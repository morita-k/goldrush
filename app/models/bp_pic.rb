# -*- encoding: utf-8 -*-
class BpPic < ActiveRecord::Base
  belongs_to :business_partner
  belongs_to :sales_pic, :class_name => 'User'
  has_one :delivery_mail_target
  has_many :businesses
  has_many :bp_members
  
  # TODO: 複数形で指定すると、取引先一覧画面のpaginateでエラーが出るため単数形で記述
  has_many :bp_pic_group_detail, :conditions => "bp_pic_group_details.deleted = 0"
  
  validates_presence_of :bp_pic_name, :bp_pic_short_name, :bp_pic_name_kana, :email1
#  validates_uniqueness_of :bp_pic_name, :case_sensitive => false, :scope => :business_partner_id
#  validates_uniqueness_of :bp_pic_name_kana, :case_sensitive => false, :scope => :business_partner_id
  validates_uniqueness_of :email1, :case_sensitive => false, :scope => [:deleted, :deleted_at]
  
  NONDELIVERY_LIMIT=3
  BOUNCE_MAIL_REASON_ERROR = [:hostunknown, :userunknown]
  BOUNCE_MAIL_REASON_WARN = [:hasmoved, :rejected, :filtered, :mailboxfull, :exceedlimit, :systemfull, :notaccept, :suspend, :mailererror, :systemerror, :mesgtoobig, :securityerr, :contenterr, :expired, :onhold]
  
  def business_partner_name
    business_partner && business_partner.business_partner_name
  end
  
  def usefulname
    bp_pic_name + (nondelivery? ? ' (送信停止)' : '')
  end
  
  def sales_pic_name
    sales_pic && sales_pic.employee.employee_short_name
  end
  
  def BpPic.select_content_list
    Employee.where(deleted: 0).map{|e| [e.employee_short_name, e.user_id]}
  end
  
  def contact_mail?
    contact_mail_flg == 1
  end

  def contact_mail_status
    contact_mail? ? "送信済み" : "未送信"
  end
  
  def contact_mail_short_status
    contact_mail? ? "済" : ""
  end

  def nondelivery?
    self.nondelivery_score >= NONDELIVERY_LIMIT
  end
  
  def increse_nondelivery_score(reason)
    score = self.nondelivery_score + BpPic.score_nondelivery(reason)
    self.nondelivery_score = [score, NONDELIVERY_LIMIT].min
  end
  
  def BpPic.score_nondelivery(reason)
    reason = reason.to_sym
    if BOUNCE_MAIL_REASON_WARN.include?(reason)
      return 1
    elsif BOUNCE_MAIL_REASON_ERROR.include?(reason)
      return NONDELIVERY_LIMIT
    end
    return 0
  end
  
  def to_test
    self.email1 = StringUtil.to_test_address(email1)
  end
  
  def BpPic.to_test_all!
    require 'string_util'
    BpPic.where("email1 not like ?", "test%").where(:deleted => 0).each do |b|
      b.to_test
      b.updated_user = 'to_test_all!'
      b.save!
    end
  end
  
  def into_group(group_id)
    if BpPicGroupDetail.where(bp_pic_group_id: group_id, bp_pic_id: self.id, deleted: 0).blank?
      group = BpPicGroupDetail.new(bp_pic_group_id: group_id, bp_pic_id: self.id)
      group.save!
    end
  end
  
end
