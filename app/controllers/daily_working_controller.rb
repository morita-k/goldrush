# -*- encoding: utf-8 -*-
class DailyWorkingController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @daily_working_pages, @daily_workings = paginate :daily_workings, :per_page => 30, :conditions => "deleted = 0 "
  end

  def show
    @daily_working = DailyWorking.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @calendar = true
    @daily_working = DailyWorking.new
  end

  def create
    parseTimes(params)
    @daily_working = DailyWorking.new(params[:daily_working])
    @daily_working.user_id = current_user.id
    set_user_column @daily_working
    if @daily_working.save
      flash[:notice] = 'DailyWorking was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    set_target_user

    @check_errors = []
    #@calendar = true
    if params[:target_date]
      @daily_working = DailyWorking.find(:first, :conditions => ["deleted = 0 and working_date = ? and user_id = ?", params[:target_date].to_date, @target_user.id])
    else
      @daily_working = DailyWorking.find(params[:id], :conditions => "deleted = 0 ")
    end
    if @daily_working
      if holiday_application = @daily_working.get_holiday_application
        flash[:notice] = holiday_application.working_type_name + "申請が提出されています"
      end
      @daily_working.init_default_value(@target_employee, holiday_application) if @daily_working.action_type == 'blank'
    else
      flash[:notice] = "先に作業日報を作成してください。"
      redirect_to params[:back_to]
      return
    end
  end

  def update
    set_target_user
#    parseTimes(params)
    @daily_working = DailyWorking.find(params[:id], :conditions => "deleted = 0 ")
    # もしFixした休日出勤を変更するときは代休時間の計算をしなければならない
    if @daily_working.action_type == 'fixed'# && @daily_working.working_type == 'on_holiday_working'
      if @daily_working.working_type == 'on_holiday_working'
        @daily_working.old_working_time = @daily_working.hour_total
      elsif @daily_working.working_type == 'all_day_working'
        old_working_type = 'all_day_working' # 2011/3/9 Fixした全日出勤を変更するとき
      end
    end
    @daily_working.set_time_str(params[:daily_working])
    # 遅延証明受理者をセットする処理
    #if @daily_working.delayed_cancel_flg == 0 and params[:daily_working][:delayed_cancel_flg] == "1"
    #  @daily_working.delayed_cancel_user_id = current_user.id
    #elsif @daily_working.delayed_cancel_flg == 1 and params[:daily_working][:delayed_cancel_flg] == "0"
    #  @daily_working.delayed_cancel_user_id = nil
    #end
    @daily_working.attributes = params[:daily_working]
    
    # 申請チェックを追記して行く
    @check_errors = []
    flash[:notice] = ""
    
    @daily_working.convert10minutes
    #出社時間と退社時間のチェック
    if @daily_working.enable_in_out_time? && !@daily_working.in_out_time?
      flash[:notice] = "出社時間と退社時間が正しくありません。"
      return render(:action => 'edit')
    end
    
    holiday_application = @daily_working.get_holiday_application
    if holiday_application && holiday_application.working_type != @daily_working.working_type
      flash[:notice] = '休暇申請の勤務種別と選択された勤務種別が違います'
      return render(:action => 'edit')
    end

    #休日出勤のチェック
    if @daily_working.holiday_flg == 1 && @daily_working.working_type != 'on_holiday_working'
      flash[:notice] = '営業日ではないので、休日出勤以外は選べません'
      return render(:action => 'edit')
    end
    if @daily_working.holiday_flg != 1 && @daily_working.working_type == 'on_holiday_working'
      flash[:notice] = '休日ではないので、休日出勤は選べません'
      return render(:action => 'edit')
    end
    # 最大退勤時間のチェック
    if @daily_working.over_time?(@target_employee)
      flash[:notice] = "最大退勤時間を越えています。#{@target_employee.max_out_time}以降は翌日の登録にしてください"
      return render(:action => 'edit')
    end

    # 権限のチェック
    if (@daily_working.can_change_only_personnel_department?) and (!current_user.personnel_department?)
      flash[:notice] = "権限がありませんので、#{@daily_working.working_type_long_name}は選択できません"
      render :action => 'edit'
      return true
    end
    
    # 申請が出てない場合のチェック
    if @daily_working.need_application?
      unless @daily_working.check_working_application
        flash[:notice] += "#{@daily_working.working_type_long_name}申請が出ていませんので、登録ができません。申請を作成して下さい。<br/>"
        @check_errors << @daily_working.working_type
      end
    end

    #@daily_working.convert10minutes
    if @daily_working.calc_come_lately?(@target_employee) and !@daily_working.get_other_application('come_lately_app')
      if @daily_working.calc_come_lately_over_ele_time?
        flash[:notice] += "午前休申請が出ていませんので、登録ができません。午前休申請、もしくは午後休が重なる場合は休暇系の申請を作成して下さい。<br/>"
        @check_errors << 'only_PM_working'
      else
        flash[:notice] += "遅刻申請が出ていませんので、登録ができません。遅刻申請を作成して下さい。<br/>"
        @check_errors << 'come_lately_app'
      end
    end
    if @daily_working.calc_leave_early?(@target_employee) && !@daily_working.get_other_application('leave_early_app')
      if @daily_working.calc_come_early_over_ele_time?
        # TODO : furukawa : たぶんここ違う。ifとelse逆？
        flash[:notice] += "午後休申請が出ていませんので、登録ができません。午後休申請、もしくは午前休が重なる場合は休暇系の申請を作成して下さい。<br/>"
        @check_errors << 'only_AM_working'
      else
        flash[:notice] += "早退申請が出ていませんので、登録ができません。早退申請を作成して下さい"
        @check_errors << 'leave_early_app'
      end
    end
    if @daily_working.calc_over_time_taxi?(@target_employee) && !@daily_working.get_other_application('over_time_app')
      flash[:notice] += '残業申請が出ていませんので、登録ができません。残業申請を作成して下さい。<br/>'
      @check_errors << "over_time_app"
    end
    
    unless @check_errors.empty?
      return render(:action => 'edit')
    end


    if @daily_working.need_calc_total_hour?
      @daily_working.calc_working_hour(@target_employee)
    else
      @daily_working.clear_working_hour # 時間が関係しない区分(欠勤など)の場合は、0クリア
    end
    if @daily_working.occasion_dayoff?
      @daily_working.hour_total = 60 * 60 * @daily_working.user.employee.regular_working_hour
    end

    @daily_working.calc_flags(@target_employee) # 遅刻早退などのフラグを計算する
    # とりあえず、updatedにする 2011/3/9 全日出勤から各休暇届けに変更したときはfixedからupdatedにする
    if @daily_working.action_type != 'fixed' || (old_working_type == 'all_day_working' && @daily_working.working_type != 'all_day_working')
      @daily_working.action_type = 'updated'
    end
    #遅延証明フラグを変更
    if come_lately_app = @daily_working.get_other_application('come_lately_app')
      @daily_working.delayed_cancel_flg = come_lately_app.delayed_cancel_flg
      if @daily_working.delayed_cancel_flg == 1
        @daily_working.delayed_cancel_user_id = current_user.id 
      else
        @daily_working.delayed_cancel_user_id = nil
      end
    end
    set_user_column @daily_working
    ActiveRecord::Base.transaction do
      @daily_working.save!
      # 条件が満たされればfixされる
      # 全日で他申請もない場合は、即Fix。休日出勤の場合は勤務時間を計算する。それ以外は、登録時に申請が必要なのでFixしない。
      if @daily_working.action_type != 'fixed'
        @daily_working.change_fixed!(current_user.login)
      elsif @daily_working.working_type == 'on_holiday_working'
        @daily_working.calc_holiday_hour_date!(current_user.login)
      end
    end
    flash[:notice] = "日報を変更しました。"
    redirect_to(params[:back_to] || {:controller => 'monthly_working', :action => 'list'})

  rescue ActiveRecord::RecordInvalid
    render :action => 'edit', :id => params[:id]
  end

  # 申請が出てる時はこここないから、単純に登録でいい。
  def registr_all_day_working
    set_target_user
    @daily_working = DailyWorking.find(params[:daily_working_id], :conditions => "deleted = 0 ")
    @daily_working.init_default_value(@target_employee)
    @daily_working.calc_working_hour(@target_employee)
    @daily_working.action_type = 'fixed'
    set_user_column @daily_working
    ActiveRecord::Base.transaction do
      @daily_working.save!
    end
    flash[:notice] = "日報を全出で登録しました。"
    redirect_to(params[:back_to] || {:controller => 'monthly_working', :action => 'list'})
  end

  def destroy
    #DailyWorking.find(params[:id]).destroy
    daily_working = DailyWorking.find(params[:id], :conditions => "deleted = 0 ")
    daily_working.deleted = 9
    set_user_column daily_working
    daily_working.save!
    redirect_to :action => 'list'
  end

  def delayed_cancel
    daily_working = DailyWorking.find(params[:id], :conditions => "deleted = 0 ")
    daily_working.delayed_cancel_flg = (daily_working.delayed_cancel_flg + 1) % 2 # トグル
    daily_working.delayed_cancel_user_id = daily_working.delayed_cancel_flg == 0 ? nil : current_user.id
    set_user_column daily_working
    daily_working.save!
    redirect_to(params[:back_to] || {:action => 'edit', :id => daily_working})
  end

  def clear
    daily_working = DailyWorking.find(params[:id], :conditions => "deleted = 0 ")
    ActiveRecord::Base.transaction do
      daily_working.clear_daily_working!(current_user.login)
    end
    redirect_to(params[:back_to] || {:controller => '/'})
  end
end
