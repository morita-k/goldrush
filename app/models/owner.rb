# -*- encoding: utf-8 -*-
class Owner < ActiveRecord::Base
  has_many :users
  validates_uniqueness_of :owner_key, :scope => [:deleted, :deleted_at]
  before_save :set_default

  def set_default
    self.init_password_salt ||= 'salt'
    self.user_max_count = 50 if self.user_max_count.nil? || self.user_max_count == 0
    self.available_user_count = 50 if self.available_user_count.nil? || self.available_user_count == 0
    self.additional_option ||= ''
  end

  def enable_photo?
    self.additional_option.present? && self.additional_option.split(',').include?('photo')
  end

  def enable_jiet?
    self.additional_option.present? && self.additional_option.split(',').include?('jiet')
  end

  def enable_daily_report?
    self.additional_option.present? && self.additional_option.split(',').include?('daily_report')
  end

  # "契約","案件照会","人材所属" 3機能を1つとした"contract"なので注意
  def enable_contract?
    self.additional_option.present? && self.additional_option.split(',').include?('contract')
  end

  def enable_outflow_mail?
    self.additional_option.present? && self.additional_option.split(',').include?('outflow_mail')
  end
end
