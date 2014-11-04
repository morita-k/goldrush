# -*- encoding: utf-8 -*-
class Owner < ActiveRecord::Base
  require 'digest/md5'

  has_many :users
  validates_presence_of :sender_email, :if => :advanced_smtp_mode_on?
  validates_uniqueness_of :owner_key, :scope => [:deleted, :deleted_at]
  before_save :set_default

  def set_default
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

  def advanced_smtp_mode_on?
    self.additional_option.present? && self.additional_option.split(',').include?('advanced_smtp_mode')
  end

  def change_smtp_mode(advanced_smtp_mode)
    if advanced_smtp_mode.present? && advanced_smtp_mode.to_s == '1'
      self.additional_option = self.additional_option.split(',').push('advanced_smtp_mode').uniq.join(',')
    else
      self.additional_option = self.additional_option.split(',').reject{|o| o == 'advanced_smtp_mode'}.join(',')
    end
  end

  def Owner.calculate_owner_key(initial_user_id, initial_user_email)
    owner_key = ''
    # owner_keyは4桁固定、ダブらないようにする
    begin
      owner_key = Digest::MD5.hexdigest("#{initial_user_id}_#{initial_user_email}_#{DateTime.now.to_s}").to_s[0..3]
    end while self.where(:deleted => 0, :owner_key => owner_key).exists?
    owner_key
  end

  def Owner.delete_owner(id, deleted_user)
    now = Time.now

    # オーナー配下のユーザー削除
    User
        .where(:owner_id => id, :deleted => 0)
        .update_all(["deleted = 9, deleted_at = :now, updated_user = :deleted_user, lock_version = lock_version + 1, updated_at = :now", {:now => now, :deleted_user => deleted_user}])

    # オーナー削除
    Owner.find(id).update_attributes!(:deleted => 9, :deleted_at => now, :updated_user => deleted_user)
  end
end
