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
    if a = @actions_map[status_type].detect{|x| x.action == action}
      if a.event
        send("#{status_type}=", a.event.call(a))
      else
        send("#{status_type}=", a.to)
      end
    end
  end

  def change_status(action, status_type = detect_default_status_type)
    next_status = do_action(action, status_type)
    attributes["#{status_type}"] = next_status.to_s
  end

  def next_actions(status_type = detect_default_status_type)
     @actions_map[status_type].reject do |action|
       action.from != send(status_type).to_sym
     end
  end
end

