# -*- encoding: utf-8 -*-
class EmployeeController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => "resignation_date is null and deleted = 0")
  end
  
  def address_list
    list
    render :action => 'list'
  end
  
  def order_by_birthday_asc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'birthday_date')
    render :action => 'list'
  end
  
  def order_by_birthday_desc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'birthday_date desc')
    render :action => 'list'
  end
  
  def order_by_entry_date_asc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'entry_date')
    render :action => 'list'
  end
  
  def order_by_entry_date_desc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'entry_date desc')
    render :action => 'list'
  end
  
  def order_by_zip1_asc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'zip1')
    render :action => 'list'
  end
  
  def order_by_zip1_desc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'zip1 desc')
    render :action => 'list'
  end
  
  def order_by_tel1_asc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'tel1')
    render :action => 'list'
  end
  
  def order_by_tel1_desc
    @employee_pages, @employees = paginate(:employees, :per_page => 50, :conditions => ["active_flg = ? and deleted = 0", 1], :order => 'tel1 desc')
    render :action => 'list'
  end
  
  def show
    @employee = Employee.find(params[:id], :conditions => "deleted = 0 ")
  end

  def store_upload_file
    file_dir = File.join(Rails.root,'tmp','attach')
    if params[:upload]
      if !params[:upload]['file1'].blank?
        file1 = params[:upload]['file1']
        ext = File.extname(file1.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がjpgのファイルでなければなりません") if ext != '.jpg'
        filename1 = "employee_#{@employee.id.to_s}_1" + ext
        @employee.attached_file1 = filename1
        File.open(File.join(file_dir, filename1), "wb"){ |f| f.write(file1.read) }
      end
      if !params[:upload]['file2'].blank?
        file2 = params[:upload]['file2']
        ext = File.extname(file2.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がpdfのファイルでなければなりません") if ext != '.pdf'
        filename2 = "employee_#{@employee.id.to_s}_2" + ext
        @employee.attached_file2 = filename2
        File.open(File.join(file_dir, filename2), "wb"){ |f| f.write(file2.read) }
      end
      if !params[:upload]['file3'].blank?
        file3 = params[:upload]['file3']
        ext = File.extname(file3.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がpdfのファイルでなければなりません") if ext != '.pdf'
        filename3 = "employee_#{@employee.id.to_s}_3" + ext
        @employee.attached_file3 = filename3
        File.open(File.join(file_dir, filename3), "wb"){ |f| f.write(file3.read) }
      end
      if !params[:upload]['file4'].blank?
        file4 = params[:upload]['file4']
        ext = File.extname(file4.original_filename.to_s).downcase
        raise ValidationAbort.new("写真は、拡張子がpdfのファイルでなければなりません") if ext != '.pdf'
        filename4 = "employee_#{@employee.id.to_s}_4" + ext
        @employee.attached_file4 = filename4
        File.open(File.join(file_dir, filename4), "wb"){ |f| f.write(file4.read) }
      end
    end
  end

  def new
    @page_title = '[アカウント新規作成]'
    @user = User.find(params[:id])
    if @user.employee
      raise Exception.new("Employee is exists.")
    end

    @employee = Employee.new
    conf_hour_total = SysConfig.get_hour_total_full
    @employee.regular_working_hour = conf_hour_total.value1.split(':')[0]
    @calendar = true
    @departments = Department.find(:all, :order => "display_order") 
    
    return unless request.post?
    ActiveRecord::Base.transaction do
      parseTimes(params)
      @employee = Employee.new(params[:employee])

      @employee.employee_code = @employee.insurance_code.to_i + 9800

      @employee.user_id = @user.id
      @employee.save!

      # アップロードファイルの保存
      store_upload_file

      # 初期有給休暇を作成
      Vacation.create_init_vacation(@user, @employee.entry_date.to_date)
    end

    #交通費登録へ
    redirect_to(:controller => 'route_expense_detail', :action => 'new', :id => @user, :back_to => back_to)
    flash[:notice] = _("Thanks for signing up!")
  rescue ValidationAbort
    flash[:err] = $!.to_s
    render :action => 'new'
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @calendar = true
    @page_title = '[アカウント情報変更]'
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
    unless @employee = @user.employee
      @employee = Employee.new(:user_id => @user.id)
      conf_hour_total = SysConfig.get_hour_total_full
      @employee.regular_working_hour = conf_hour_total.value1.split(':')[0]
    end

    @departments = Department.find(:all, :order => "display_order") 
    
    if request.post?
      parseTimes(params)
      @employee.attributes = params[:employee]

      # アップロードファイルの保存
      store_upload_file

#      @employee.employee_code = @employee.insurance_code.to_i + 9800
#      old_employee = Employee.find(@user.employee.id)

      @employee.save!

      request.env['HTTPS'] = nil unless params[:https]
      if params[:back_to].blank?
        redirect_to(:controller => 'employee', :action => 'list')
      else
        redirect_to params[:back_to]
      end
      flash[:notice] = _("Update your infomation.")
    end
  rescue ValidationAbort
    flash[:warning] = $!
  rescue ActiveRecord::RecordInvalid
  end
  
  def edit_bank
    @employee = Employee.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update_bank
    @employee = Employee.find(params[:id], :conditions => "deleted = 0 ")
    @employee.attributes = params[:employee] 
    if @employee.save
      flash[:notice] = 'Employee was successfully updated.'
      redirect_to :action => 'show', :id => @employee
    else
      render :action => 'edit'
    end
  end

  def destroy
    #Employee.find(params[:id]).destroy
    employee = Employee.find(params[:id], :conditions => "deleted = 0 ")
    employee.deleted = 9
    employee.save!
    redirect_to :action => 'list'
  end
end
