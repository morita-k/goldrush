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
  
  def sales_pic_name(sales_pic_id)
	  	short_name = Employee.find_by_id(sales_pic_id)
	  	short_name.nil? ? "" : short_name.employee_short_name
  end
  
  def contact_mail_status(mail_flg)
	  	mail_flg == 1 ? "送信済み" : "未送信"
  end
  
end
