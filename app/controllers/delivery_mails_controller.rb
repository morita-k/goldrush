# -*- encoding: utf-8 -*-
class DeliveryMailsController < ApplicationController
  before_filter :check_smtp_settings_authentication, :only => [:new, :copynew, :contact_mail_new, :reply_mail_new, :edit]

  # GET /delivery_mails
  # GET /delivery_mails.json
  def index

    if params[:bp_pic_group_id]
      #グループメール
      @bp_pic_group = BpPicGroup.find(params[:bp_pic_group_id])
      cond  = ["bp_pic_group_id = ? and deleted = 0",  @bp_pic_group]
    else
      #即席メール
      cond  = ["delivery_mail_type = ? and deleted = 0",  "instant"]
    end
    @delivery_mails = find_login_owner(:delivery_mails)
                        .where(cond)
                        .order("id desc")
                        .page(params[:page])
                        .per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @delivery_mails }
    end
  end

  # GET /delivery_mails/1
  # GET /delivery_mails/1.json
  def show
    @delivery_mail = DeliveryMail.find(params[:id]).get_informations
    @delivery_mail_targets = @delivery_mail.get_delivery_mail_targets(@target_limit || 20)

    @attachment_files = AttachmentFile.get_attachment_files("delivery_mails", @delivery_mail.id)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  def show_all
    @delivery_mail = DeliveryMail.find(params[:id]).get_informations
    @delivery_mail_targets = @delivery_mail.get_delivery_mail_targets(3000)
    respond_to do |format|
      format.html { render layout: false } # show.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  def copynew
    params[:src_mail_id] = params[:id]
    src_mail = DeliveryMail.find(params[:src_mail_id])
    src_mail.setup_planned_setting_at(current_user.zone_at(src_mail.planned_setting_at))
    @attachment_files = AttachmentFile.get_attachment_files("delivery_mails", src_mail.id)
    @delivery_mail = DeliveryMail.new
    @delivery_mail.attributes = src_mail.attributes.reject{|x| ["created_at", "updated_at", "created_user", "updated_user", "deleted_at", "deleted"].include?(x)}

    new_proc

    respond_to do |format|
      format.html { render action: "new" }
    end
  end

  # GET /delivery_mails/new
  # GET /delivery_mails/new.json
  def new
    @delivery_mail = DeliveryMail.new
    @delivery_mail.bp_pic_group_id = params[:bp_pic_group_id]
    if (target_mail_template = get_target_mail_template)
      @delivery_mail.content = target_mail_template.content
      @delivery_mail.subject = target_mail_template.subject
      @delivery_mail.mail_cc = target_mail_template.mail_cc
      @delivery_mail.mail_bcc = target_mail_template.mail_bcc
    else
      @delivery_mail.content = <<EOS
%%business_partner_name%%
%%bp_pic_name%%　様
EOS
    end
    @delivery_mail.add_signature(current_user)

    new_proc

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  # GET /delivery_mails/1/edit
  def edit
    @delivery_mail = DeliveryMail.find(params[:id])
    @delivery_mail.setup_planned_setting_at(current_user.zone_at(@delivery_mail.planned_setting_at))
    @attachment_files =  @delivery_mail.attachment_files
    respond_to do |format|
      format.html # edit.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  # POST /delivery_mails
  # POST /delivery_mails.json
  def create
    if params[:bp_pic_ids].present?
      return contact_mail_create(params[:bp_pic_ids].split.uniq)
    end
    if params[:source_bp_pic_id].present?
      return reply_mail_create
    end

    if params[:src_mail_id]
      @attachment_files = AttachmentFile.get_attachment_files("delivery_mails", params[:src_mail_id])
    end
    @delivery_mail = create_model(:delivery_mails, params[:delivery_mail])
    set_mail_sender @delivery_mail
    @delivery_mail.matching_way_type = @delivery_mail.bp_pic_group.matching_way_type
    @delivery_mail.delivery_mail_type = "group"
    @delivery_mail.perse_planned_setting_at(current_user) # zone
    set_user_column @delivery_mail

    respond_to do |format|
      begin
        ActiveRecord::Base.transaction do
          @delivery_mail.save!

          @delivery_mail.tag_analyze!

          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)

          # 配信メールコピーの場合、コピー元の添付ファイルもコピーする
          copy_upload_files(params[:src_mail_id], @delivery_mail.id)
        end

        if params[:testmail]
          DeliveryMail.send_test_mail(current_user, @delivery_mail.get_informations)
          format.html {
            redirect_to({
              :controller => 'delivery_mails',
              :action => 'edit',
              :id => @delivery_mail,
              :back_to => back_to
            },
            notice: 'Delivery mail was successfully created.')
          }
        end

        format.html {
          redirect_to url_for(
            :controller => 'bp_pic_groups',
            :action => 'show',
            :id => @delivery_mail.bp_pic_group_id,
            :delivery_mail_id => @delivery_mail.id,
            :back_to => back_to
          ),
          notice: 'Delivery mail was successfully created.'
        }
        format.json { render json: @delivery_mail, status: :created, location: @delivery_mail }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @delivery_mail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /delivery_mails/1
  # PUT /delivery_mails/1.json
  def update
    @delivery_mail = DeliveryMail.find(params[:id])
    @attachment_files =  @delivery_mail.attachment_files
    set_mail_sender @delivery_mail
    @delivery_mail.mail_status_type = 'editing'

    respond_to do |format|
      begin
        @delivery_mail.attributes = params[:delivery_mail]
        @delivery_mail.perse_planned_setting_at(current_user) # zone

        set_user_column(@delivery_mail)

        ActiveRecord::Base.transaction do
          @delivery_mail.save!

          @delivery_mail.tag_analyze!

          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)
       end

        if params[:testmail]
          DeliveryMail.send_test_mail(current_user, @delivery_mail.get_informations)
          format.html {
            redirect_to({
              :controller => 'delivery_mails',
              :action => 'edit',
              :id => @delivery_mail,
              :back_to => back_to
            },
            notice: 'Delivery mail was successfully created.')
          }
        end

        if @delivery_mail.instant?
          format.html {
            redirect_to back_to,
            notice: 'Delivery mail was successfully updated.' }
        else
          format.html {
            redirect_to url_for(
              :controller => 'bp_pic_groups',
              :action => 'show',
              :id => @delivery_mail.bp_pic_group_id,
              :delivery_mail_id => @delivery_mail.id,
              :back_to => back_to
            ),
            notice: 'Delivery mail was successfully updated.' }
        end
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @delivery_mail.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /delivery_mails/add_details
  # POST /delivery_mails/add_details.json
  def add_details
    if params[:bp_pic_ids].blank?
      redirect_to back_to, notice: 'メール対象者が0人でなので、登録できません。'
      return
    end
    delivery_mail = DeliveryMail.find(params[:delivery_mail_id]).get_informations
    ActiveRecord::Base.transaction do
      delivery_mail.mail_status_type = 'unsend'
      set_user_column delivery_mail
      delivery_mail.save!
      add_targets(params[:delivery_mail_id], params[:bp_pic_ids])
    end

    # メール送信はcronのジョブに任せて、ここでは送信しない。
=begin
    if delivery_mail.planned_setting_at < Time.now.to_s
      DeliveryMail.send_mails

      error_count = DeliveryError.where(:delivery_mail_id => delivery_mail.id).size
      if error_count > 0
        flash[:warning] = "送信に失敗した宛先が存在します。<br>送信に失敗した宛先は配信メール詳細画面から確認できます。"
      end
    end
=end

    SystemNotifier.send_info_mail("[GoldRush] 配信メールがセットされました ID:#{delivery_mail.id}", <<EOS).deliver

#{SysConfig.get_system_notifier_url_prefix}/delivery_mails/#{delivery_mail.id}

件名: #{delivery_mail.subject}

#{delivery_mail.content}

EOS

    respond_to do |format|
      format.html { redirect_to url_for(:action => :index, :bp_pic_group_id => params[:bp_pic_group_id]), notice: 'Delivery mail targets were successfully created.' }
#        format.json { render json: @delivery_mail_target, status: :created, location: @delivery_mail_target }
    end
  end

  def add_targets(delivery_mail_id, bp_pic_ids)
    bp_pic_ids.each do |bp_pic_id|
      next if DeliveryMailTarget.where(:delivery_mail_id => delivery_mail_id, :bp_pic_id => bp_pic_id.to_i, :deleted => 0).first
      delivery_mail_target = create_model(:delivery_mail_targets)
      delivery_mail_target.delivery_mail_id = delivery_mail_id
      delivery_mail_target.bp_pic_id = bp_pic_id.to_i
      set_user_column(delivery_mail_target)
      delivery_mail_target.save!
    end
  end

  # PUT /delivery_mails/cancel/1
  # PUT /delivery_mails/cancel/1.json
  def cancel
    @delevery_mail = DeliveryMail.find(params[:id])
    @delevery_mail.mail_status_type = 'canceled'
    set_user_column @delevery_mail
    @delevery_mail.save!

    respond_to do |format|
      format.html { redirect_to back_to, notice: 'Delivery mail was successfully canceled.'  }
    end
  end


  # DELETE /delivery_mails/1
  # DELETE /delivery_mails/1.json
  def destroy
  #  @delivery_mail = DeliveryMail.find(params[:id])
  #  @delivery_mail.destroy

    respond_to do |format|
      format.html { redirect_to delivery_mails_url }
      format.json { head :no_content }
    end
  end

  def reply_mail_new
    @bp_pics = []
    source_subject, source_content, params[:source_bp_pic_id], params[:source_message_id] =
      if params[:import_mail_id]
        source_im = ImportMail.find(params[:import_mail_id])
        [source_im.mail_subject, source_im.mail_body, source_im.bp_pic_id, source_im.message_id]
      elsif params[:delivery_mail_id]
        source_dm = DeliveryMail.find(params[:delivery_mail_id])
        # こちらから送った配信メールに返信する形で配信するのは、現状、自動マッチングからのみの機能なので、
        # 配信メールの持つ配信メール対象は一つしかない想定
        source_dmt = source_dm.delivery_mail_targets.first
        [source_dm.subject, source_dm.content, source_dmt.bp_pic_id, source_dmt.message_id]
      end

    @delivery_mail = DeliveryMail.new
    @delivery_mail.delivery_mail_type = "instant"
    @delivery_mail.mail_bcc = current_user.email

    new_proc

    @delivery_mail.subject = "Re: #{source_subject}"
    @delivery_mail.content = <<EOS + "\n\n\n" + source_content.lines.map{|x| "> " + x}.join
%%business_partner_name%%
%%bp_pic_name%%　様
EOS

    @delivery_mail.add_signature(current_user)

    respond_to do |format|
      format.html { render action: "new" }
    end
  end

  def reply_mail_create
    @delivery_mail = create_model(:delivery_mails, params[:delivery_mail])
    set_mail_sender @delivery_mail
    @delivery_mail.delivery_mail_type = "instant"
    @delivery_mail.setup_planned_setting_at(current_user.zone_now)
    @delivery_mail.mail_status_type = 'unsend'
    set_user_column @delivery_mail

    respond_to do |format|
      begin
        ActiveRecord::Base.transaction do
          @delivery_mail.save!

          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)

          #配信メール対象作成
          delivery_mail_target = create_model(:delivery_mail_targets)
          delivery_mail_target.delivery_mail_id = @delivery_mail.id
          delivery_mail_target.bp_pic_id = params[:source_bp_pic_id]
          delivery_mail_target.in_reply_to = params[:source_message_id]
          set_user_column(delivery_mail_target)
          delivery_mail_target.save!
        end #transaction

        # メール送信はcronのジョブに任せて、ここでは送信しない。
=begin
        DeliveryMail.send_mails
        error_count = DeliveryError.where(:delivery_mail_id => @delivery_mail.id).size
        if error_count > 0
          flash[:warning] = "送信に失敗した宛先が存在します。<br>送信に失敗した宛先は配信メール詳細画面から確認できます。"
        end
=end

        format.html {
          redirect_to(back_to , notice: 'Delivery mail was successfully sent.')
        }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
      end
    end
  end

  def contact_mail_new
    @bp_pics = BpPic.find(params[:bp_pic_ids])
    @delivery_mail = DeliveryMail.new
    @delivery_mail.delivery_mail_type = "instant"
    #@delivery_mail.bp_pic_group_id = params[:id]
    unless sales_pic = BpPic.find(params[:bp_pic_ids][0]).sales_pic
      sales_pic = current_user
    end
    @delivery_mail.content = ""
    if t = sales_pic.contact_mail_template
      @delivery_mail.mail_cc = t.mail_cc
      @delivery_mail.mail_bcc = t.mail_bcc
      @delivery_mail.subject = t.subject
      @delivery_mail.content = t.content
    end
    @delivery_mail.add_signature(sales_pic)
    @delivery_mail.mail_bcc = @delivery_mail.mail_bcc.to_s.split(",").push(sales_pic.email).join(",")
    @delivery_mail.setup_planned_setting_at(sales_pic.zone_now)

    respond_to do |format|
      format.html { render action: "new" }
    end
  rescue ValidationAbort
    respond_to do |format|
      format.html {
        flash[:warning] = '営業担当が設定されていません。'
        redirect_to(back_to)
      }
    end
  end

  def contact_mail_create(bp_pic_ids)
    @bp_pics = BpPic.find(bp_pic_ids)
    @delivery_mail = create_model(:delivery_mails, params[:delivery_mail])
    set_mail_sender @delivery_mail
    @delivery_mail.delivery_mail_type = "instant"
    @delivery_mail.setup_planned_setting_at(
        (@bp_pics[0].sales_pic.blank? ? current_user : @bp_pics[0].sales_pic).zone_now)
    @delivery_mail.mail_status_type = 'unsend'
    set_user_column @delivery_mail
    respond_to do |format|
      begin
        ActiveRecord::Base.transaction do
          @delivery_mail.save!

          #あいさつメールフラグの更新
          @bp_pics.each do |bp_pic|
            bp_pic.contact_mail_flg = 1
            set_user_column bp_pic
            bp_pic.save!
          end

          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)

          #配信メール対象作成
          add_targets(@delivery_mail.id, bp_pic_ids)
        end #transaction

        # メール送信はcronのジョブに任せて、ここでは送信しない。
=begin
        DeliveryMail.send_mails
        error_count = DeliveryError.where(:delivery_mail_id => @delivery_mail.id).size
        if error_count > 0
          flash[:warning] = "送信に失敗した宛先が存在します。<br>送信に失敗した宛先は配信メール詳細画面から確認できます。"
        end
=end

        format.html {
          redirect_to(back_to , notice: 'Delivery mail was successfully sent.')
        }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
      end
    end
  end

  def start_matching
    m = DeliveryMail.find(params[:id])
    session[:mail_match_target_id] = m.id
    redirect_to :controller => :import_mail, :action => :list
  end

  def fix_matching
    session.delete(:mail_match_target_id)
    render :text => "OK", :layout => false
  end

  def add_matching
    ActiveRecord::Base.transaction do
      dm = DeliveryMail.find(session[:mail_match_target_id])
      im = ImportMail.find(params[:id])
      dmm = create_model(:delivery_mail_matches)
      dmm.delivery_mail = dm
      dmm.import_mail = im
      dmm.delivery_mail_match_type = 'auto'
      dmm.matching_user_id = current_user.id
      dmm.memo= params[:msg]
      set_user_column dmm
      dmm.save!

      ScoreJournal.update_score!(current_user.id, 1, 'add_matching', dmm.id)

      SystemNotifier.send_info_mail("[GoldRush] マッチング候補が提案されました ID:#{dm.id}", <<EOS).deliver

#{SysConfig.get_system_notifier_url_prefix}/delivery_mails/#{dm.id}

コメント: #{dmm.memo}

対象メール: #{dm.subject}

提案メール: #{im.mail_subject}

#{im.mail_body}

EOS
    end

    _redirect_or_back_to({:controller => :import_mails, :action => :show , :id => params[:id]}, notice: "マッチング候補に追加しました！")
  end

  def unlink_matching
    ActiveRecord::Base.transaction do
      dmm = DeliveryMailMatch.match(params[:delivery_mail_id], params[:import_mail_id])
      dmm.deleted = 9
      dmm.deleted_at = Time.now
      set_user_column dmm
      dmm.save!
      ScoreJournal.update_score!(dmm.matching_user_id, -1, 'unlink_matching', dmm.id)
    end

    redirect_to(back_to, notice: "マッチング候補から外しました。")
  end


private
  def check_smtp_settings_authentication
    if !current_user.advanced_smtp_mode_on? && !current_user.smtp_settings_authenticated?
      flash[:warning] = "メール配信設定に誤りがあります。 設定内容を変更して下さい。"
      redirect_to({
        :controller => 'auth/registrations',
        :action => 'edit_smtp_setting',
        :back_to => back_to
      })
    end
  end

  def new_proc
    set_mail_sender @delivery_mail
    @delivery_mail.setup_planned_setting_at(current_user.zone_now)
  end

  def set_mail_sender(dm)
    if current_user.advanced_smtp_mode_on?
      if params[:delivery_mail].blank? || params[:delivery_mail][:formated_mail_from].blank?
        # アドバンストSMTPモード かつ 新規作成時は組織共通アドレスを初期選択
        o = current_user.owner
        dm.formated_mail_from = "\"#{o.company_name}\" <#{o.sender_email}>"
      else
        dm.formated_mail_from = params[:delivery_mail][:formated_mail_from]
      end
    else
      dm.formated_mail_from = "\"#{current_user.nickname}\" <#{current_user.email}>"
    end
    dm.delivery_user = current_user
  end

  def store_upload_files(parent_id)
    [1,2,3,4,5].each do |i|
      unless (upfile = params['attachment' + i.to_s]).blank?
        af = create_model(:attachment_files)
        af.create_and_store!(upfile, parent_id, upfile.original_filename, "delivery_mails", current_user.login)
      end
    end
  end

  def copy_upload_files(src_mail_id, parent_id)
    unless src_mail_id.blank?
      AttachmentFile.get_attachment_files("delivery_mails", src_mail_id).each do |src|
        af = create_model(:attachment_files)
        af.parent_table_name = src.parent_table_name
        af.parent_id = parent_id
        af.file_name = src.file_name
        af.extention = src.extention
        af.file_path = src.file_path
        set_user_column af
        af.save!
      end
    end
  end

  def get_target_mail_template
    if @delivery_mail.bp_pic_group != nil && @delivery_mail.bp_pic_group.mail_template_id
      MailTemplate.find(@delivery_mail.bp_pic_group.mail_template_id)
    end
  end
end
