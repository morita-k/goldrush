# -*- encoding: utf-8 -*-
class AccountController < ApplicationController
#  skip_before_filter :login_required, :only => [:login, :activate, :activate_recv_mail, :mailsend, :forgot_password]
#  before_filter :personnel_department_required, :only => [:list, :view, :destroy, :signup]

  def personnel_department_required
    unless logged_in? && current_user.personnel_department? || current_user.accounting?
#      redirect_to :controller => '/'
      return false
    end
    return true
  end
  
  # ユーザの作成と変更を見張ってメールを送信する observer
#  observer :user_observer if ENV['ENABLE_MAIL_ACTIVATE']
  # Be sure to include AuthenticationSystem in Application Controller instead
#  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
#  before_filter :login_from_cookie, :only => [:login]

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end
  
  def login
    @menu_hide = 1
    @page_title = '[ログイン]'
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      request.env['HTTPS'] = nil unless params[:https]
      #redirect_back_or_default(:controller => 'home', :action => 'index')
      #if self.current_user.access_level_type == "super"
        redirect_to :controller => 'home', :action => 'index'
      #else
        
      #end
      flash[:notice] = _("Logged in successfully")
      flash[:first_access] = true
    else
      flash[:warning] = _("Logged in faild")
    end
  end

  def store_upload_file
    file_dir = File.join(Rails.root,'tmp','attach')
    if params[:upload]
      if params[:upload]['file1'] != ""
        file1 = params[:upload]['file1']
        ext = File.extname(file1.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がjpgのファイルでなければなりません") if ext != '.jpg'
        filename1 = "employee_#{@employee.id.to_s}_1" + ext
        @employee.attached_file1 = filename1
        File.open(File.join(file_dir, filename1), "wb"){ |f| f.write(file1.read) }
      end
      if params[:upload]['file2'] != ""
        file2 = params[:upload]['file2']
        ext = File.extname(file2.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がpdfのファイルでなければなりません") if ext != '.pdf'
        filename2 = "employee_#{@employee.id.to_s}_2" + ext
        @employee.attached_file2 = filename2
        File.open(File.join(file_dir, filename2), "wb"){ |f| f.write(file2.read) }
      end
      if params[:upload]['file3'] != ""
        file3 = params[:upload]['file3']
        ext = File.extname(file3.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がpdfのファイルでなければなりません") if ext != '.pdf'
        filename3 = "employee_#{@employee.id.to_s}_3" + ext
        @employee.attached_file3 = filename3
        File.open(File.join(file_dir, filename3), "wb"){ |f| f.write(file3.read) }
      end
      if params[:upload]['file4'] != ""
        file4 = params[:upload]['file4']
        ext = File.extname(file4.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がpdfのファイルでなければなりません") if ext != '.pdf'
        filename4 = "employee_#{@employee.id.to_s}_4" + ext
        @employee.attached_file4 = filename4
        File.open(File.join(file_dir, filename4), "wb"){ |f| f.write(file4.read) }
      end
    end
  end

  def update
    @calendar = true
    @page_title = '[アカウント情報変更]'
#    @user = self.current_user
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
    old_user_login = @user.login
    @user.attributes = params[:user]
    @employee = Employee.find(@user.employee.id)
    @departments = Department.find(:all, :order => "display_order") 
    
    
    if request.post?
      @user.attributes = params[:user]
      @user.updated_user = @user.login
      @user.save!
      parseTimes(params)
      @employee = Employee.find(@user.employee.id, :conditions => "deleted = 0")
      @employee.attributes = params[:employee]

      # アップロードファイルの保存
      store_upload_file

      @employee.employee_code = @employee.insurance_code.to_i + 9800
      old_employee = Employee.find(@user.employee.id)

      @employee.save!
      self.current_user = @user if self.current_user.id == @user.id

      request.env['HTTPS'] = nil unless params[:https]
      if params[:back_to].blank?
        #redirect_to(:controller => '/')
        redirect_to(:controller => 'account', :action => 'list')
      else
        redirect_to params[:back_to]
      end
      flash[:notice] = _("Update your infomation.")
    end
  rescue ValidationAbort
    flash[:warning] = $!
  rescue ActiveRecord::RecordInvalid
  end

  def edit_password
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update_password
    @page_title = '[アカウント情報変更]'
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
    @user.attributes = params[:user]
    
    if request.post?
      @user.attributes = params[:user]
      @user.updated_user = @user.login
      @user.save!
      self.current_user = @user
      request.env['HTTPS'] = nil unless params[:https]
      if params[:back_to].blank?
        #redirect_to(:controller => '/')
        redirect_to(:controller => 'account', :action => 'list')
      else
        redirect_to params[:back_to]
      end
      flash[:notice] = _("Update your infomation.")
    end
  rescue ValidationAbort
    flash[:warning] = $!
  rescue ActiveRecord::RecordInvalid
  end

  def signup
    @page_title = '[アカウント新規作成]'
    @user = User.new(params[:user])
    @user.email = @user.login

    @employee = Employee.new
    conf_hour_total = SysConfig.get_hour_total_full
    @employee.regular_working_hour = conf_hour_total.value1.split(':')[0]
    @calendar = true
    @departments = Department.find(:all, :order => "display_order") 
    
    return unless request.post?
    ActiveRecord::Base.transaction do
      #@user.access_level_type = 'normal'
      @user.per_page = 50
      @user.created_user = 'signup'
      @user.updated_user = 'signup'
#      @user.make_activation_code if ENV['ENABLE_MAIL_ACTIVATE']
#      @user.activate_url = url_for(:controller => 'account', :action => 'activate', :id => @user.activation_code)

      parseTimes(params)
      @employee = Employee.new(params[:employee])
      @user.save!

#      @employee.employee_code = @employee.insurance_code.to_i + 9800

      @employee.user_id = @user.id
      @employee.save!

      # アップロードファイルの保存
      store_upload_file

      @employee.user_id = @user.id
      @employee.save!

      # 初期有給休暇を作成
      Vacation.create_init_vacation(@user, @employee.entry_date.to_date)

    end

    request.env['HTTPS'] = nil unless params[:https]
    if ENV['ENABLE_MAIL_ACTIVATE']
      self.current_user = nil
      redirect_to(:action => 'mailsend')
      flash[:notice] = _("Thanks for signing up! check your mail.")
    else
      #self.current_user = @user
      #redirect_back_or_default(:controller => 'account', :action => 'list')
      #redirect_to(:controller => 'account', :action => 'list')
      
      #交通費登録へ
      redirect_to(:controller => 'route_expense_detail', :action => 'new', :id => @user)
      flash[:notice] = _("Thanks for signing up!")
    end
  rescue ValidationAbort
    flash[:err] = $!.to_s
    render :action => 'signup'
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  def forgot_password
    if request.post?
      unless @user = User.find(:first, :conditions => ["deleted = 0 and login = ?", params[:login]])
        flash[:warning] = _("User not found.")
        return
      end
      @user.make_activation_code if ENV['ENABLE_MAIL_ACTIVATE']
      @user.forgot_password_url = url_for(:controller => 'account', :action => 'forgot_password', :id => @user.activation_code)
      @user.forgot_password!
      flash[:notice] = _("Mail send now, check your mail box.")
    elsif params[:id]
      unless @user = User.find(:first, :conditions => ["deleted = 0 and activation_code = ?", params[:id]])
        flash[:warning] = _("User not found.")
        return
      end
      if @user.activate_send_at.blank? || (@user.activate_send_at + 1.day) < Time.now
        flash[:warning] = _("Activate is too rate. Please input email and resend activate message.")
        return redirect_to(:action => 'forgot_password')
      end
      @user.forgot_password_fix
      self.current_user = @user
      flash[:notice] = _("Update your passwod.")
      redirect_to :action => 'update'
    end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = _("You have been logged out.")
    redirect_back_or_default(:controller => 'home', :action => 'index')
  end
  
  def activate
    if request.post?
      params[:id] = params[:activation_code]
    end
    unless params[:id]
      return flash[:warning] = _("Not Activate.")
    end
    unless @user = User.find_by_activation_code(params[:id])
      return flash[:warning] = _("Not Activate.")
    end
    if @user.activate_send_at.blank? || (@user.activate_send_at + 1.day) < Time.now
      flash[:warning] = _("Activate is too rate. Please input email and resend activate message.")
      return redirect_to(:action => 'forgot_password')
    end
    @user.site_url = url_for(:controller => '/')
    if @user.activate
      self.current_user = @user
      redirect_back_or_default(:controller => 'home', :action => 'index')
      flash[:notice] = _("Your account has been activated.") 
    else
      flash[:warning] = _("Not Activate.")
    end
  rescue ActiveRecord::RecordInvalid
  end
  
  def view
    @page_title = '[アカウント情報]'
    unless @user = User.find(:first, :conditions => ["id = ? and deleted = 0", params[:id]])
      flash[:warning] = _("User not found.")
      return redirect_to(:controller => '/')
    end
  end

  def show
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
    @route_expense_detail_pages, @route_expense_details = paginate(:route_expense_details, :per_page => SysConfig.get_per_page_count, :include => [ :route_expense ], :conditions => ["route_expenses.user_id = ? and route_expenses.deleted = 0 and route_expense_details.deleted = 0", params[:id]]) 
  end

  def edit
    @calendar = true
    @user = User.find(params[:id], :conditions => "deleted = 0 ") 
    @departments = Department.find(:all, :conditions => "deleted = 0 ", :order => "display_order")
  end

  def make_conditions
    sql = "users.deleted = 0 and employees.deleted = 0"
    param = []
    include = [ :user, :department ]
    order_by = "users.id"
    
    if request.post?
      if params[:display_button]
        if !params[:all_display_checkbox]
          sql += " and employees.resignation_date is null"
          @all_display = false
        else
          @all_display = true
        end
      end
    else
      if !@all_display
        sql += " and employees.resignation_date is null"
      end
    end
    
    {:conditions => param.unshift(sql), :include => include, :per_page => 50, :order => order_by}
  end

  def list
    @calendar = true
    @all_display = true
    if action_name.match(/list2.*/)
      @all_display = false
    end
    @edit_type = params[:edit_type] || 'list_all'
    @departments = Department.find(:all, :conditions => "deleted = 0 ")

    cond = make_conditions
    @employee_pages, @employees = paginate(:employees, cond)
  end

  def list2
    list
  end

  def address_list
    list
    render :action => 'list'
  end
  
  def do_search
    @calendar = true
    @edit_type = params[:edit_type]
    @departments = Department.find(:all, :conditions => "deleted = 0 ")
    parseTimes(params)
    fromBirthday = nil
    toBirthday = nil
    @fromEntryDate = nil
    @toEntryDate = nil
    fromDate = nil
    toDate = nil
    if params[:age_from] != "" && params[:age_to] == ""
      tmp = Employee.calAboutBirthdayFromAge(params[:age_from])
      toBirthday = Date.new(tmp.year, tmp.month, 1) - 1.day
      fromBirthday = Date.new(tmp.year, tmp.month, 1) - 12.month
      
    elsif params[:age_to] != "" && params[:age_from] == ""
      tmp = Employee.calAboutBirthdayFromAge(params[:age_to])
      toBirthday = Date.new(tmp.year, tmp.month, 1) - 1.day
      fromBirthday = Date.new(tmp.year, tmp.month, 1) - 12.month
      
    elsif params[:age_to] != "" && params[:age_from] != ""
      tmp = Employee.calAboutBirthdayFromAge(params[:age_from])
      tmp2 = Employee.calAboutBirthdayFromAge(params[:age_to])
      toBirthday = Date.new(tmp.year, tmp.month, 1) - 1.day
      fromBirthday = Date.new(tmp2.year, tmp2.month, 1) - 12.month

#  def mailsend
#  end
      
    end
    
    if params[:working_year_from] != "" && params[:working_year_to] == ""
      tmp = Employee.calEntryFromWorkingYear(params[:working_year_from])
      d = Date.new(tmp.year, tmp.month, 1)
      @fromEntryDate = d
      @toEntryDate = d + 1.month - 1.day
    elsif params[:working_year_to] != "" && params[:working_year_from] == ""
      tmp = Employee.calEntryFromWorkingYear(params[:working_year_to])
      d = Date.new(tmp.year, tmp.month, 1)
      @fromEntryDate = d
      @toEntryDate = d + 1.month - 1.day
    elsif params[:working_year_to] != "" && params[:working_year_from] != ""
      tmp = Employee.calEntryFromWorkingYear(params[:working_year_from])
      tmp2 = Employee.calEntryFromWorkingYear(params[:working_year_to])
      d = Date.new(tmp.year, tmp.month, 1)
      d2 = Date.new(tmp2.year, tmp2.month, 1)
      @fromEntryDate = d2
      @toEntryDate = d + 1.month - 1.day
    end
    
    if params[:date_from] != "" && params[:date_to] == ""
      fromDate = params[:date_from]
      toDate = params[:date_from]
    elsif params[:date_to] != "" && params[:date_from] == ""
      fromDate = params[:date_to]
      toDate = params[:date_to]
    elsif params[:date_to] != "" && params[:date_from] != ""
      fromDate = params[:date_from]
      toDate = params[:date_to]
    end
    
    arr1 = []
    arr1 << "users.deleted = 0"
    arr1 << "and employees.deleted = 0"
    arr1 << "and (employees.department_id = ?)" unless params[:employee][:department_id].blank?
    arr1 << "and (employees.address1_1 || employees.address1_2 || employees.address1_3 || employees.address1_4 like ?)" unless params[:address].blank?
    arr1 << "and (employees.sex_type = ?)" if ["man","woman"].include?(params[:employee][:sex_type])
    arr1 << "and (employees.birthday_date between ? and ?)" unless toBirthday.blank?
    arr1 << "and (employees.entry_date between ? and ?)" unless @toEntryDate.blank?
    arr1 << "and (employees.resignation_date between ? and ?)" unless toDate.blank?
    searchConditionStr = arr1.join("\n")
    searchCondition = [searchConditionStr]
    searchCondition << params[:employee][:department_id] unless params[:employee][:department_id].blank?
    searchCondition << "%#{params[:address]}%" unless params[:address].blank?
    searchCondition << params[:employee][:sex_type] if ["man","woman"].include?(params[:employee][:sex_type])
    searchCondition << fromBirthday << toBirthday unless toBirthday.blank?
    searchCondition << @fromEntryDate << @toEntryDate unless @toEntryDate.blank?
    searchCondition << fromDate << toDate unless toDate.blank?
    
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :include => [ :user, :department ], :conditions => searchCondition, :order => "users.id")
    render :action => 'list'
  end
  
  def open_file_picture
    user = User.find(params[:id], :conditions => "deleted = 0 ") 
    filename = user.employee.attached_file1.to_s
    file_dir = File.join(Rails.root,'tmp','attach')
    send_file File.join(file_dir,filename), :type => 'image/jpeg', :disposition => 'inline', :filename => filename
  rescue ActionController::MissingFile
    flash[:notice] = '写真が見つかりませんでした。'
    redirect_to :action => 'show', :id => user
  end
  
  def open_file_history1
    user = User.find(params[:id], :conditions => "deleted = 0 ") 
    filename = user.employee.attached_file2.to_s
    file_dir = File.join(Rails.root,'tmp','attach')
    send_file File.join(file_dir,filename), :type => 'application/pdf', :disposition => 'inline', :filename => filename
  rescue ActionController::MissingFile
    flash[:notice] = '職務経歴書が見つかりませんでした。'
    redirect_to :action => 'show', :id => user
  end
  
  def open_file_history2
    user = User.find(params[:id], :conditions => "deleted = 0 ") 
    filename = user.employee.attached_file3.to_s
    file_dir = File.join(Rails.root,'tmp','attach')
    send_file File.join(file_dir,filename), :type => 'application/pdf', :disposition => 'inline', :filename => filename
  rescue ActionController::MissingFile
    flash[:notice] = '職務経歴書が見つかりませんでした。'
    redirect_to :action => 'show', :id => user
  end
  
  def open_file_history3
    user = User.find(params[:id], :conditions => "deleted = 0 ") 
    filename = user.employee.attached_file4.to_s
    file_dir = File.join(Rails.root,'tmp','attach')
    send_file File.join(file_dir,filename), :type => 'application/pdf', :disposition => 'inline', :filename => filename
  rescue ActionController::MissingFile
    flash[:notice] = '職務経歴書が見つかりませんでした。'
    redirect_to :action => 'show', :id => user
  end

private
  def xpersonnel_department_required
    unless logged_in? && current_user.personnel_department? || current_user.accounting?
      redirect_to :controller => '/'
      return false
    end
    return true
  end
end
