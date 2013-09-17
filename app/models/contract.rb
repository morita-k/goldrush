# -*- encoding: utf-8 -*-
class Contract < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
#  attr_accessor :closed_at_date, :closed_at_hour, :closed_at_minute, :contracted_at_date, :contracted_at_hour, :contracted_at_minute
  attr_accessor :contracted_at_date, :contracted_at_hour, :contracted_at_minute
  after_initialize :after_initialize

  has_many :interviews, :conditions => ["interviews.deleted = 0"]
  belongs_to :upper_contract_term, :class_name => 'ContractTerm'
  belongs_to :down_contract_term, :class_name => 'ContractTerm'
  belongs_to :contract_pic, :class_name => 'User'
  belongs_to :approach

#  validates_presence_of     :closed_at, :contract_pic_id, :start_date
  validates_presence_of     :contract_pic_id

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

#  def setup_closed_at(zone_now)
#    date, hour, min = DateTimeUtil.split_date_hour_minute(zone_now)
#    self.closed_at_date = date
#    self.closed_at_hour = hour
#    self.closed_at_minute = min
#  end
#
#  def perse_closed_at(user)
#    unless closed_at_date.blank? || closed_at_hour.blank? || closed_at_minute.blank?
#      self.closed_at = user.zone_parse("#{closed_at_date} #{closed_at_hour}:#{closed_at_minute}:00")
#    end
#  end

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

  def contract_pic_name
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
  
  def contract_start_date_view
    contract_start_date && contract_start_date.strftime("%y/%m/%d")
  end

  def contract_end_date_view
    contract_end_date && contract_end_date.strftime("%y/%m/%d")
  end

  def term_term
    "#{contract_start_date_view} ～ #{contract_end_date_view}"
  end

  def contract_renewal
    "#{contract_renewal_unit}(#{contract_renewal_terms})"
  end

  def next_term
    Contract.where("approach_id = ? and contract_start_date > ? and contract_status_type != ?", approach_id, contract_end_date, 'finished').order("contract_start_date").first
  end

  # 契約終了バッチ
  # 
  # 毎月月初に走る
  # 
  # 下記の条件に合致する[契約]を抽出
  # 1. [契約]のステータスが「契約中」
  # 2. 契約終了日 が過去になっている(前月末以前)
  # 3. 後続の[契約]がない(*1)
  # 
  # 抽出した[契約]の[提案]の[稼働終了日]に[契約終了日]を入れる(契約終了日が前月末じゃないことは考えない)
  # [上流契約ステータス区分]と[下流契約ステータス区分 ]に「契約満了」を入れる
  # [契約ステータス区分]に「契約終了」を入れる
  # 
  # [人材]の[人材ステータス区分]を「営業中」にする
  # 
  # [提案]の[提案ステータス区分]を「案件終了」にする
  # [照会]の[照会ステータス区分]を「案件終了」にする
  # [案件]の[案件ステータス区分]を「案件終了」にする
  #
  # (*1) 後続契約ありの判断
  # 1. 対象[契約]の[契約完了日] < [契約開始日] となっている[契約]を抽出
  # 2. 抽出した[契約]の[契約ステータス]が、「契約終了」じゃないもの
  # この条件に合致した契約がある場合、後続契約ありとみなす。
  def Contract.close_contracts(today=Date.today)
    ActiveRecord::Base.transaction do
      Contract.where("deleted = 0 and contract_status_type = 'contract' and contract_end_date < ?", today).order("contract_end_date desc").each do |c|
        next if c.next_term

        # 契約
        c.contract_status_type = 'finished'
        c.upper_contract_status_type = 'closed'
        c.down_contract_status_type = 'closed'

        # 提案
        c.approach.approach_status_type = 'finished'
        c.approach.end_date = c.contract_end_date

        # 人材
        c.approach.bp_member.human_resource.human_resource_status_type = 'sales'

        # 照会
        c.approach.biz_offer.biz_offer_status_type = 'finished'

        # 案件
        c.approach.biz_offer.business.business_status_type = 'finished'

       # 更新
        for i in [c.approach.biz_offer.business, c.approach.biz_offer, c.approach.bp_member.human_resource, c.approach, c]
          i.updated_user = 'make_next'
          i.save!
        end
      end
    end
  end
  
  # 次契約作成バッチ
  # 
  # 毎月月初に走る
  # 
  # 下記の条件に合致する[契約]を抽出
  # 1. [契約]のステータスが「契約中」
  # 2. 「バッチ起動日＋契約更新事前通達月数」の年月 ≧ [契約終了日]の年月
  # 3. 後続の[契約]がない(*1)
  # 
  # 条件に合致した[契約]に対して"次契約作成項目移送表"シートの処理を行う
  def Contract.make_next(today=Date.today)
    ActiveRecord::Base.transaction do
      Contract.where("deleted = 0 and contract_status_type = 'contract'").each do |c|
        make_next_in(c)
      end
    end
  end

  def Contract.make_next_in(c)
    return if (today + c.contract_renewal_terms.to_i.month).strftime("%Y%m") < c.contract_end_date.strftime("%Y%m")
    return if c.next_term
    
    upper = ContractTerm.new(c.upper_contract_term.attributes)
    upper.created_user = 'make_next'
    upper.updated_user = 'make_next'
    upper.save!

    down = ContractTerm.new(c.down_contract_term.attributes)
    down.created_user = 'make_next'
    down.updated_user = 'make_next'
    down.save!

    n = Contract.new
    n.contract_status_type = 'open'
    n.approach_id = c.approach_id
    n.contract_pic_id = c.contract_pic_id
    n.contract_start_date = c.contract_end_date + 1
    n.contract_end_date = (n.contract_start_date + c.contract_renewal_unit.to_i.month) - 1 # 契約単位月経過後の月末
    n.contract_renewal_unit = c.contract_renewal_unit
    n.contract_renewal_terms = c.contract_renewal_terms
    n.upper_contract_term_id = upper.id
    n.down_contract_term_id = down.id
    n.upper_contract_status_type = 'confirming'
    n.down_contract_status_type = 'confirming'
    n.created_user = 'make_next'
    n.updated_user = 'make_next'
    n.save!

    make_next_in(n)
  end
end
