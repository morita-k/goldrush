# -*- encoding: utf-8 -*-
class AccountController < ApplicationController

  def new
    @page_title = '[アカウント新規作成]'
    @user = User.new(params[:user])
    @user.email = @user.login

    @employee = Employee.new

    @employee.init_default_working_times

    @calendar = true
    @departments = find_login_owner(:departments).order("display_order")
  end

  def create
    @user = create_model(:users, params[:user])
    @user.email = @user.login

    ActiveRecord::Base.transaction do
      #@user.access_level_type = 'normal'
      @user.per_page = 50

      parseTimes(params)
      @employee = create_model(:employees, params[:employee])
      @employee.set_regular_working_hour
      set_user_column @user
      set_user_column @employee
      @user.save!

      @employee.user_id = @user.id
      @employee.save!

      # アップロードファイルの保存
      store_upload_file

      @employee.user_id = @user.id
      @employee.save!
    end

    request.env['HTTPS'] = nil unless params[:https]
    if ENV['ENABLE_MAIL_ACTIVATE']
      self.current_user = nil
      redirect_to(:action => 'mailsend')
      flash[:notice] = _("Thanks for signing up! check your mail.")
    else
      redirect_to(:action => 'show', :id => @user)
      flash[:notice] = _("Thanks for signing up!")
    end
  rescue ValidationAbort
    @calendar = true
    @departments = find_login_owner(:departments).order("display_order")
    flash[:err] = $!.to_s
    render :action => 'new'
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    @departments = find_login_owner(:departments).order("display_order")
    render :action => 'new'
  end
  
  def show
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
  end

  def edit
    @calendar = true
    @page_title = '[アカウント情報変更]'
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
    unless @employee = Employee.where(user_id: @user.id).first
      @employee = Employee.new(:user_id => @user.id)
    end

    # TODO : furukawa : 基本勤務時間などが未登録の人がいた場合、下のコメントアウトを外すとデフォルトの値がformに現れる。
    # ただし、登録済のデータも上書きされてしまうので注意。
    # ・・・というか、SQLで直接入れた方がいいかもねー。
    # @employee.init_default_working_times
    @departments = find_login_owner(:departments).order("display_order")
    
    if request.post?
      parseTimes(params)
      @employee.attributes = params[:employee]
      @employee.set_regular_working_hour

      # アップロードファイルの保存
      store_upload_file

      set_user_column @employee
      @employee.save!

      u = params[:user]
      if (u.include?("password") || u.include?("password_confirmation")) && (u["password"].blank? && u["password_confirmation"].blank?)
        u.delete("password")
        u.delete("password_confirmation")
      end
      @user.attributes = u
      set_user_column @user
      @user.save!

      request.env['HTTPS'] = nil unless params[:https]
      if params[:back_to].blank?
        redirect_to(:controller => 'employee', :action => 'index')
      else
        redirect_to params[:back_to]
      end
      flash[:notice] = _("Update your infomation.")
    end
  rescue ValidationAbort
    flash[:warning] = $!
  rescue ActiveRecord::RecordInvalid
  end

  def make_conditions
    sql = "users.deleted = 0 and employees.deleted = 0"
    param = []
    include = [ :user, :department ]
    order_by = "users.id"
    
    {:conditions => param.unshift(sql), :include => include, :per_page => 50, :order => order_by}
  end

  def index
    @calendar = true
    @edit_type = params[:edit_type] || 'list_all'
    @departments = find_login_owner(:departments).where("deleted = 0")

    cond = make_conditions
    @employee_pages, @employees = paginate(:employees, cond)
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
end
