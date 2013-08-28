# -*- encoding: utf-8 -*-
require 'application_util'
class DailyWorking < ActiveRecord::Base
  include AutoTypeName
  include DateTimeUtil
  include ApplicationUtil

  belongs_to :monthly_working
  belongs_to :weekly_report
  belongs_to :user
  belongs_to :base_date
  has_many :working_logs, :conditions => "working_logs.deleted = 0"

  attr_accessor :old_working_time

  validates_length_of :summary, :maximum=>4000, :allow_blank => true

  # ワークログ設定
  def set_working_log!(str, login)
    WorkingLog.set_working_log!(self, str, login)
  end

  def clear_working_log!(login)
    working_logs.each do |wlog|
      wlog.deleted = 9
      wlog.updated_user = login
      wlog.save!
    end
  end

  def format_working_log
    str = ""
    working_logs.each do |wlog|
      hour = (wlog.working_time / 60 / 60).to_s.rjust 2, "0"
      min = (wlog.working_time / 60 % 60).to_s.rjust 2, "0"
      str << "[#{hour}:#{min}] #{wlog.working_kind}\n"
    end
    str
  end

  # 確定されているか判定
  def fixed?
    self.action_type == 'fixed'
  end

  def action_type_blank?
    self.action_type == 'blank'
  end

  def DailyWorking.get_working_days(user_id, start_date, end_date)
    find(:all, :conditions => ["deleted = 0 and holiday_flg = 0 and working_date between ? and ? and user_id = ?", start_date.to_date, end_date.to_date, user_id])
  end

  def DailyWorking.get_all_working_days(user_id, start_date, end_date)
    find(:all, :conditions => ["deleted = 0 and working_date between ? and ? and user_id = ?", start_date.to_date, end_date.to_date, user_id])
  end

  def working_date_color
    " background-color: lightgrey;" if holiday? || self.entry_date > self.working_date 
  end

  def holiday?
    self.holiday_flg == 1
  end

  def in_time_format
    calHourMinuteFormat self.in_time.to_i if self.in_time
  end

  def out_time_format
    calHourMinuteFormat self.out_time.to_i if self.out_time
  end

  def rest_hour_format
    calHourMinuteFormat self.rest_hour.to_i if self.rest_hour
  end

  def hour_total_format
    calHourMinuteFormat self.hour_total.to_i if self.hour_total
  end

  def calc_working_hour(target_employee)
    return nil unless (self.out_time && self.in_time && self.rest_hour)
    self.hour_total = self.out_time - self.in_time - self.rest_hour
    # 既に休暇申請がfixされている場合、その分を足す必要がある
    if self.action_type == "fixed"
      case self.working_type
        when 'vacation_dayoff'
          self.hour_total = ((self.user.employee.regular_working_hour * 60 * 60).to_i)
        when 'only_AM_working'
          self.hour_total += ((self.user.employee.regular_working_hour * 60 * 60 / 2).to_i)
        when 'only_PM_working'
          self.hour_total += ((self.user.employee.regular_working_hour * 60 * 60 / 2).to_i)
      end
    end
    x = self.out_time - hourminstr_to_sec(target_employee.regular_over_time_taxi)
    self.over_time = (x < 0 ? 0 : x)
    self.over_time_meel_flg = (self.out_time > hourminstr_to_sec(target_employee.regular_over_time_meel) ? 1 : 0)
  end

  def clear_working_hour
    self.in_time = nil
    self.out_time = nil
    self.rest_hour = nil
    # 既に有休申請か夏期休暇がfixされている場合は稼働時間は基本時間になる
    if self.action_type == "fixed" && (self.working_type == "vacation_dayoff" || self.working_type == "summer_dayoff")
      self.hour_total = ((self.user.employee.regular_working_hour * 60 * 60).to_i)
    else
      self.hour_total = nil
    end
    self.over_time = nil
  end

  def calc_holiday_hour_date!(approver, reverse = false)
    # 解除モードの場合は、数値が逆転。もしくは0になる
    x1 = (reverse ? -1 : 1)
    x0 = (reverse ? 0 : 1)
    case self.working_type
      when 'vacation_dayoff'
        self.hour_total = ((self.user.employee.regular_working_hour * 60 * 60).to_i * x0)
        effect = (1 * x1)
Rails.logger.info("[VACATION USED TOTAL] action: calc_holiday_hour_date!, at: #{Time.now}, used_total: #{self.user.vacation.used_total}, effect: #{effect}, user: #{self.user_id}, date: #{self.working_date} type: #{self.working_type}")
        self.user.vacation.used_total += effect
#        self.user.vacation.cutoff_day_total -= (1 * x1)
      when 'only_AM_working'
        self.hour_total += ((self.user.employee.regular_working_hour * 60 * 60 / 2).to_i * x1)
        effect = (0.5 * x1)
Rails.logger.info("[VACATION USED TOTAL] action: calc_holiday_hour_date!, at: #{Time.now}, used_total: #{self.user.vacation.used_total}, effect: #{effect}, user: #{self.user_id}, date: #{self.working_date} type: #{self.working_type}")
        self.user.vacation.used_total += effect
#        self.user.vacation.cutoff_day_total -= (0.5 * x1)
      when 'only_PM_working'
        self.hour_total += ((self.user.employee.regular_working_hour * 60 * 60 / 2).to_i * x1)
        effect = (0.5 * x1)
Rails.logger.info("[VACATION USED TOTAL] action: calc_holiday_hour_date!, at: #{Time.now}, used_total: #{self.user.vacation.used_total}, effect: #{effect}, user: #{self.user_id}, date: #{self.working_date} type: #{self.working_type}")
        self.user.vacation.used_total += effect
#        self.user.vacation.cutoff_day_total -= (0.5 * x1)
      when 'compensatory_dayoff'
        self.user.vacation.compensatory_used_total += ((self.user.employee.regular_working_hour * 60 * 60).to_i * x1)
        # 代休今月までから引いていく（月承認タイミングで、マイナスだったら0にするので今はとにかく引きまくる）
        self.user.vacation.cutoff_compensatory_hour_total -= ((self.user.employee.regular_working_hour * 60 * 60).to_i * x1)
      when 'on_holiday_working'
        if self.old_working_time && !reverse
          self.monthly_working.compensatory_hour_total += ((self.hour_total - self.old_working_time) * x1)
          self.user.vacation.compensatory_hour_total += ((self.hour_total - old_working_time) * x1)
        else
          self.monthly_working.compensatory_hour_total += (self.hour_total * x1)
          self.user.vacation.compensatory_hour_total += (self.hour_total * x1)
        end
      when 'life_plan_dayoff'
        self.hour_total = ((self.user.employee.regular_working_hour * 60 * 60).to_i * x0)
        self.user.vacation.life_plan_used_total += (1 * x1)
      when 'summer_dayoff'
        self.hour_total = ((self.user.employee.regular_working_hour * 60 * 60).to_i * x0)
        self.user.vacation.summer_vacation_used_total += (1 * x1)
    end
    self.updated_user = approver
    self.save!
    self.user.vacation.updated_user = approver
    self.user.vacation.save!
    self.monthly_working.updated_user = approver
    self.monthly_working.save!
  end

  # 必要な申請の有無を確認
  def check_working_application
    self.get_holiday_application(self.working_type)
  end

  def get_holiday_application(type = nil)
    app = HolidayApplication.get_holiday_applications(self.user_id, self.working_date.to_date, self.working_date.to_date)
    app.each{|x|
      return x unless type
      return x if type == x.working_type
    }
    return nil
  end

  def get_other_application(type)
    app = OtherApplication.get_other_applications(self.user_id, self.working_date, self.working_date)
    app.each{|x| return x if type == x.working_option_type}
    return nil
  end

  def get_other_applications
    OtherApplication.get_other_applications(self.user_id, self.working_date, self.working_date)
  end

  def get_business_trip_application
    app = BusinessTripApplication.get_business_trip_applications(self.user_id, self.working_date, self.working_date)
    app.each{|x| return x}
    return nil
  end

  def DailyWorking.regular_working_type
    ['all_day_working','only_AM_working','only_PM_working','on_holiday_working']
  end

  # 出勤系の区分か判定(全日、AMPM、休出)
  def regular_working?
    DailyWorking.regular_working_type.include?(self.working_type)
  end

  # 残業可能な区分かどうか
  def can_over_time?
    ['all_day_working','only_PM_working'].include?(self.working_type)
  end

  # 遅刻可能な区分かどうか
  def can_come_lately?
    ['all_day_working','only_AM_working','only_PM_working'].include?(self.working_type)
  end

  # 時間合計の計算が必要な区分かどうか
  def need_calc_total_hour?
    regular_working?
  end

  # 人事担当者のみが選択できる勤怠区分
  def can_change_only_personnel_department?
    ['suspension1_dayoff','suspension2_dayoff','occasion_dayoff','life_plan_dayoff'].include?(self.working_type)
  end

  # 申請が必要な勤怠区分
  def need_application?
    !['suspension1_dayoff','suspension2_dayoff','all_day_working','occasion_dayoff','life_plan_dayoff'].include?(self.working_type)
  end

  def DailyWorking.count_day_total_types
    ['all_day_working','only_AM_working','only_PM_working','on_holiday_working','life_plan_dayoff','vacation_dayoff','summer_dayoff']
  end

  def DailyWorking.count_hour_total_types
    ['all_day_working','only_AM_working','only_PM_working','on_holiday_working','life_plan_dayoff','vacation_dayoff','summer_dayoff','occasion_dayoff']
  end

  def occasion_dayoff?
    'occasion_dayoff' == self.working_type
  end

  # 労働日数としてカウントするか?
  def count_day_total?
    DailyWorking.count_day_total_types.include?(self.working_type)
  end

  # 労働時間としてカウントするか?
  def count_hour_total?
    DailyWorking.count_hour_total_types.include?(self.working_type)
  end

  # 現在のDaily workingの状態を判断して、フラグの状態を変更する
  # 保存時にこれらのフラグを立てるが、実際に有効となるのはaction_typeが'fixed'の時
  def calc_flags(target_employee)
    self.come_lately_flg = calc_come_lately?(target_employee) ? 1 : 0
    self.leave_early_flg = calc_leave_early?(target_employee) ? 1 : 0
    self.over_time_taxi_flg = calc_over_time_taxi?(target_employee) ? 1 : 0
    self.over_time_meel_flg = calc_over_time_meel?(target_employee) ? 1 : 0
  end

  # 最大退勤時間を越えているか?
  def over_time?(target_employee)
    return false unless self.out_time
    self.out_time > hourminstr_to_sec(target_employee.max_out_time)
  end

  # 遅刻かどうか判定
  def come_lately?
    self.come_lately_flg == 1 and fixed?
  end

  # 早退かどうか判定
  def leave_early?
    self.leave_early_flg == 1 and fixed?
  end

  # TAXI可の残業かどうか判定
  def over_time_taxi?
    self.over_time_taxi_flg == 1 and fixed?
  end

  # 残業食事代可の残業かどうか判定
  def over_time_meel?
    self.over_time_meel_flg == 1 and fixed?
  end

  # 遅刻かどうか計算
  def calc_come_lately?(target_employee)
    return false unless self.in_time
    defact = hourminstr_to_sec(target_employee.regular_in_time_defact)
    pm = hourminstr_to_sec(target_employee.regular_in_time_pm)
    # TODO : furukawa : ベタ書き？
    ele_time = hourminstr_to_sec("11:00")
    atype = self.working_type
    #(self.delayed_cancel_flg == 0) and ((atype == 'all_day_working' and self.in_time > defact) or (atype == 'only_AM_working' and self.in_time > defact) or (atype == 'only_PM_working' and self.in_time > pm))
    ((atype == 'all_day_working' and self.in_time > defact) or (atype == 'only_AM_working' and self.in_time > defact) or (atype == 'only_PM_working' and self.in_time > pm))
  end
  
  def calc_come_lately_over_ele_time?
    # TODO : furukawa : ベタ書き？
    ele_time = hourminstr_to_sec("11:00")
    atype = self.working_type
    ((atype == 'all_day_working' and self.in_time > ele_time) or (atype == 'only_AM_working' and self.in_time > ele_time))
  end

  # 早退かどうか計算
  def calc_leave_early?(target_employee)
    return false unless self.out_time
    early_am = hourminstr_to_sec(target_employee.regular_out_time_early_am)
    early_full = hourminstr_to_sec(target_employee.regular_out_time_early_full)
    # TODO : furukawa : ベタ書き？
    ele_time = hourminstr_to_sec("15:00")
    atype = self.working_type
    (atype == 'all_day_working' and self.out_time < early_full) or (atype == 'only_AM_working' and self.out_time < early_am) or (atype == 'only_PM_working' and self.out_time < early_full)
  end

  def calc_come_early_over_ele_time?
    # TODO : furukawa : ベタ書き？
    ele_time = hourminstr_to_sec("15:00")
    atype = self.working_type
    ((atype == 'all_day_working' and self.out_time < ele_time) or (atype == 'only_AM_working' and self.out_time < ele_time))
  end

  # TAXI可の残業かどうか計算
  def calc_over_time_taxi?(target_employee)
    return false unless self.out_time
    taxi = hourminstr_to_sec(target_employee.regular_over_time_taxi)
    (self.can_over_time? and self.out_time > taxi)
  end

  # 残業食事代可の残業かどうか計算
  def calc_over_time_meel?(target_employee)
    return false unless self.out_time
    meel = hourminstr_to_sec(target_employee.regular_over_time_meel)
    (self.can_over_time? and self.out_time > meel)
  end

  # 遅延証明済みか判定
  def delayed_canceled?
    delayed_cancel_flg == 1
  end

  def convert10minutes
    if regular_working?
      self.in_time = convert10MinutesUnitUp(self.in_time) if self.in_time
      self.out_time = convert10MinutesUnitDown(self.out_time) if self.out_time
      self.rest_hour = convert10MinutesUnitUp(self.rest_hour) if self.rest_hour
    end
  end

  def init_default_value(target_employee, holiday_application = nil)
    if holiday_application
      self.working_type = holiday_application.working_type
    else
      self.working_type = (self.holiday? ? 'on_holiday_working' : 'all_day_working')
    end

    self.in_time   = case self.working_type
                     when 'all_day_working', 'on_holiday_working', 'only_AM_working'
                       hourminstr_to_sec(target_employee.regular_in_time)
                     when 'only_PM_working'
                       hourminstr_to_sec(target_employee.regular_in_time_pm)
                     end
    self.out_time  = case self.working_type
                     when 'all_day_working', 'on_holiday_working', 'only_PM_working'
                       hourminstr_to_sec(target_employee.regular_out_time)
                     when 'only_AM_working'
                       hourminstr_to_sec(target_employee.regular_out_time_early_am)
                     end
    self.rest_hour = case self.working_type
                     when 'all_day_working', 'on_holiday_working'
                       hourminstr_to_sec(target_employee.regular_rest_hour)
                     when 'only_AM_working', 'only_PM_working'
                       hourminstr_to_sec(target_employee.regular_rest_hour_half)
                     end

    self.application_date = Time.now
  end

  def set_time_str(param)
    self.in_time = hourminstr_to_sec(param.delete(:in_time)) if !param[:in_time].blank?
    self.out_time = hourminstr_to_sec(param.delete(:out_time)) if !param[:out_time].blank?
    self.rest_hour = hourminstr_to_sec(param.delete(:rest_hour)) if !param[:rest_hour].blank?
  end

  # 対象日に対する申請がすべてfixedになっているか確認
  # working_typeに対する申請が最大1つ
  # working_option_typeに対する申請が複数件存在する可能性がある
  def all_application_fixed?
    holiday_application_fixed? && other_applications_fixed? && business_trip_application_fixed?
  end

  def holiday_application_fixed?
    happ = self.get_holiday_application
    (!happ or happ.fixed?)
  end

  def other_applications_fixed?
    oapps = self.get_other_applications
    return true if oapps.empty?
    oapps.each{|oapp|
      return false unless oapp.fixed?
    }
    return true
  end

  def business_trip_application_fixed?
    bapp = self.get_business_trip_application
    (!bapp or bapp.fixed?)
  end

  # 確定ステータスにする
  def change_fixed!(approver)
    # 全日出勤以外で、すでに確定済みをさらに確定しようとした場合
    raise "daily_working.action_type status error!!!" if self.action_type == 'fixed' && self.working_type != 'all_day_working'
    # 他の申請が承認済みでなければ、作業日はfixedにならない
    return false unless all_application_fixed?
    # 条件が良ければfixedにして保存
    self.action_type = 'fixed'
    calc_holiday_hour_date!(approver)
  end
  # 確定ステータスをはがす
  def revert_fixed!(approver)
    # すでに解除済みをさらに解除しようとした場合
    raise "daily_working.action_type status error!!!" if self.action_type == 'updated'

    # 条件が良ければupdatedにして保存
    self.action_type = 'updated'
    calc_holiday_hour_date!(approver, true)
    self.updated_user = approver
    self.save!
  end

  def clear
    self.working_type = nil
    self.application_date = nil
#    self.working_date
    self.in_time = nil
    self.out_time = nil
    self.rest_hour = nil
    self.hour_total = nil
    self.over_time = nil
    self.come_lately_flg = 0
    self.leave_early_flg = 0
    self.direct_in_flg = 0
    self.direct_out_flg = 0
    self.over_time_taxi_flg = 0
    self.over_time_meel_flg = 0
    self.location = nil
    self.summary = nil
    self.action_type = 'blank'
    x = ([0, 6].include?(self.base_date.day_of_week) or self.base_date.holiday_flg == 1) ? 1 : 0
    if x == 1 and self.holiday_flg == 0
      self.holiday_flg = x
      self.monthly_working.labor_day_total -= 1
      self.monthly_working.save!
    elsif x == 0 and self.holiday_flg == 1
      self.holiday_flg = x
      self.monthly_working.labor_day_total += 1
      self.monthly_working.save!
    end
    self.delayed_cancel_flg = 0
    self.delayed_cancel_user_id = nil
    self.taxi_flg = 0
    self.business_trip_flg = 0
    self.memo = nil
  end

  def clear_daily_working!(login_user, exclude_id_list = [])
    exclude_id_list << self.id
    if happ = self.get_holiday_application
      happ.get_daily_workings.each do |working|
        next if exclude_id_list.include?(working.id)
        working.clear_daily_working!(login_user, exclude_id_list)
      end
#      happ.base_application.cancel!(login_user)
      b = BaseApplication.find(happ.base_application_id)
      b.cancel!(login_user)
    end
    oapps = self.get_other_applications
    oapps.each do |oapp|
      b = BaseApplication.find(oapp.base_application_id)
      b.cancel!(login_user)
    end

    if bapp = self.get_business_trip_application
      bapp.get_all_working_days.each do |working|
        next if exclude_id_list.include?(working.id)
        working.clear_daily_working!(login_user, exclude_id_list)
      end
      b = BaseApplication.find(bapp.base_application_id)
      b.cancel!(login_user)
    end
    if self.action_type == 'fixed'
      self.calc_holiday_hour_date!(login_user, true)
    end
    self.clear
    self.updated_user = login_user
    self.save!
  end

  def monthly_working_applicated?
    monthly_working.base_application #&& monthly_working.base_application.approval_status_type == 'fixed'
  end
  
  def in_out_time?
    self.rest_hour = 0 if self.rest_hour.blank?
    return false if self.out_time <= self.in_time
    self.out_time > self.in_time
  end
  
  def enable_in_out_time?
    ["all_day_working","only_PM_working","only_AM_working","on_holiday_working"].include?(self.working_type)
  end
  

  def entry_date
    self.user.employee.entry_date
  end

  def DailyWorking.count_comp(user, next_start_date)
    comp_total = 0
    daikyus = DailyWorking.find(:all, :conditions => ["user_id = ? and daily_workings.working_type = 'on_holiday_working' and working_date >= ?", user.id, next_start_date])
    daikyus.each do |daikyu|
puts"-----------------------"
puts">>#{daikyu.id}"
      holiapp = HolidayApplication.find(:first, :include => :base_application, :conditions => ["holiday_applications.user_id = ? and holiday_applications.start_date = ? and base_applications.approval_status_type = 'fixed'", user.id, daikyu.working_date])
      if holiapp
        comp_total += daikyu.hour_total
puts"-----------------------------"
puts">>>>>#{daikyu.id}"
puts">>>>>>>comp_total : #{comp_total}"
      end
    end
    comp_total
  end
end
