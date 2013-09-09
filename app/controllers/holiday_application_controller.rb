# -*- encoding: utf-8 -*-
class HolidayApplicationController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @calendar = true
    @approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = ? and deleted = 0", current_user.id, 'other_approval', 1], :order => 'approver_id')
    @holiday_application_pages, @holiday_applications = paginate(:holiday_applications, :per_page => 30, :conditions => ["user_id = ? and deleted = 0", current_user.id], :order => 'application_date DESC, id DESC ')
  end
  
  def list_by_approver
    @holiday_application_pages, @holiday_applications = paginate(:holiday_applications, :per_page => 30, :include => [ :application_approvals ], :conditions => ["application_approvals.approver_id = ? and holiday_applications.deleted = 0", current_user.id], :order => 'application_date DESC')
  end
  
  def do_search
    @calendar = true
    parseTimes(params)
    if params[:date_from] == "" && params[:date_to] == ""
      start_date = Date.today - 2.month
      end_date = Date.today + 1.month
    elsif params[:date_from] != "" && params[:date_to] == ""
      start_date = params[:date_from].to_date
      end_date = start_date
    elsif params[:date_from] == "" && params[:date_to] != ""
      end_date = params[:date_to].to_date
      start_date = end_date
    else
      start_date = params[:date_from].to_date
      end_date = params[:date_to].to_date
    end
    
    @approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = 1 and deleted = 0", current_user.id, 'other_approval'], :order => 'approver_id')
    @holiday_application_pages, @holiday_applications = paginate(:holiday_applications, :per_page => 30, :conditions => ["user_id = ? and deleted = 0 and application_date between ? and ?", current_user.id, start_date, end_date])
    render :action => 'list'
  end

  def show
    @holiday_application = HolidayApplication.find(params[:id], :conditions => "deleted = 0 ")
  end
  
  def show_by_user
    @application_approval = ApplicationApproval.find(params[:app_approval_id], :conditions => "deleted = 0 ")
    @holiday_application = HolidayApplication.find(params[:id], :conditions => "deleted = 0 ")
    if params[:back_to]
      session[:back_to] = params[:back_to]
    end
    render :action => 'show'
  end
  
  def popup_new
    new
    #@working_type = params[:working_type]
    params[:mode] = 'popup_new'
    render :action => 'new', :layout => 'popup'
  end

  # 申請の新規作成画面表示
  # チェック
  #対象日が指定されている場合
  #1. 対象日が申請の必要ない区分(warning)
  #2. 対象日に休暇申請あり(warning)
  def new
    @calendar = true
    @holiday_application = HolidayApplication.new
    @holiday_application.user_id = params[:id] || current_user.id
    
    @holiday_application.working_type = params[:working_type] || 'vacation_dayoff'
    #condition
    if params[:daily_working_id]
      daily_working = DailyWorking.find(params[:daily_working_id])
      unless daily_working.need_application?
        flash[:worning] = "休暇(休出)申請が必要ない区分のデータです"
      end
#      @holiday_application.user_id = current_user.id
      @holiday_application.application_date = Time.now
      @holiday_application.start_date = daily_working.working_date
      @holiday_application.end_date = daily_working.working_date
      unless @holiday_application.get_overlaid_holiday_applications.empty?
        flash[:warning] = "すでに#{@holiday_application.working_type_name}申請されています"
      end
      if @holiday_application.working_type == 'on_holiday_working'
        @holiday_application.end_time = params[:out_time].to_i if params[:out_time]
        @holiday_application.start_time = params[:in_time].to_i if params[:in_time]
      end
    else
      @holiday_application.application_date = Time.now
      @holiday_application.start_date = Date.today.to_date
      @holiday_application.end_date = Date.today.to_date
    end
  end

  # チェック内容
  # 1. 開始日 > 終了日
  # 2. 休日出勤など、範囲指定できない区分で開始日 != 終了日
  # 3. 申請が必要ない区分で申請された
  # 4. 作業日が存在しない
  # 5. 他の休暇申請と期間が重複
  # 6. 対象日の区分が申請必要なし
  # 7. 休日でないのに休日出勤申請
  # 8. 休暇申請の範囲内に平日がゼロ(休出以外の場合)
  # 9. 有給残不足
  def valid_holiday_application(holiday_application)
    # 一日限定の区分であれば、強制的に一緒にしてしまう

   
    if holiday_application.end_date.blank?
      holiday_application.end_date = holiday_application.start_date
    end
    if holiday_application.start_date.to_date > holiday_application.end_date.to_date
      raise ValidationAbort.new('終了日が正しくありません')
    end

    if holiday_application.monthly_working_applicated?
      raise ValidationAbort.new('対象月は、すでに勤務表が提出されています')
    end

    # ライフプラン・慶弔は申請必要なし
    if holiday_application.can_change_only_personnel_department?
      raise ValidationAbort.new("#{holiday_application.working_type_long_name}は申請が必要ありません")
    end

    daily_workings = holiday_application.get_daily_workings
    if daily_workings.empty?
      raise ValidationAbort.new("対象日が初期化されていません。勤務表の初期化を行ってください")
    end

    if holiday_application.new_record?
      holiday_applications = holiday_application.get_overlaid_holiday_applications
      unless holiday_applications.empty?
        raise ValidationAbort.new("すでに#{holiday_applications[0].working_type_name}申請されています")
      end
    end

    # 休日出勤以外の場合は休日含むかどうかのチェック
    if holiday_application.working_type != 'on_holiday_working'
      #-----moriyama修正箇所-----#
      #申請開始日～終了日に休日が含まれている場合の処理
      if base_dates = BaseDate.find(:all, :conditions => ["deleted = 0 and calendar_date >= ? and calendar_date <= ?", holiday_application.start_date, holiday_application.end_date])
        base_dates.each do |base_date|
          if base_date.holiday?
            raise ValidationAbort.new("申請対象範囲日に休日が含まれています。")
          end
        end #each
      end
      #--------------------------#
    end

    accept_app = false
    if params[:working_type]
      accept_app = true
    end
    daily_workings.each{|daily_working|
      if !accept_app
        unless daily_working.need_application?
          raise ValidationAbort.new("休暇(休出)申請が必要ない区分のデータです")
        end
      end
    }

    # 全日出勤、午前休、午後休、休日出勤以外の勤怠はオプションをつけることができない
    if !DailyWorking.regular_working_type.include?(holiday_application.working_type)
      #if !OtherApplication.get_other_applications(@other_application.user_id, holiday_application.start_date, holiday_application.end_date).empty?
      if !OtherApplication.get_other_applications(current_user.id, holiday_application.start_date, holiday_application.end_date).empty?
        raise ValidationAbort.new("すでに残業／他勤怠申請されています")
      end
      #if !BusinessTripApplication.get_business_trip_applications(@other_application.user_id, holiday_application.start_date, holiday_application.end_date).empty?
      if !BusinessTripApplication.get_business_trip_applications(current_user.id, holiday_application.start_date, holiday_application.end_date).empty?
        raise ValidationAbort.new("すでに出張申請されています")
      end
    end

    if holiday_application.working_type == 'on_holiday_working'
      daily_workings.each{|daily_working|
        if daily_working.holiday_flg != 1
          raise ValidationAbort.new('休日ではないので、休日出勤は選べません')
        end
        holiday_application.day_total = 1
      }
    else
      daycount = 0
      daily_workings.each{|daily_working|
        #休日のチェック
        next if daily_working.holiday_flg == 1
        daycount += 1
      }
      if daycount == 0
        raise ValidationAbort.new('対象日が祝日などのために、有効な日付がありません')
      end

      if holiday_application.working_type == 'summer_dayoff' && !Vacation.in_summer_vacation_period?(holiday_application.start_date, holiday_application.end_date)
        raise ValidationAbort.new('夏期休暇の対象範囲外です')
      end

      #if ['only_PM_working','only_PM_dayoff'].include?(holiday_application.working_type)
      if ['only_PM_working','only_AM_working'].include?(holiday_application.working_type)
        vacation_count = 0.5 * daycount
      else
        vacation_count = 1 * daycount
      end

      if ['compensatory_dayoff'].include?(holiday_application.working_type)
        holiday_application.hour_total = 60 * 60 * holiday_application.user.employee.regular_working_hour * daycount
      end

      # TODO: 代休／夏期休暇／ライフプランの考慮
      holiday_application.day_total = vacation_count
      unless holiday_application.enough_vacation_count?
        if ['compensatory_dayoff'].include?(holiday_application.working_type)
          raise ValidationAbort.new("#{holiday_application.working_type_name}残日数が足りませんので、申請ができません(申請中#{holiday_application.hour_count / (60*60)}時間)")
        else
          raise ValidationAbort.new("#{holiday_application.working_type_name}残日数が足りませんので、申請ができません(申請中#{holiday_application.app_count}日)")
        end
      end
    end
  end

  # 休暇申請新規登録処理
  def create
    parseTimes(params)
    @holiday_application = HolidayApplication.new
    @holiday_application.set_time_str(params[:holiday_application])
    @holiday_application.attributes = params[:holiday_application]
    #@holiday_application.user_id = current_user.id
    
    if @holiday_application.start_date.blank?
      if @holiday_application.working_type == 'on_holiday_working'
         raise ValidationAbort.new("出勤日を入力してください")
      else
        raise ValidationAbort.new("開始日を入力してください")
      end
    end
    
    valid_holiday_application(@holiday_application)

    #休暇申請での全て承認者を取る。
    approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = 1 and deleted = 0", @holiday_application.user_id, 'working_xxx'])
    if approval_authorities.empty?
      raise ValidationAbort.new('承認者が一人も登録されていません。承認権限設定をしてください')
    end
    
    ActiveRecord::Base.transaction do
      base_application = BaseApplication.new
      base_application.user_id = @holiday_application.user_id
      base_application.application_type = 'holiday_app'
      base_application.approval_status_type = 'entry'
      base_application.application_date = @holiday_application.application_date
      base_application.save!

      @holiday_application.base_application_id = base_application.id
      set_user_column @holiday_application
      @holiday_application.save!

      # 申請に承認者を設定
      order = 0
      for approval_authority in approval_authorities
        order += 1
        application_approval = ApplicationApproval.new
        application_approval.user_id = approval_authority.user_id
        application_approval.base_application_id = base_application.id
        application_approval.application_type = 'holiday_app'
        application_approval.application_date = @holiday_application.application_date
        application_approval.approver_id = approval_authority.approver_id
        application_approval.approval_status_type = 'entry'
        application_approval.approval_order = order
        set_user_column application_approval
        application_approval.save!
      end
    end

    if @holiday_application.working_type == 'on_holiday_working'
       flash[:notice] = "休日出勤申請情報を作成しました。"
    else
       flash[:notice] = "休暇申請情報を作成しました。"
    end
    if params[:mode] == 'popup_new'
      render :text => '<script type="text/javascript">popup_close();</script>', :layout => 'popup' # window.opener.reload();
    else
      redirect_to :action => 'show', :id => @holiday_application
    end
  rescue ValidationAbort
    flash[:warning] = $!.message
    @calendar = true
    if params[:mode] == 'popup_new'
      render :action => 'popup_err', :layout => 'popup'
    else
      params[:working_type] = @holiday_application.working_type if @holiday_application.working_type == 'on_holiday_working'
      render :action => 'new'
    end
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    if params[:mode]
      render :action => 'new', :layout => 'popup'
    else
      render :action => 'new'
    end
  end

  def edit
    @calendar = true
    @holiday_application = HolidayApplication.find(params[:id], :conditions => "deleted = 0 ")
    @holiday_application.application_date = Time.now
  end

  def update
    parseTimes(params)
    @holiday_application = HolidayApplication.find(params[:id], :conditions => "deleted = 0 ")
    @holiday_application.set_time_str(params[:holiday_application])
    @holiday_application.attributes = params[:holiday_application]
    base_application = @holiday_application.base_application
    if base_application.approval_status_type == 'fixed'
      raise ValidationAbort.new('すでに確定されているため、変更できません')
    end
    
    valid_holiday_application(@holiday_application)

    ActiveRecord::Base.transaction do
      if base_application.approval_status_type == 'reject'
        for application_approval in base_application.application_approvals
          application_approval.application_date = @holiday_application.application_date
          application_approval.approval_status_type = 'retry'
          set_user_column application_approval
          application_approval.save!
        end
        base_application.approval_status_type == 'retry'
      end

      base_application.application_date = @holiday_application.application_date
      set_user_column base_application
      base_application.save!

      set_user_column @holiday_application
      @holiday_application.save!
    end

    if @holiday_application.working_type == 'on_holiday_working'
       flash[:notice] = "休日出勤申請情報を更新しました。"
    else
       flash[:notice] = "休暇申請情報を更新しました。"
    end
    redirect_to(params[:back_to] || {:controller => '/'})
  rescue ValidationAbort
    flash[:warning] = $!
    @calendar = true
    render :action => 'edit'
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    render :action => 'edit'
  end

  def destroy
    holiday_application = HolidayApplication.find(params[:id], :conditions => "deleted = 0 ")
    holiday_application.deleted = 9
    set_user_column holiday_application
    holiday_application.save!
    redirect_to :controller => '/'
  end
  
end
