# -*- encoding: utf-8 -*-
module BusinessFlow
  class BusinessFlowAction
    attr_accessor :from, :to, :action, :event, :display_order
    def initialize(from, to, action, event, display_order)
      @from = from
      @to = to
      @action = action
      @event = event
      @display_order = display_order
    end
  end

  # action_src [[:from_status, :to_status, :action, :event]]
  # event is lambda: ->(action){return next_status}
  def init_actions(action_src, status_type = detect_default_status_type)
    @actions_map ||= {}
    i = 0
    @actions_map[status_type] = action_src.map do |x|
      i += 1
      x << nil if x.size < 4
      BusinessFlowAction.new(*(x+[i]))
    end
  end
  
  # 普通のテーブルは、ステータスが1個しかないので、"status_type"を探して、シンボル化して利用する
  def detect_default_status_type
    attributes.keys.sort.detect{|x| x.include?("status_type")}.to_sym
  end
  
  # actionを実行する。:actionのレコードにeventが設定されていた場合evnt実行
  def do_action(action, status_type = detect_default_status_type)
    if a = @actions_map[status_type].detect{|a| a.action == action}
      if a.event
        return a.event.call(a)
      else
        return a.to
      end
    end
  end

  def change_status(action, status_type = detect_default_status_type)
    next_status = do_action(action, status_type)
    attributes["#{status_type}"] = next_status.to_s
  end

  def next_actions(from_status, status_type = detect_default_status_type)
     @actions_map[status_type].reject do |action|
       action.from != from_status
     end
  end

=begin
  # ステータスとアクションの定義
  def business_status_types
    [:offered, :working, :finished, :other_failure, :lost_failure, :natural_lost]
  end
  def biz_offer_status_types
    [:open,:approached, :working, :finished,:other_failure,:lost_failure,:natural_lost,:other_success]
  end
  def approach_status_types
    [:approaching,:adjust,:result_waiting, :working, :finished, :approach_failure,:interview_failure,:other_failure,:lost_failure,:natural_lost,:other_success]
  end
  def human_resource_status_types
    [:sales,:approached,:working,:unknown]
  end
  def contract_status_types
    [:open,:contract,:finished]
  end
  def upper_contract_status_types
    [:waiting_order,:proc_acceptance,:contracted,:finished,:abort,:confirming,:closed]
  end
  def down_contract_status_types
    [:waiting_offer,:proc_order,:waiting_acceptance,:contracted,:finished,:abort,:confirming,:closed]
  end
  def actions
    [:accept_order,:send_accept,:end_term,:abort_term,:prepare_next,:accept_continue_term,:accept_end_term,:notify_order,:send_order,:accept_accept,:send_continue_term,:send_end_term]
  end

  # アクションによるステータスの変化を定義
  def do_business_status_type_action(action)
    {:end_term => :finished, :abort_term => :finished, :accept_end_term => :finished}[action]
  end
  def do_biz_offer_status_type_action(action)
    {:end_term => :finished, :abort_term => :finished, :accept_end_term => :finished}[action]
  end
  def do_approach_status_type_action(action)
    {:end_term => :finished, :abort_term => :finished, :accept_end_term => :finished}[action]
  end
  def do_human_resource_status_type_action(action)
    {:end_term => :finished, :abort_term => :finished, :accept_end_term => :finished}[action]
  end

  def xexe(xss)
    status_to_actions = {}
    action_to_status = {}
    xss.each do |xs|
      status_to_actions[xs[0]] ||= []
      status_to_actions[xs[0]] << xs[1]
      action_to_status[xs[1]] = xs[2]
    end
    return [status_to_actions, action_to_status]
  end

  def xexe_business_status_type_actions
    xexe([
    
    ])
  end

  #----------------------------------------------------------

  def init_status
    @statuses = {
      :business_status_type => :working,
      :biz_offer_status_type => :working,
      :approach_status_type => :working,
      :human_resource_status_type => :working,
      :contract_status_type => :open,
      :upper_contract_status_type => :waiting_order,
      :down_contract_status_type => :waiting_offer,
    }
  end

  def do_action(action)
  end
  
=end
end

