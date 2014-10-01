# -*- encoding: utf-8 -*-
require 'date_time_util'
class Employee < ActiveRecord::Base
  include AutoTypeName
  include DateTimeUtil

  belongs_to :user
  belongs_to :department
  
  validates_presence_of     :insurance_code, :employee_code, :employee_name, :employee_kana_name, :employee_short_name, :birthday_date, :entry_date
  validates_presence_of     :regular_in_time, 
                            :regular_in_time_defact, 
                            :regular_in_time_pm, 
                            :regular_out_time, 
                            :regular_out_time_early_am, 
                            :regular_out_time_early_full, 
                            :max_out_time, 
                            :regular_rest_hour, 
                            :regular_rest_hour_half, 
                            :regular_over_time_meel, 
                            :regular_over_time_taxi
  validates_numericality_of :insurance_code, :employee_code, :on => :create
  
#  validates_length_of :insurance_code, :is => 3
  validates_length_of :employee_name, :maximum=>100
  validates_length_of :employee_kana_name, :maximum=>100
  
  validates_length_of :employee_short_name, :maximum=>100, :allow_blank => true
  validates_length_of :position, :maximum=>100, :allow_blank => true
  validates_length_of :resignation_reason, :maximum=>255, :allow_blank => true
  validates_length_of :zip1, :maximum=>40, :allow_blank => true
  validates_length_of :address1_1, :maximum=>255, :allow_blank => true
  validates_length_of :address1_2, :maximum=>255, :allow_blank => true
  validates_length_of :address1_3, :maximum=>255, :allow_blank => true
  validates_length_of :address1_4, :maximum=>255, :allow_blank => true
  validates_length_of :tel1, :maximum=>40, :allow_blank => true
  validates_length_of :fax, :maximum=>40, :allow_blank => true
  validates_length_of :email, :maximum=>40, :allow_blank => true
  validates_length_of :mobile, :maximum=>40, :allow_blank => true
  validates_length_of :mobile_email, :maximum=>40, :allow_blank => true
  validates_length_of :zip3, :maximum=>40, :allow_blank => true
  validates_length_of :address3_1, :maximum=>255, :allow_blank => true
  validates_length_of :address3_2, :maximum=>255, :allow_blank => true
  validates_length_of :address3_3, :maximum=>255, :allow_blank => true
  validates_length_of :address3_4, :maximum=>255, :allow_blank => true
  validates_length_of :tel3, :maximum=>40, :allow_blank => true
  validates_length_of :name2, :maximum=>100, :allow_blank => true
  validates_length_of :zip2, :maximum=>40, :allow_blank => true
  validates_length_of :address2_1, :maximum=>255, :allow_blank => true
  validates_length_of :address2_2, :maximum=>255, :allow_blank => true
  validates_length_of :address2_3, :maximum=>255, :allow_blank => true
  validates_length_of :address2_4, :maximum=>255, :allow_blank => true
  validates_length_of :tel2, :maximum=>40, :allow_blank => true
  validates_length_of :bank_name, :maximum=>100, :allow_blank => true
  validates_length_of :branch_name, :maximum=>100, :allow_blank => true
  validates_length_of :account_number, :maximum=>40, :allow_blank => true
  validates_length_of :account_name, :maximum=>255, :allow_blank => true
  
  def address1
    address1_1.to_s +  address1_2.to_s +  address1_3.to_s +  address1_4.to_s
  end

  def address2
    address2_1.to_s +  address2_2.to_s +  address2_3.to_s +  address2_4.to_s
  end

  def address3
    address3_1.to_s +  address3_2.to_s +  address3_3.to_s +  address3_4.to_s
  end

  def getFullName
    return "社員名： " + self.insurance_code.to_s + " " + self.employee_name
  end
  
  def calAge
    if self.birthday_date == nil
      return 0
    end
    d1 = self.birthday_date.to_date
    d2 = Date.today
    age = (d2.strftime("%Y%m%d").to_i - d1.strftime("%Y%m%d").to_i)/10000
    return age
  end
  
  def self.calAboutBirthdayFromAge(age)
    d2 = Date.today
    d1 = d2 - age.to_i.year
    return d1
  end
  
  def self.calEntryFromWorkingYear(yearCount)
    d2 = Date.today
    d1 = d2 - yearCount.to_i.year
    return d1
  end
  
  def calWorkingYearMonth
    if self.entry_date == nil
      return 0
    end

    d1 = self.entry_date.to_date
    if self.resignation_date != nil
      d2 = self.resignation_date
    else
      d2 = Date.today
    end

    m1 = (d1.year * 12) + d1.month
    m2 = (d2.year * 12) + d2.month

    m4 = ((self.leave_day * 1.0) / 30).ceil
    m3 = m2 - m1 - m4.to_i
    if m3 >= 12 
      y = m3 / 12
      m = m3 % 12
      return "#{y}年#{m}ヶ月"
    else
      return "#{m3}ヶ月"
    end
    return m3
  end
  
  def calWorkingMonthes(base_date = Date.today)
    enday = self.entry_date.to_date
    years = base_date.year - enday.year
    monthes = base_date.month - enday.month
    return years * 12 + monthes
  end
 
  def init_default_working_times
    self.regular_in_time             = SysConfig.get_regular_in_time_regular.value1
    self.regular_in_time_defact      = SysConfig.get_regular_in_time_defact.value1
    self.regular_in_time_pm          = SysConfig.get_regular_in_time_pm.value1
    self.regular_out_time            = SysConfig.get_regular_out_time_regular.value1
    self.regular_out_time_early_am   = SysConfig.get_regular_out_time_early_am.value1
    self.regular_out_time_early_full = SysConfig.get_regular_out_time_early_full.value1
    self.max_out_time                = SysConfig.get_max_out_time.value1
    self.regular_rest_hour           = SysConfig.get_rest_hour_regular.value1
    self.regular_rest_hour_half      = SysConfig.get_rest_hour_half.value1
    self.regular_over_time_meel      = SysConfig.get_regular_over_time_meel.value1
    self.regular_over_time_taxi      = SysConfig.get_regular_over_time_taxi.value1
  end

  def calc_regular_working_hour
    calc_sec = hourminstr_to_sec(self.regular_out_time) - hourminstr_to_sec(self.regular_in_time) - hourminstr_to_sec(self.regular_rest_hour)
    hour = (calc_sec / 60 / 60).to_s
    min = ((calc_sec / 60 % 60) / 6).to_s
    # TODO : furukawa : 30分間隔じゃない場合の対処
    min.to_i > 0 ? (hour + '.' + min).to_f : hour.to_i
  end

  def set_regular_working_hour
    self.regular_working_hour = calc_regular_working_hour
  end
end
