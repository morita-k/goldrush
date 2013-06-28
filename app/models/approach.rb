# -*- encoding: utf-8 -*-
class Approach < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize

  belongs_to :biz_offer
  belongs_to :bp_member
  belongs_to :approach_upper_contract_term, :class_name => 'ContractTerm'
  belongs_to :approach_down_contract_term, :class_name => 'ContractTerm'
  belongs_to :approach_pic, :class_name => 'User'
  has_many :interviews, :conditions => ["interviews.deleted = 0"]
  has_one :contract
  has_many :contracts, :conditions => ["contracts.deleted = 0"], :order => "id"
  
  validates_presence_of     :biz_offer_id, :bp_member_id

  def after_initialize 
    init_actions([
      [:approaching, :adjust, :want],
      [:approaching, :result_waiting, :success_approach],
      [:approaching, :other_failure, :choice_other],
      [:approaching, :lost_failure, :lost],
      [:approaching, :natural_lost, :pass_away],
      [:approaching, :other_success, :other_success],
      [:adjust, :approaching, :reapproach],
      [:adjust, :approach_failure, :reject_approach],
      [:adjust, :other_failure, :choice_other],
      [:adjust, :lost_failure, :lost],
      [:adjust, :natural_lost, :pass_away],
      [:adjust, :other_success, :other_success],
      [:result_waiting, :working, :get_job],
      [:result_waiting, :approach_failure, :reject_approach],
      [:result_waiting, :other_failure, :choice_other],
      [:result_waiting, :lost_failure, :lost],
      [:result_waiting, :natural_lost, :pass_away],
      [:result_waiting, :other_success, :other_success],
      [:working, :finished, :finish, ->(a){
        # 提案が完了する際に、照会と人材のステータスも変化する
        biz_offer.change_status(:finish)
        biz_offer.save!
        bp_member.human_resource.change_status(:finish)
        bp_member.human_resource.save!
        return a.to
      }],
    ])
  end

  def approach_employee_name
   if self.approach_pic_id
     employee = Employee.find(self.approach_pic_id)
     employee ? employee.employee_name : ""
   end
  end
  
  def process_interview
    self.interviews.each do |interview|
#puts ">>>>>>>>>>>>>>>>>>>>> #{interview.interview_status_type}"
      return true if interview.interview_status_type != 'finished'
    end
    return false
  end
  
  def last_interview
    Interview.find(:first, :conditions => ["deleted = 0 and approach_id = ?", self], :order => "interview_number desc")
  end
  
  def approach_status_type_active
    # 失敗してないステータスを並べ立てる(提案中、提案調整中、面談結果待ち、成約)
    self.approach_status_type == 'approaching' || self.approach_status_type == 'adjust' || self.approach_status_type == 'result_waiting' || self.approach_status_type == 'success'
  end
  
end
