# -*- encoding: utf-8 -*-
class Contract < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  attr_accessor :closed_at_date, :closed_at_hour, :closed_at_minute, :contracted_at_date, :contracted_at_hour, :contracted_at_minute
  after_initialize :after_initialize

  has_many :interviews, :conditions => ["interviews.deleted = 0"]
  belongs_to :upper_contract_term, :class_name => 'ContractTerm'
  belongs_to :down_contract_term, :class_name => 'ContractTerm'
  belongs_to :contract_pic, :class_name => 'User'
  belongs_to :approach

  validates_presence_of     :closed_at, :contract_pic_id, :start_date

  # 契約条件が、上流も下流も「契約済み」であれば「契約中」にアップデートする
  def make_contract_proc(str)
    return ->(a){
      if ["contracted"].include?(attributes["#{str}_contract_status_type"])
        change_status(:conclusion, :contract_status_type)
      end
      return a.to
    }
  end

  # 契約条件が、上流も下流も「契約満了、途中解約、更新なし」であれば「契約完了」にアップデートする
  def make_finished_proc(str)
    return ->(a){
      if ["finished","abort","closed"].include?(attributes["#{str}_contract_status_type"])
        change_status(:finish_contract, :contract_status_type)
      end
      return a.to
    }
  end

  def finished?
    ['finished'].include? contract_status_type
  end

  def after_initialize
    init_actions([
      [:open, :contract, :conclusion],
      [:contract, :finished, :finish_contract, ->(a){
        #approachにぶら下がるすべての契約がfinishedしているか確認する
        if approach.contracts.all?{|c| c.id == self.id || c.finished?}
          approach.change_status(:finish)
          approach.save!
        end
        return a.to
      }],
    ], :contract_status_type)
    init_actions([
      [:waiting_order, :proc_acceptance, :accept_order],
      [:proc_acceptance, :contracted, :send_accept, make_contract_proc(:down)],
      [:contracted, :finished, :finish_term, make_finished_proc(:down)],
      [:contracted, :abort, :abort_term, make_finished_proc(:down)],
      [:contracted, :confirming, :make_next],
      [:confirming, :waiting_order, :accept_reorder],
      [:confirming, :closed, :accept_close, make_finished_proc(:down)],
    ], :upper_contract_status_type)
    init_actions([
      [:waiting_offer, :proc_order, :send_offer],
      [:proc_order, :waiting_acceptance, :send_order],
      [:waiting_acceptance, :contracted, :accept_accept, make_contract_proc(:upper)],
      [:contracted, :finished, :finish_term, make_finished_proc(:upper)],
      [:contracted, :abort, :abort_term, make_finished_proc(:upper)],
      [:contracted, :confirming, :make_next],
      [:confirming, :proc_order, :send_reorder],
      [:confirming, :closed, :send_close, make_finished_proc(:upper)],
    ], :down_contract_status_type)
  end

  def setup_closed_at(zone_now)
    date, hour, min = DateTimeUtil.split_date_hour_minute(zone_now)
    self.closed_at_date = date
    self.closed_at_hour = hour
    self.closed_at_minute = min
  end

  def perse_closed_at(user)
    unless closed_at_date.blank? || closed_at_hour.blank? || closed_at_minute.blank?
      self.closed_at = user.zone_parse("#{closed_at_date} #{closed_at_hour}:#{closed_at_minute}:00")
    end
  end

  def setup_contracted_at(zone_now)
    if zone_now
      date, hour, min = DateTimeUtil.split_date_hour_minute(zone_now)
      self.contracted_at_date = date
      self.contracted_at_hour = hour
      self.contracted_at_minute = min
    end
  end

  def perse_contracted_at(user)
    unless contracted_at_date.blank? || contracted_at_hour.blank? || contracted_at_minute.blank?
      self.contracted_at = user.zone_parse("#{contracted_at_date} #{contracted_at_hour}:#{contracted_at_minute}:00")
    end
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
  
  def payment_diff
    upper_contract_term.payment_diff(down_contract_term)
  end
  
  def payment_diff_veiw
    payment_diff / 10000.0
  end
  
  def payment_redio
    (100.0 * payment_diff / upper_contract_term.payment).round(1)
  end
  
  # 契約をクローズする
  # 継続する契約があれば、提案などはそのままキープ
  # 継続する契約が[更新なし]であれば、提案->照会->案件をクローズし、人材のステータスも[営業中]にする
  def Contract.close_contracts(date)
    ActiveRecord::Base.transaction do
      Contract.where(:deleted => 0, :contract_status_type => :contract).each do |c|
        changed = false
        if c.upper_contract_status_type == 'contracted' && c.upper_contract_term.contract_end_date < date
          c.change_status(:finish_term, :upper_contract_status_type)
          changed = true
        end 
        if c.down_contract_status_type == 'contracted' && c.down_contract_term.contract_end_date < date
          c.change_status(:finish_term, :down_contract_status_type)
          changed = true
        end 
        c.save! if changed
      end
    end
  end
  
  # 次回契約を確認ステータスで作る
  def Contract.make_next(date)
    ActiveRecord::Base.transaction do
      Contract.where(:deleted => 0, :contract_status_type => :contract).each do |c|
#        if c.upper_contract_term.contract_end_date - 1.month
      end
    end
  end
end
