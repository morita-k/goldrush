# -*- encoding: utf-8 -*-
class MonthlyWorkingController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def xpopup_list
    list
    render :action => 'list', :layout => 'popup'
  end

  def list
    set_target_user
    set_list_info(params[:id], @target_user)
  end
  
  def set_list_info(base_month_id, target_user)
    if base_month_id
      @base_month = BaseMonth.find(base_month_id, :conditions => "deleted = 0")
    else
      @base_month = BaseMonth.get_base_month_by_date
    end

    unless @base_month
      raise Exception.new("基準月が初期化されていません")
    end

    if @monthly_working = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and base_month_id = ?", target_user.id, @base_month.id])
      @monthly_working.count_working_type
      @monthly_working.init_approval_list
    end
    @start_date = @base_month.start_date.to_date
    @vacation = Vacation.find(:first, :conditions => ["deleted = 0 and user_id = ?", target_user.id])
  end

  def show_by_user
    @application_approval = ApplicationApproval.find(params[:app_approval_id], :conditions => "deleted = 0 ")
    @user_id = params[:user_id]
    start_date = params[:start_date]
    end_date = params[:end_date]
    @base_month_pages, @base_months = paginate(:base_months, :per_page => 1, :conditions => ["base_months.deleted = 0 and start_date = ? and end_date = ?", start_date, end_date], :order => 'base_months.start_date')
    render :action => 'list_by_user'
  end

  def list_all_employee
    @user_pages, @users = paginate(:users, :per_page => 50, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 "], :order => "users.id")
    curdate = Date.today
    start_date = curdate - 12.month
    end_date = curdate
    @base_months = BaseMonth.find(:all, :conditions => ["start_date between ? and ? ", start_date, end_date], :order => "start_date")
  end
  
  def list_by_employee
    @monthly_working_pages, @monthly_workings = paginate(:monthly_workings, :per_page => 1, :conditions => ["monthly_workings.user_id = ? and base_month_id = ?", params[:id], params[:base_month_id]])
    render :action => 'list_by_user'
  end
  
  def show
    @monthly_working = MonthlyWorking.find(params[:id])
  end

  def new
    @monthly_working = MonthlyWorking.new
  end

  def create
    @monthly_working = MonthlyWorking.new(params[:monthly_working])
    @monthly_working.user_id = current_user.id
    if @monthly_working.save
      flash[:notice] = 'MonthlyWorking was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @monthly_working = MonthlyWorking.find(params[:id])
  end

  def update
    @monthly_working = MonthlyWorking.find(params[:id])
    @monthly_working.attributes = params[:monthly_working] 
    set_user_column @monthly_working
    if @monthly_working.save!
      flash[:notice] = '月所定労働日数が変更されました。'
    end
    redirect_to params[:back_to]
  end
  
  def destroy
    #MonthlyWorking.find(params[:id]).destroy
    monthly_working = MonthlyWorking.find(params[:id], :conditions => "deleted = 0 ")
    monthly_working.deleted = 9
    monthly_working.save!
    redirect_to :action => 'list'
  end
  
  def total_working_hour
    list_all_employee
    render :action => 'list_all_employee'
  end
  
  def total_negative_hour
    list_all_employee
    render :action => 'list_all_employee'
  end
  
  def total_latearly_count
    list_all_employee
    render :action => 'list_all_employee'
  end
  
  def total_vacation_count
    list_all_employee
    render :action => 'list_all_employee'
  end
  
  def working_time_sheet
    @cur_year = Date.today.year
    @cur_month = Date.today.month
    @arr_year = [
              [@cur_year - 2, @cur_year - 2],
              [@cur_year - 1, @cur_year - 1],
              [@cur_year, @cur_year],
              [@cur_year + 1, @cur_year + 1],
              [@cur_year + 2, @cur_year + 2],
                ]
    @arr_month = [
              [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6],
              [7, 7], [8, 8], [9, 9], [10, 10], [11, 11], [12, 12],
                 ]
    @cur_year = params[:reinit_year] if !params[:reinit_year].blank?
    @cur_month = params[:reinit_month] if !params[:reinit_month].blank?
    list_all_employee
    render :action => 'list_all_employee'
  end
  
  def init_base_month
    #BaseMonth.init_data
    start_date = nil
    end_date = nil
    month_start_date = SysConfig.get_month_start_date.value1
    ActiveRecord::Base::transaction() do
      base_month = BaseMonth.find(:first, :conditions => ["last_flg = ? and deleted = 0", 1])
      if base_month
         start_date = base_month.start_date.to_date + 1.month
         end_date = base_month.end_date.to_date + 1.month
         base_month.last_flg = 0
         set_user_column base_month
         base_month.save!
      else
        curdate = Date.today
        d = Date.new(curdate.year, curdate.month, month_start_date.to_i)
        start_date = d
        end_date = (d + 1.month) - 1.day
      end
      #create next month
      base_month = BaseMonth.new
      base_month.report_month = end_date.to_date.month
      base_month.start_date = start_date.to_date
      base_month.end_date = end_date.to_date
      base_month.last_flg = 1
      set_user_column base_month
      base_month.save!
    end
    redirect_to params[:back_to]
  end 
  
  def do_init_monthly_working(base_month, user)
    ActiveRecord::Base::transaction() do
      labor_day_total = 0
      if MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and base_month_id = ?", user.id, base_month.id])
        flash[:err] = "すでに作業日報データが存在します"
        return
      end
      monthly_working = MonthlyWorking.new# unless monthly_working
      monthly_working.user_id = user.id
      monthly_working.base_month_id = base_month.id
      monthly_working.application_date = Time.now
      monthly_working.report_month = base_month.report_month
      monthly_working.start_date = base_month.start_date.to_date
      monthly_working.end_date = base_month.end_date.to_date
      monthly_working.next_time_flg = 0
      monthly_working.last_flg = 0
      monthly_working.labor_day_total = 0
      set_user_column monthly_working
      
      base_dates = BaseDate.find(:all, :conditions => ["calendar_date between ? and ? and deleted = 0", base_month.start_date, base_month.end_date], :order => "calendar_date ")
      if base_dates.size < (base_month.end_date - base_month.start_date)
        flash[:err] = "基準日データが所定の日数に足りません。初期化が必要です"
        return
      end

      monthly_working.save!

      weekly_report_tmp = WeeklyReport.new
      base_dates.each do |base_date|
        labor_day_total = labor_day_total + 1
        if base_date.day_of_week == 1
          weekly_report = WeeklyReport.new# unless weekly_report
          weekly_report.user_id = user.id
          weekly_report.base_month_id = base_month.id
          weekly_report.report_date = Date.today.to_date
          weekly_report.start_date = base_date.calendar_date.to_date
          weekly_report.end_date = base_date.calendar_date.to_date + 6.day
#          weekly_report.approval_status_type = 'entry'
          set_user_column weekly_report
          weekly_report.save!
          weekly_report_tmp = weekly_report
        end
        
        #作業日を設定
        daily_working = DailyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and monthly_working_id = ? and working_date = ?", user.id, monthly_working.id, base_date.calendar_date])
        daily_working = DailyWorking.new unless daily_working
        daily_working.user_id = user.id
        daily_working.base_date_id = base_date.id
        daily_working.monthly_working_id = monthly_working.id
        daily_working.working_date = base_date.calendar_date.to_date
        daily_working.action_type = 'blank'
        if [0, 6].include?(base_date.day_of_week) or base_date.holiday_flg == 1
          daily_working.holiday_flg = 1
          labor_day_total = labor_day_total - 1
        end
        set_user_column daily_working
        daily_working.save!
      end
      monthly_working.labor_day_total = labor_day_total
      set_user_column monthly_working
      monthly_working.save!
    end #transaction
  end

  def init_monthly_working
     base_month = BaseMonth.find(params[:id], :conditions => "deleted = 0")
     user = User.find(params[:user_id], :conditions => "deleted = 0")
     do_init_monthly_working(base_month, user)
    redirect_to params[:back_to]
  end
  
  def init_monthly_working_admin
    user_id = params[:user_id]
    start_date = params[:start_date]
    end_date = params[:end_date]
    retval = do_init_monthly_working(start_date.to_date, end_date.to_date, user_id)
    if retval == 1
      flash[:notice] = '現在の基準月が存在しませんので、勤務表と週報が作成されていません。管理者に連絡して下さい。'
      redirect_to params[:back_to]
      return true
    elsif retval == 2
      flash[:notice] = '次の基準月が存在しませんので、次月に週報が作成されていません。管理者に連絡して下さい。'
      redirect_to params[:back_to]
      return true
    else
      flash[:notice] = 'データ初期が成功しました。'
      redirect_to params[:back_to]
      return true
    end
  end
  
  def send_monthly_working
    monthly_working = MonthlyWorking.find(params[:id], :conditions => "deleted = 0 ")
    monthly_working.init_approval_list # その月の申請データを一括で持ってくる
    #monthly_working.count_working_type

    #前月の月報申請チェック
    unless monthly_working.last_mw_applicated?
      flash[:err] = "先月の勤務表がまだ申請されていません。先月分の申請／承認を先に行ってください"
      redirect_to params[:back_to]
      return true
    end

    #前月の月報承認チェック
    unless monthly_working.last_mw_fixed?
      flash[:err] = "先月の勤務表がまだ承認されていません。承認者に確認してください"
      redirect_to params[:back_to]
      return true
    end

    #入力されてないデータチェック
    if monthly_working.no_input_data_count > 0
      flash[:err] = "#{monthly_working.no_input_data_count}件の日報が登録されていません。登録してください"
      redirect_to params[:back_to]
      return true
    end

    #入力されてないデータチェック（休日）
    if monthly_working.no_input_data_count_holiday > 0
      flash[:err] = "#{monthly_working.no_input_data_count_holiday}件の休日出勤日報が登録されていません。登録してください"
      redirect_to params[:back_to]
      return true
    end

    #日報承認チェック
    if monthly_working.entry_working_app_count > 0
      flash[:err] = "#{monthly_working.entry_working_app_count}件の勤怠申請が承認されていません。承認者に確認してください"
      redirect_to params[:back_to]
      return true
    end
    
    ActiveRecord::Base::transaction() do
      #monthly_working = MonthlyWorking.find(params[:id], :conditions => "deleted = 0 ")
      monthly_working.application_date = Time.now

      #出退勤表に承認者を設定
      base_application = BaseApplication.new
      base_application.user_id = monthly_working.user_id
      base_application.application_type = 'monthly_working_app'
      base_application.approval_status_type = 'entry'
      base_application.application_date = monthly_working.application_date
      set_user_column base_application
      base_application.save!

      monthly_working.base_application_id = base_application.id
      monthly_working.labor_day_total = monthly_working.labor_day_total.to_i # ?
      set_user_column monthly_working
      monthly_working.save!

      #週報・出退勤表での全て承認者を取る。
      approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = ? and deleted = 0", monthly_working.user_id, 'report_xxx', 1])
      if approval_authorities.empty?
        raise ValidationAbort.new('承認者が一人も登録されていません。承認権限設定をしてください')
      end
      count = 0
      for approval_authority in approval_authorities
        count = count + 1
        application_approval = ApplicationApproval.find(:first, :conditions => ["deleted = 0 and approver_id = ? and base_application_id = ?", approval_authority.approver_id, base_application.id])
        application_approval = ApplicationApproval.new unless application_approval
        application_approval.user_id = approval_authority.user_id
        application_approval.base_application_id = base_application.id
#        application_approval.monthly_working_id = monthly_working.id
        application_approval.application_type = 'monthly_working_app'
        application_approval.approver_id = approval_authority.approver_id
        application_approval.approval_status_type = 'entry'
        application_approval.approval_order = count
        set_user_column application_approval
        application_approval.save!
      end
      flash[:notice] = '承認者に送りました。'
      redirect_to params[:back_to]
    end
  end
  
  def clear_monthly_working
    count = 0
    target_year = params[:reinit_year]
    target_month = params[:reinit_month]
    conf_month_start_date = SysConfig.get_month_start_date
    target_day = conf_month_start_date.value1 if conf_month_start_date
    target_date = Date.new(target_year.to_i, target_month.to_i, target_day.to_i)
    target_base_month = BaseMonth.get_base_month_by_date(target_date)
    users = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 "], :order => "users.id")
    ActiveRecord::Base::transaction() do
      users.each do |user|
        monthly_working = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and base_month_id = ?", user.id, target_base_month.id]) if target_base_month
        if monthly_working
          monthly_working.daily_workings.each do |daily_working|
            daily_working = DailyWorking.find(daily_working.id)
            daily_working.clear_daily_working!(current_user.login)
          end
          count = count + 1
        end
      end
    end
    
    #ActiveRecord::Base::transaction() do
    #  monthly_working = MonthlyWorking.find(params[:id], :conditions => "deleted = 0")
    #  monthly_working.daily_workings.each do |daily_working|
    #    daily_working = DailyWorking.find(daily_working.id)
    #    daily_working.clear_daily_working!(current_user.login)
    #  end
    #end
    if count > 0 
      flash[:notice] = "#{count}件、再初期化しました。"
    else
      flash[:notice] = "#{count}件も再初期化されていません。"
    end
    redirect_to (url_for(:controller => 'monthly_working', :action => 'working_time_sheet', :reinit_year => target_year, :reinit_month => target_month))
    #redirect_to params[:back_to]
  end


  def cancel_monthly_working
    monthly_working = MonthlyWorking.find(params[:id], :conditions => "deleted = 0 ")
    
    base_application = monthly_working.base_application
    base_application.deleted = 9
    base_application.save!
    
    application_approvals = ApplicationApproval.find(:all, :conditions => ["deleted = 0 and base_application_id = ?", base_application.id])
    application_approvals.each do |application_approval|
      application_approval.deleted = 9
      application_approval.save!
    end
    
    monthly_working.base_application_id = nil
    monthly_working.save!

    redirect_to params[:back_to]
  end

end
