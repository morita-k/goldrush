# -*- encoding: utf-8 -*-
class BpPic < ActiveRecord::Base

  belongs_to :business_partner
  has_one :delivery_mail_target
  has_many :businesses
  has_many :bp_members
   
  validates_presence_of :bp_pic_name, :bp_pic_name_kana, :email1
  validates_uniqueness_of :bp_pic_name, :case_sensitive => false, :scope => :business_partner_id
  validates_uniqueness_of :bp_pic_name_kana, :case_sensitive => false, :scope => :business_partner_id
  validates_uniqueness_of :email1, :case_sensitive => false
  
end
