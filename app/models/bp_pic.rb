# -*- encoding: utf-8 -*-
class BpPic < ActiveRecord::Base
  belongs_to :business_partner
  has_one :delivery_mail_target
  has_many :businesses
  has_many :bp_members
   
  validates_presence_of :bp_pic_name, :bp_pic_short_name, :bp_pic_name_kana, :email1
#  validates_uniqueness_of :bp_pic_name, :case_sensitive => false, :scope => :business_partner_id
#  validates_uniqueness_of :bp_pic_name_kana, :case_sensitive => false, :scope => :business_partner_id
  validates_uniqueness_of :email1, :case_sensitive => false
  
  NONDELIVERY_LIMIT=3
  BOUNCE_MAIL_REASON_ERROR = [:hostunknown, :userunknown]
  BOUNCE_MAIL_REASON_WARN = [:hasmoved, :rejected, :filtered, :mailboxfull, :exceedlimit, :systemfull, :notaccept, :suspend, :mailererror, :systemerror, :mesgtoobig, :securityerr, :contenterr, :expired, :onhold]
  
  def sales_pic_name(sales_pic_id)
    short_name = Employee.find_by_id(sales_pic_id)
    short_name.nil? ? "" : short_name.employee_short_name
  end
  
  def contact_mail_status(mail_flg)
    mail_flg == 1 ? "送信済み" : "未送信"
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
  
end
