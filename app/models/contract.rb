# -*- encoding: utf-8 -*-
class Contract < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize

  has_many :interviews, :conditions => ["interviews.deleted = 0"]
  belongs_to :upper_contract_term, :class_name => 'ContractTerm'
  belongs_to :down_contract_term, :class_name => 'ContractTerm'
  belongs_to :contract_pic, :class_name => 'User'
  belongs_to :approach

  def make_contract_proc(str)
    return ->(a){
      if ["contracted"].include?(attributes["#{str}_contract_status_type"])
        change_status(:conclusion, :contract_status_type)
      end
      return a.to
    }
  end

  def after_initialize
    init_actions([
      [:open, :contract, :conclusion],
      [:contract, :finished, :finish_contract, ->(a){
        approach.change_status(:finish)
        return a.to
      }],
    ], :contract_status_type)
    init_actions([
      [:waiting_order, :proc_acceptance, :accept_order],
      [:proc_acceptance, :contracted, :send_accept, make_contract_proc(:upper)],
      [:contracted, :finished, :finish_term],
      [:contracted, :abort, :abort_term],
      [:contracted, :confirming, :make_next],
      [:confirming, :waiting_order, :accept_reorder],
      [:confirming, :closed, :accept_close],
    ], :upper_contract_status_type)
    init_actions([
      [:waiting_offer, :proc_order, :send_offer],
      [:proc_order, :waiting_acceptance, :send_order],
      [:waiting_acceptance, :contracted, :accept_accept, make_contract_proc(:upper)],
      [:contracted, :finished, :finish_term],
      [:contracted, :abort, :abort_term],
      [:contracted, :confirming, :make_next],
      [:confirming, :proc_order, :send_reorder],
      [:confirming, :closed, :send_close],
    ], :down_contract_status_type)
  end

  def upper_contract_status_type_next_actions
    next_actions(upper_contract_status_type, :upper_contract_status_type)
  end

  def upper_contract_status_type_change(action)
    change_status(action, :upper_contract_status_type)
  end

  def down_contract_status_type_next_actions
    next_actions(down_contract_status_type, :down_contract_status_type)
  end

  def down_contract_status_type_change(action)
    change_status(action, :down_contract_status_type)
  end

  def contract_employee_name
    contract_pic && contract_pic.employee.employee_name
  end
end
