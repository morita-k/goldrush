# -*- encoding: utf-8 -*-
require 'sales_person_logic'
class ExpenseApplicationController < ApplicationController
  include SalesPersonLogic

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @expense_application_pages, @expense_applications = paginate(:expense_applications, :per_page => 30, :conditions => ["deleted = 0 and user_id = ?", current_user.id], :order => "application_date DESC")
  end


  def set_conditions
    session[:expense_search] = {
      :application_date_from => params[:application_date_from],
      :application_date_to =>  params[:application_date_to],
      :payment_flg => params[:payment_flg]
    }
  end

  def make_conditions
    sql = "expense_applications.deleted = 0 and expense_applications.expense_app_type = 'fee_expense_app' and user_id = ?"
    param = [current_user.id]
    include = []
    order_by = "application_date DESC"

    if session[:expense_search].blank?
    end

    if !(application_date_from = session[:expense_search][:application_date_from]).blank?
      sql += " and application_date >= ?"
      param << application_date_from
    end
    
    if !(application_date_to = session[:expense_search][:application_date_to]).blank?
      sql += " and application_date <= ?"
      param << application_date_to
    end

    if !(payment_flg = session[:expense_search][:payment_flg]).blank?
      sql += " and payment_flg = ?"
      param << payment_flg
    end

    {:conditions => param.unshift(sql), :include => include, :order => order_by }
  end

  def fee_list
    @calendar = true
    session[:expense_search] ||= {}
    if request.post?
      if params[:search_button]
        set_conditions
      end
    end
    cond = make_conditions

    @expense_application_pages, @expense_applications = paginate(:expense_applications, cond)
  end

  def show
    @calendar = true
    @expense_application = ExpenseApplication.find(params[:id])
  end

  def print
    @expense_application = ExpenseApplication.find(params[:id])
    case @expense_application.expense_app_type
    when 'temporary_app'
      render :action => :print_temporary, :layout => false
    when 'fee_expense_app'
      render :action => :print_fee, :layout => false
    else
      flash[:err] = "この申請区分では、プリント画面を開けません"
      redirect_to params[:back_to]
    end
  end

  def new
    @calendar = true
    @expense_application = ExpenseApplication.new
    @expense_application.expense_app_type = params[:expense_app_type]
    @expense_application.application_date = Time.now
    if @expense_application.expense_app_type == 'temporary_app'
      set_base_months
    end
  end

  def set_base_months
    @expense_application.temporary_app_flg = 1
    start_date = Date.today - 1.month
    end_date = Date.today + 1.month
    @base_months = BaseMonth.find(:all, :conditions =>["deleted = 0 and start_date between ? and ?",  start_date, end_date], :order => "start_date").collect{|x| [x.end_date.strftime('%Y/%m'), x.id]}
    @selected_month = @base_months[0][1]
  end

  # use by SalesPersonLogic
  def require_sales_person?
    ['business_trip_app','fee_expense_app'].include?(@expense_application.expense_app_type)
  end

  def create
    parseCurrency(params){|k| ['withholding_tax','other_expenses'].include?(k)}
    parseTimes(params)
    @file_field = params[:expense_application].delete(:attached_material)
    @expense_application = ExpenseApplication.new(params[:expense_application])
    @expense_application.user_id = current_user.id
    if @expense_application.expense_app_type == 'material_expenses_app'
      @expense_application.plan_buy_date = Date.today #マイページに過去1ヶ月間まで物品購入申請の表示件数を検索のためです。
    end
    #経費申請での全て承認者を取る。
    approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = 1 and deleted = 0", @expense_application.user_id, 'expense_xxx'])

    if !@expense_application.want_approval?
      approval_authorities = []
    end

    if approval_authorities.empty? && @expense_application.want_approval?
      raise ValidationAbort.new('承認者が一人も登録されていません。承認権限設定をしてください')
    end
    set_user_column @expense_application

    ActiveRecord::Base::transaction() do
      base_application = BaseApplication.new
      base_application.user_id = current_user.id
      base_application.application_type = 'expense_app'
      base_application.approval_status_type = (@expense_application.expense_app_type == 'temporary_app' ? 'fixed' : 'entry')
      base_application.application_date = @expense_application.application_date
      base_application.accounting_approval_flg = (['temporary_app','fee_expense_app'].include?(@expense_application.expense_app_type) ? 1 : 0)
      set_user_column base_application
      base_application.save!

      @expense_application.base_application_id = base_application.id
      if @expense_application.expense_app_type == 'fee_expense_app'
        @expense_application.other_expenses = @expense_application.other_expenses.to_i
      end


      set_user_column @expense_application
      @expense_application.save!

      proc_attach
      set_user_column @expense_application
      @expense_application.save!

      #申請に承認者を設定
      count = 0
      for approval_authority in approval_authorities
        count = count + 1
        application_approval = ApplicationApproval.new
        application_approval.user_id = approval_authority.user_id
        application_approval.base_application_id = base_application.id
        application_approval.application_type = 'expense_app'
        application_approval.application_date = @expense_application.application_date
        application_approval.approver_id = approval_authority.approver_id
        application_approval.approval_status_type = 'entry'
        application_approval.approval_order = count
        set_user_column application_approval
        application_approval.save!
      end

      if @expense_application.temporary_app_flg == 1
        @base_month = BaseMonth.find(params[:base_month_id])

        @payment_per_month = PaymentPerMonth.get_payment_per_month(@base_month, current_user.id)
        if @payment_per_month.new_record?
          set_user_column @payment_per_month
          @payment_per_month.save!
        end

        @expense_detail = ExpenseDetail.new
        @expense_detail.user_id = @expense_application.user_id
        @expense_detail.expense_application_id = @expense_application.id
        @expense_detail.payment_per_month_id = @payment_per_month.id
        @expense_detail.expense_type = 'temporary_expense'
        @expense_detail.buy_date = @expense_application.plan_buy_date
        @expense_detail.book_no = @expense_application.book_no
        @expense_detail.account_item = @expense_application.account_item
        @expense_detail.purpose = @expense_application.purpose
        @expense_detail.content = @expense_application.content
        @expense_detail.amount = @expense_application.approximate_amount
        @expense_detail.temporary_flg = 1
        @expense_detail.cutoff_status_type = 'open'
        set_user_column @expense_detail
        @expense_detail.save!
      end
    end
    if @expense_application.expense_app_type == 'material_expenses_app'
      flash[:notice] = '物品購入申請を作成しました'
    else 
      flash[:notice] = '経費申請を作成しました'
    end
    redirect_to :action => 'show', :id => @expense_application.id
  rescue ValidationAbort
    flash[:warning] = $!
    @calendar = true
    if @expense_application.expense_app_type == 'temporary_app'
      set_base_months
    end
    render :action => 'new'
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    if @expense_application.expense_app_type == 'temporary_app'
      set_base_months
    end
    render :action => 'new'
  end

  def edit
    @calendar = true
    @expense_app_type = params[:expense_app_type]
    @expense_application = ExpenseApplication.find(params[:id])
    if @expense_application.expense_app_type == 'temporary_app'
      start_date = Date.today - 2.month
      end_date = Date.today + 2.month
      @base_months = BaseMonth.find(:all, :conditions =>["deleted = 0 and start_date between ? and ?",  start_date, end_date], :order => "start_date").collect{|x| [x.end_date.strftime('%Y/%m'), x.id]}
      @selected_month = @expense_application.expense_detail.payment_per_month.base_month_id
    end
  end

  def update
    ActiveRecord::Base::transaction() do
      parseCurrency(params){|k| ['withholding_tax','other_expenses'].include?(k)}
      parseTimes(params)
      @file_field = params[:expense_application].delete(:attached_material)
      @expense_application = ExpenseApplication.find(params[:id])
      @expense_application.attributes = params[:expense_application]

      set_user_column @expense_application
      @expense_application.save!

      proc_attach
      set_user_column @expense_application
      if @expense_application.expense_app_type == 'fee_expense_app'
        @expense_application.other_expenses = @expense_application.other_expenses.to_i
      end
      @expense_application.save!

      if @expense_application.temporary_app_flg == 1
        @expense_detail = @expense_application.expense_detail
        @expense_detail.buy_date = @expense_application.plan_buy_date
        @expense_detail.book_no = @expense_application.book_no
        @expense_detail.account_item = @expense_application.account_item
        @expense_detail.purpose = @expense_application.purpose
        @expense_detail.content = @expense_application.content
        @expense_detail.amount = @expense_application.approximate_amount
        @expense_detail.cutoff_status_type = 'open'
        set_user_column @expense_detail
        @expense_detail.save!
      end
    end

    if @expense_application.expense_app_type == 'material_expenses_app'
      flash[:notice] = '物品購入申請を更新しました'
    else 
      flash[:notice] = '経費申請を更新しました'
    end
    redirect_to :action => 'show', :id => @expense_application
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    render :action => 'edit'
  end

  def popup_list
    @expense_applications = ExpenseApplication.find(:all,
      :conditions => ["deleted = 0 and user_id = ? and expense_app_type not in (?)", current_user.id, ['temporary_app','fee_expense_app']],
      :order => "application_date DESC")
    render :layout => 'popup'
  end

  def destroy
    ExpenseApplication.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  # 支払済みにする
  def fix_payment
    flg = params[:release] ? 0 : 1
    paid_date = nil
    begin
      if flg == 1
        paid_date = params[:paid_date].to_date
        if BaseDate.is_holiday?(paid_date)
          flash[:err] = '支払日に土日祝日は指定できません'
          redirect_to params[:back_to]
          return
        end
      end
    rescue
      flash[:err] = '支払日が正しくありません'
      redirect_to params[:back_to]
      return
    end
    ActiveRecord::Base::transaction() do
      expense_application = ExpenseApplication.find(params[:id], :conditions => "deleted = 0")
      expense_application.payment_flg = flg
      expense_application.payment_date = paid_date
      set_user_column expense_application
      expense_application.save!
      # 仮払いだったら、経費明細も支払済みにする)
      if expense_application.temporary_app?
        expense_detail = expense_application.expense_detail
        expense_detail.temporary_payment_flg = flg
        set_user_column expense_detail
        expense_detail.save!
      end
    end
    redirect_to params[:back_to]
  end

  def open_file
    expense_application = ExpenseApplication.find_by_attached_material(params[:id] + '.' + params[:format], :conditions => "deleted = 0 ") 
    filename = expense_application.attached_material
    file_dir = File.join(Rails.root,'tmp','expense')
    send_file File.join(file_dir, filename), :type => 'application/octet-stream', :disposition => 'inline', :filename => expense_application.attached_material_name
  rescue ActionController::MissingFile
    flash[:notice] = 'ファイルが見つかりませんでした。'
    redirect_to :action => 'show', :id => expense_application
  end
  
  def excel_download
    mode = params[:mode]
    id = params[:id]
    unless ['fee_expense_app', 'temporary_app'].include?(mode)
      flash[:err] = 'EXCELダウンロードのパラメータが不正です(mode)'
      return redirect_to(:action => '/')
    end
    if id.blank? || id.to_i == 0
      flash[:err] = 'EXCELダウンロードのパラメータが不正です(id)'
      return redirect_to(:action => '/')
    end
    java_dir = File.join(Rails.root, 'java')
    tmp_dir = File.join(Rails.root, 'tmp', 'excel')
    xxx = rand(1000000).to_s
    filename = "expense_#{mode}_#{id}_#{Time.now.strftime('%Y%m%d%H%M%S')}.xls"
    tmp_filename = filename + "." + xxx
    sep = ENV["OS"] ? ";" : ":" # Windows or UNIX??
    class_path = ["#{java_dir}","#{java_dir}/lib/poi-2.5.1-final-20040804.jar","#{java_dir}/lib/ojdbc14.jar"].join(sep)
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    host = ActiveRecord::Base.configurations[RAILS_ENV]['host']
    if host[0] == '/'[0] # hostの一文字目が'/'だったらUNIX SOCKETと判断
      host = 'localhost'
    end
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    username = ActiveRecord::Base.configurations[RAILS_ENV]['username']
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    password = ActiveRecord::Base.configurations[RAILS_ENV]['password']
    if password.blank?
      password = '\"\"'
    end
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    database = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    command = "java -classpath #{class_path} gd/Main #{mode} jdbc:oracle:thin:@#{host}:1521:#{database} #{username} #{password} #{id} #{java_dir}/template_#{mode}1.xls #{tmp_dir}/#{tmp_filename}"
    logger.debug(command)
    result = `#{command}`
      
    send_file "#{tmp_dir}/#{tmp_filename}", :type => 'application/xls', :disposition => 'attachment', :filename => filename
  end

private
  def proc_attach
    file_dir = File.join(Rails.root,'tmp','expense')
    if !(@file_field.blank?)
      file = @file_field
      ext = File.extname(file.original_filename.to_s).downcase
      filename = "expense_#{@expense_application.id}_1" + ext
      @expense_application.attached_material = filename
      @expense_application.attached_material_name = file.original_filename
      File.open(File.join(file_dir, filename), "wb"){ |f| f.write(file.read) }
    end
  end

end
