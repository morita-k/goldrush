# -*- encoding: utf-8 -*-
class Interview < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize

  belongs_to :interview_bp, :class_name => 'BusinessPartner'
  belongs_to :interview_bp_pic, :class_name => 'BpPic'
  belongs_to :approach
  belongs_to :interview_pic, :class_name => 'User'
  
  before_save :derive_business_partner

  def derive_business_partner
    if interview_bp_pic
      if interview_bp_id.blank? || interview_bp_id != bp_pic.business_partner_id
        self.interview_bp_id = interview_bp_pic.business_partner_id
      end
    end
  end

  def after_initialize 
    init_actions([
      [:interview_waiting, :result_waiting, :interview],
      [:interview_waiting, :other_failure, :choice_other],
      [:interview_waiting, :lost_failure, :lost],
      [:interview_waiting, :natural_lost, :pass_away],
      [:interview_waiting, :other_success, :other_success],
      [:result_waiting, :adjusting, :want],
      [:result_waiting, :finished, :get_job],
      [:result_waiting, :interview_failure, :reject_interview],
      [:result_waiting, :other_failure, :choice_other],
      [:result_waiting, :lost_failure, :lost],
      [:result_waiting, :natural_lost, :pass_away],
      [:result_waiting, :other_success, :other_success],
      [:adjusting, :result_waiting, :reapproach],
      [:adjusting, :other_failure, :choice_other],
      [:adjusting, :lost_failure, :lost],
      [:adjusting, :natural_lost, :pass_away],
      [:adjusting, :other_success, :other_success],
    ])
  end

  def interview_employee_name
   if self.interview_pic_id
     employee = Employee.find(self.interview_pic_id)
     employee ? employee.employee_name : ""
   end
  end
  
end
