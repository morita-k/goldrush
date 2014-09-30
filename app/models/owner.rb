# -*- encoding: utf-8 -*-
class Owner < ActiveRecord::Base
  has_many :users
  validates_uniqueness_of :owner_key, :scope => [:deleted, :deleted_at]
  before_save :set_default

  def set_default
    self.init_password_salt ||= 'salt'
    self.user_max_count ||= 50
    self.available_user_count ||= 50
  end
end
