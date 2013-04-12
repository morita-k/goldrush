# -*- encoding: utf-8 -*-
class BizOffer < ActiveRecord::Base
  include AutoTypeName
  
  validates_presence_of :business_id, :business_partner_id, :bp_pic_id, :biz_offer_status_type, :biz_offered_at
  
  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  belongs_to :business
  belongs_to :business_partner
  belongs_to :bp_pic
  belongs_to :contact_pic, :class_name => 'User'
  belongs_to :sales_pic, :class_name => 'User'
  belongs_to :import_mail
  
  def contact_employee_name
   if self.contact_pic_id
     employee = Employee.find(self.contact_pic_id)
     employee ? employee.employee_name : ""
   end
  end
  
  def sales_employee_name
   if self.sales_pic_id
     employee = Employee.find(self.sales_pic_id)
     employee ? employee.employee_name : ""
   end
  end
  
  def change_status_type
    
  end
  
  def payment_max_view=(x)
    self.payment_max = x.to_f * 10000
  end
  
  def payment_max_view
    payment_max.to_f / 10000.0
  end
end
