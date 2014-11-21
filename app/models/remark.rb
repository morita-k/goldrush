# encoding: UTF-8

class Remark < ActiveRecord::Base
  attr_accessible :id, :owner_id, :rating, :remark_content, :remark_key, :remark_target_id, :lock_version

  validates_presence_of :remark_content

  def get_created_user
    User.find(:first, :conditions => ["owner_id = ? and deleted = 0 and login = ?", owner_id, created_user])
  end

  def self.get_all(key, target_id)
    Remark.where("deleted = 0 and remark_key = ? and remark_target_id = ?", key, target_id)
  rescue => e
    logger.warn e
    logger.warn "Remarkの取得エラー（key:#{key} target_id:#{target_id}）"
    []
  end
end
