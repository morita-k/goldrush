# -*- encoding: utf-8 -*-
class Auth::RegistrationsController < Devise::RegistrationsController
  require 'smtp_password_encryptor'

  prepend_before_filter :authenticate_scope!, only: [:edit, :update, :show_smtp_setting, :edit_smtp_setting, :update_smtp_setting, :destroy]

  def new
    if invite_action?
      @invite = Invite.where(:deleted => 0, :activation_code => params[:auth_activation_code]).order(:created_at).first
      if @invite.blank?
        flash.now[:err] = "アクティベーションコードに誤りがあります。URLを再確認して下さい。"
        params.delete(:auth_activation_code)
      end
    end
    super
  end

  def create
    build_resource(sign_up_params)
    ActiveRecord::Base.transaction do
      if invite_action?
        create_invited_user(resource, params[:auth_activation_code])
      else
        # 同一組織 存在チェック(※最初1回だけ警告表示)
        if resource.valid? && owner_already_exists?
          flash.now[:warning] = "同名の会社が既に存在します。会社の管理者からの招待を受けるようにして下さい。"
          params[:skip_owner_check] = 1
          render :action => :new and return
        end

        # ユーザー登録
        super

        # ユーザー関連初期データ登録
        init_user_data(get_last_created_user, params[:auth_company_name]) if resource.errors.empty?
      end
    end
  end

  def edit
    super
  end

  def update
    ActiveRecord::Base.transaction do
      super
      if resource.errors.empty?
        resource.update_attributes!(:updated_user => resource.login)
        current_user = resource
      end
    end
  end

  def show_smtp_setting
    build_resource(current_user.attributes)
    if current_user.advanced_smtp_mode_on?
      resource.smtp_settings_enable_starttls_auto = 0
      resource.smtp_settings_address = 'localhost'
      resource.smtp_settings_port = 25
      resource.smtp_settings_domain = current_user.owner.sender_email.split('@')[1]
      resource.smtp_settings_user_name = current_user.owner.company_name
    else
      resource.smtp_settings_port ||= 587
      resource.smtp_settings_domain ||= current_user.email.split('@')[1]
      resource.smtp_settings_user_name ||= current_user.email.split('@')[0]
    end
  end

  def edit_smtp_setting
    if current_user.advanced_smtp_mode_on?
      redirect_to :controller => '/auth/registrations', :action => :show_smtp_setting and return
    end

    build_resource(current_user.attributes)
    resource.smtp_settings_port ||= 587
    resource.smtp_settings_domain ||= current_user.email.split('@')[1]
    resource.smtp_settings_user_name ||= current_user.email.split('@')[0]
  end

  def update_smtp_setting
    ActiveRecord::Base.transaction do
      set_smtp_setting(current_user, params[:auth])
      build_resource(current_user.attributes)

      # 接続確認テストメール送信
      begin
        NoticeMailer.sendmail_confirm(current_user, current_user.email)
      rescue => e
        flash.now[:err] = format_smtp_connection_error_message(e)
        current_user.update_attributes!(:smtp_settings_authenticated_flg => 0)
        render :action => 'edit_smtp_setting' and return
      end

      current_user.update_attributes!(:smtp_settings_authenticated_flg => 1)
      flash[:notice] = 'SMTP settings was successfully updated.'
      redirect_to :root
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to :action => 'edit_smtp_setting'
  end

protected
  # override
  # see https://github.com/plataformatec/devise/blob/master/app/controllers/devise/registrations_controller.rb 
  #
  # ユーザー仮登録後、何故かログイン画面でエラー
  # (ja.devise.failure.unauthenticated)となってしまうので、
  # このメソッドをオーバーライドして回避
  def after_inactive_sign_up_path_for(resource)
    new_auth_session_path
  end


  def invite_action?
    params[:auth_activation_code].present?
  end

  def owner_already_exists?
    params[:skip_owner_check].blank? && params[:auth_company_name].present? && Owner.exists?(:deleted => 0, :company_name => params[:auth_company_name])
  end

  def get_last_created_user
    User.order('id desc').first
  end

  # 招待ユーザー作成
  def create_invited_user(resource, activation_code)
    @invite = Invite.where(:deleted => 0, :activation_code => activation_code).order(:created_at).first

    resource.assign_attributes(:owner_id => @invite.owner_id, :email => @invite.email, :created_user => "initial", :updated_user => "initial")
    resource.skip_confirmation_notification!

    if resource.save
      # トークン認証 && ログイン
      redirect_to :controller => '/auth/confirmations', :action => :show, :confirmation_token => resource.confirmation_token
    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      @minimum_password_length = resource_class.password_length.min if @validatable
      respond_with resource
    end
  end

  # ユーザー関連データ初期化
  def init_user_data(user, company_name)
    # オーナー登録
    owner = new_owner(user, company_name)
    owner.save!

    # ユーザー情報更新
    user.update_attributes!(:owner_id => owner.id, :access_level_type => "owner", :created_user => "initial", :updated_user => "initial")

    # sys_configs, special_words, tags 初期データインポート
    import_sys_configs_init_data(user)
    import_special_words_init_data(user)
    import_tags_init_data(user)
  end

  def new_owner(user, company_name)
    Owner.new({
      :owner_key => Owner.calculate_owner_key(user.id, user.email),
      :company_name => company_name,
      :created_user => user.login,
      :updated_user => user.login
    })
  end


  def import_init_data(table_name, column, select_column, condition)
    ActiveRecord::Base.connection.execute("insert into #{table_name.to_s} (#{column}) select #{select_column} from #{table_name.to_s} where #{condition};")
  end

  IGNORE_COLUMN_NAMES = ['id', 'lock_version', 'deleted_at', 'deleted']

  def import_sys_configs_init_data(user)
    column = SysConfig.column_names.reject{|cn| IGNORE_COLUMN_NAMES.include?(cn)}.join(", ")
    select_column = column
        .gsub(/owner_id/, "#{user.owner_id} as owner_id")
        .gsub(/created_user|updated_user/, "'#{user.login}' as \\&")
        .gsub(/created_at|updated_at/, "'#{user.created_at}' as \\&")
    import_init_data(:sys_configs, column, select_column, "deleted = 0 and owner_id is null")
  end

  def import_special_words_init_data(user)
    column = SpecialWord.column_names.reject{|cn| IGNORE_COLUMN_NAMES.include?(cn)}.join(", ")
    select_column = column
        .gsub(/owner_id/, "#{user.owner_id} as owner_id")
        .gsub(/created_user|updated_user/, "'#{user.login}' as \\&")
        .gsub(/created_at|updated_at/, "'#{user.created_at}' as \\&")
    import_init_data(:special_words, column, select_column, "deleted = 0 and owner_id is null")
  end

  def import_tags_init_data(user)
    column = Tag.column_names.reject{|cn| IGNORE_COLUMN_NAMES.include?(cn)}.join(", ")
    select_column = column
        .gsub(/owner_id/, "#{user.owner_id} as owner_id")
        .gsub(/tag_count|inc_count/, "0 as \\&")
        .gsub(/created_user|updated_user/, "'#{user.login}' as \\&")
        .gsub(/created_at|updated_at/, "'#{user.created_at}' as \\&")
    import_init_data(:tags, column, select_column, "deleted = 0 and owner_id is null and tag_key = 'import_mails' and starred <> 0")
  end


  def set_smtp_setting(user, smtp_setting)
    user.smtp_settings_enable_starttls_auto = smtp_setting[:smtp_settings_enable_starttls_auto]
    user.smtp_settings_address = smtp_setting[:smtp_settings_address]
    user.smtp_settings_port = smtp_setting[:smtp_settings_port]
    user.smtp_settings_domain = user.email.split('@')[1]
    user.smtp_settings_authentication = 'plain' # plain固定
    user.smtp_settings_user_name = smtp_setting[:smtp_settings_user_name]
    if smtp_setting[:smtp_settings_password].present?
      user.smtp_settings_password = SmtpPasswordEncryptor.encrypt(smtp_setting[:smtp_settings_password])
    end
    user.updated_user = user.login
  end

  def format_smtp_connection_error_message(err)
    error_message = ''

    case err
    when SocketError
      if /getaddrinfo: name or service not known/i =~ err.message
        error_message = 'SMTPサーバーアドレスが正しくありません。'
      end
    when Net::SMTPAuthenticationError
      if /starttls command first/i =~ err.message
        error_message = 'SMTP自動TLSをONにして下さい。'
      elsif /username and password not accepted/i =~ err.message
        error_message = 'ユーザーかパスワードが違います。'
      elsif /authorization failed/i =~ err.message
        error_message = 'SMTPサーバーの接続認証に失敗しました。'
      end
    when Timeout::Error
      error_message = '接続がタイムアウトしました。'
    end
    error_message = '設定内容を確認して下さい。' if error_message.empty?

    "テストメールの送信に失敗しました。 #{error_message}"
  end
end

