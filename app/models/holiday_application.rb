# -*- encoding: utf-8 -*-
require 'application_util'
class HolidayApplication < ActiveRecord::Base
  include AutoTypeName
  include DateTimeUtil
  include ApplicationUtil

  belongs_to :user
  belongs_to :base_application

  attr_accessor :app_count
  attr_accessor :hour_count
  
  validates_length_of :reason, :maximum=>4000, :allow_blank => true
  validates_length_of :content, :maximum=>4000, :allow_blank => true

  def HolidayApplication.get_holiday_applications(user_id, start_date, end_date)
    HolidayApplication.find(:all, :include =>[:base_application], :conditions => [
      "holiday_applications.deleted = 0 and holiday_applications.user_id = :user_id and ((start_date >= :start_date and start_date <= :end_date) or (end_date >= :start_date and end_date <= :end_date) or (:start_date >= start_date and :start_date <= end_date) or (:end_date >= start_date and :end_date <= end_date)) and base_applications.approval_status_type != 'canceled'",
      {:user_id => user_id, :start_date => start_date.to_date, :end_date => end_date.to_date}], :order => "holiday_applications.application_date")
  end

  def HolidayApplication.get_unfixed_holiday_applications(user_id, working_types)
    HolidayApplication.find(:all, :include =>[:base_application], :conditions => [
      "holiday_applications.deleted = 0 and holiday_applications.user_id = :user_id and base_applications.approval_status_type in ('entry','retry') and working_type in (:working_types)", {:user_id => user_id, :working_types => working_types}], :order => "holiday_applications.application_date")
  end

  def HolidayApplication.get_unfixed_vacation_dayoff_count(user_id)
    app_count = 0
    HolidayApplication.get_unfixed_holiday_applications(user_id, ['only_PM_working','only_AM_working','vacation_dayoff']).each do |app|
      app_count += app.day_total
    end
    return app_count
  end

  def HolidayApplication.get_unfixed_compensatory_dayoff_count(user_id)
    hour_count = 0
    HolidayApplication.get_unfixed_holiday_applications(user_id, ['compensatory_dayoff']).each do |app|
      hour_count += app.hour_total
    end
    return hour_count
  end

  def HolidayApplication.get_unfixed_summer_dayoff_count(user_id)
    app_count = 0
    HolidayApplication.get_unfixed_holiday_applications(user_id, ['summer_dayoff']).each do |app|
      app_count += app.day_total
    end
    return app_count
  end

  def enough_vacation_count?
    vacation = self.user.vacation
    case working_type
    when 'only_PM_working','only_AM_working','vacation_dayoff'
      self.app_count = HolidayApplication.get_unfixed_vacation_dayoff_count(user_id)
      vacation.remain_total >= self.day_total + self.app_count
    when 'compensatory_dayoff'
      self.hour_count = HolidayApplication.get_unfixed_compensatory_dayoff_count(user_id)
      # 前月が承認済かどうかをチェック
      last_date = self.start_date.to_date - 1.month
      last_month = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and start_date <= ?", self.user, last_date], :order => "start_date desc")
#puts"******* target_monthly_working : #{last_month.id}"
      if last_month && last_month.fixed?
        cutoff_compensatory = 0
      else
        cutoff_compensatory = (vacation.cutoff_compensatory_hour_total < 0 ? 0 : vacation.cutoff_compensatory_hour_total)
      end
#puts"******* hour_count : #{self.hour_count}"
#puts"******* hour_total : #{self.hour_total}"
#puts"******* compensatory_remain_total : #{vacation.compensatory_remain_total}"
#puts"******* cutoff_compensatory_hour_total : #{vacation.cutoff_compensatory_hour_total}"
#puts"******* cutoff_compensatory : #{cutoff_compensatory}"
      (vacation.compensatory_remain_total - cutoff_compensatory) >= self.hour_total + self.hour_count
    when 'summer_dayoff'
      self.app_count = HolidayApplication.get_unfixed_summer_dayoff_count(user_id)
      vacation.summer_vacation_remain_total(self.start_date) >= self.day_total + self.app_count
    else
      true
    end
  end

  def start_time_format
    calHourMinuteFormat(self.start_time) if self.start_time
  end

  def end_time_format
    calHourMinuteFormat(self.end_time) if self.end_time
  end

  def HolidayApplication.one_day_application
    ['compensatory_dayoff','only_AM_working','only_PM_working', 'on_holiday_working']
  end

  # 一日限定のworking_typeか？
  def one_day_application?
    HolidayApplication.one_day_application.include?(self.working_type)
  end

  def set_time_str(param)
    self.start_time = hourminstr_to_sec(param.delete(:start_time)) unless param[:start_time].blank?
    self.end_time = hourminstr_to_sec(param.delete(:end_time)) unless param[:end_time].blank?
  end

  def HolidayApplication.can_change_only_personnel_department
    ['suspension1_dayoff','suspension2_dayoff','occasion_dayoff','life_plan_dayoff']
  end

  def HolidayApplication.hide_select_types
    ['suspension1_dayoff','suspension2_dayoff','occasion_dayoff','life_plan_dayoff','on_holiday_working','all_day_working']
  end

  # 人事担当者のみが選択できる勤怠区分
  def can_change_only_personnel_department?
    HolidayApplication.can_change_only_personnel_department.include?(self.working_type)
  end

  def get_overlaid_holiday_applications
    HolidayApplication.find(:all, :include =>[:base_application], :conditions => ["holiday_applications.deleted = 0 and ((start_date >= :start_date and start_date <= :end_date) or (end_date >= :start_date and end_date <= :end_date)) and holiday_applications.user_id = :user_id and base_applications.approval_status_type != 'canceled'",{:start_date => self.start_date, :end_date => self.end_date, :user_id => self.user_id}])
  end

  def get_daily_workings
    daily_workings = DailyWorking.find(:all, :conditions => ["deleted = 0 and user_id = ? and working_date between ? and ?", self.user_id, self.start_date.to_date, self.end_date.to_date])
  end

  def monthly_working_applicated?
    mw = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and start_date <= ? and end_date >= ? and base_application_id is not null", self.user_id, self.start_date.to_date, self.start_date.to_date])
    mw && mw.base_application #.approval_status_type == 'fixed'
  end

end
