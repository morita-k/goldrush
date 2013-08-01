# -*- encoding: utf-8 -*-
class BizOffer < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize
  
  validates_presence_of :business_id, :bp_pic_id, :biz_offer_status_type, :biz_offered_at
  
  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  belongs_to :business
  belongs_to :business_partner
  belongs_to :bp_pic
  belongs_to :contact_pic, :class_name => 'User'
  belongs_to :sales_pic, :class_name => 'User'
  belongs_to :import_mail

  before_save :derive_business_partner

  def derive_business_partner
    if bp_pic
      if business_partner_id.blank? || business_partner_id != bp_pic.business_partner_id
        self.business_partner_id = bp_pic.business_partner_id
      end
    end
  end

  def after_initialize 
    init_actions([
      [:open, :approached, :approach],
      [:open, :other_failure, :choice_other],
      [:open, :lost_failure, :lost],
      [:open, :natural_lost, :pass_away],
      [:approached, :open, :reject_approach],
      [:approached, :working, :get_job],
      [:approached, :other_failure, :choice_other],
      [:approached, :lost_failure, :lost],
      [:approached, :natural_lost, :pass_away],
      [:working, :finished, :finish, ->(a){
        business.change_status(:finish)
        return a.to
      }],
      [:other_failure, :open, :revert],
      [:lost_failure, :open, :revert],
      [:natural_lost, :open, :revert],
    ])
  end

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
  
  # 内部での値の変換処理
  def convert!
    # [単価TEXT]を[単価MAX]に変換
    v = StringUtil.detect_payments_value(self.payment_text).map{ |i| i.to_f }.max
    v *= 10000 if v
    self.payment_max = v
  end
  
  def payment_max_view=(x)
    self.payment_max = x.to_f * 10000
  end
  
  def payment_max_view
    payment_max.to_f / 10000.0
  end
end
