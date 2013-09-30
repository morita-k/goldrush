# -*- encoding: utf-8 -*-
class ContractController < ApplicationController

  def index
    if list
      render :action => 'list'
    end
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def target_date(year,month, then_block, else_block)
    if year.blank?
      else_block.call
    elsif month.blank?
      st = "#{year}/1/1".to_date
      ed = "#{year}/12/31".to_date
      then_block.call st, ed
    else
      st = "#{year}/#{month}/1".to_date
      ed = st.end_of_month
      then_block.call st, ed
    end
  end

  def each_month(st, ed, &block)
    return if st > ed
    block.call(st.beginning_of_month, st.end_of_month)
    each_month(st.next_month, ed, &block)
  end

  def summary(st, ed, contracts, &cond)
    sum = {:upper_payment => 0, :down_payment => 0, :gross_profit => 0}
    each_month(st,ed) do |xst, xed|
      contracts.each do |c|
        next unless cond.call c
        next unless c.in_term?(xst, xed)
        sum[:upper_payment] += c.upper_contract_term.payment
        sum[:down_payment] += c.down_contract_term.payment
        sum[:gross_profit] += (c.upper_contract_term.payment - c.down_contract_term.payment)
      end
    end
    sum
  end
    
  def list
    if params[:clear]
      params[:year] = params[:month] = nil
      redirect_to
      return false
    end

    target_date params[:year], params[:month], lambda {|st, ed|
      @contracts = Contract.where("deleted = 0 and contract_status_type in ('contract','finished') and contract_end_date >= ? and contract_start_date <= ? ", st, ed).order("contract_start_date")
      @summary = summary(st, ed, @contracts) {true}
      @summary_prop = summary(st, ed, @contracts) {|c| c.proper? }
      @summary_non_prop = summary(st, ed, @contracts) {|c| !c.proper? }
    }, lambda {
      @contract_pages, @contracts = paginate :contracts, :conditions =>["deleted = 0"], :per_page => current_user.per_page, :order => "contract_start_date desc"
    }
    return true
  end

  def works
    date = params[:target_date] && params[:target_date].to_date || Date.today
    @target_start = (date - 2.month).beginning_of_month
    @target_end = (date + 9.month).end_of_month
    @contracts = Contract.where("contract_end_date >= ? and contract_start_date <= ? and deleted = 0", @target_start, @target_end).order("(upper_contract_status_type = 'closed' or upper_contract_status_type = 'abort'), approach_id, contract_start_date")
    @works = Hash.new
    @contracts.each do |c|
      @works[c.approach.bp_member.human_resource] ||= []
      @works[c.approach.bp_member.human_resource] << c
    end
  end

  def show
    @contract = Contract.find(params[:id])
  end

  def quick_new
    contract_objects_new
    init_values(@contract)
    init_copies(@contract)
#    @contract.setup_closed_at(current_user.zone_now)
  end

  def quick_create
    contract_objects_new
    init_values(@contract)
    update_params(@contract)
    init_copies(@contract)

    ActiveRecord::Base.transaction do
      save_all!(@contract)
      flash[:notice] = 'Contract was successfully created.'
      redirect_to :controller => :contract, :action => :list
    end # transaction
  rescue ActiveRecord::RecordInvalid
    puts ">>>>" + @contract.approach.inspect
    puts ">>>>" + $!.inspect
    render :action => 'quick_new'
  end

  def new
    @contract = Contract.new
#    @contract.closed_at = Date.today
#    @closed_at_hour = Time.new.hour
#    @closed_at_min = (Time.new.min / 10) * 10
    @contract.contracted_at = Date.today
    @contracted_at_hour = Time.new.hour
    @contracted_at_min = (Time.new.min / 10) * 10
    @contract.upper_contract_term = ContractTerm.new
    @contract.down_contract_term = ContractTerm.new
#    @contract.setup_closed_at(current_user.zone_now)
  end

  def create
    Contract.transaction do
      @contract = Contract.new(params[:contract])
      @contract.upper_contract_term = ContractTerm.new(params[:upper_contract_term])
      @contract.down_contract_term = ContractTerm.new(params[:down_contract_term])
      set_user_column @contract
      set_user_column @contract.upper_contract_term
      set_user_column @contract.down_contract_term
      
#      if closed_at_date = DateTimeUtil.str_to_date(params[:contract][:closed_at])
#        @contract.closed_at = Time.local(closed_at_date.year, closed_at_date.month, closed_at_date.day, params[:closed_at_hour].to_i, params[:closed_at_minute].to_i)
#      end
      if contracted_at_date = DateTimeUtil.str_to_date(params[:contract][:contracted_at])
        @contract.contracted_at = Time.local(contracted_at_date.year, contracted_at_date.month, contracted_at_date.day, params[:contracted_at_hour].to_i, params[:contracted_at_minute].to_i)
      end
#      @contract.perse_closed_at(current_user)
      @contract.save!
      @contract.upper_contract_term.save!
      @contract.down_contract_term.save!
    end
    flash[:notice] = 'Contract was successfully created.'
    redirect_to :controller => 'approach', :action => 'show', :id => @contract.approach_id
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @contract = Contract.find(params[:id])
#    @contract.setup_closed_at(@contract.closed_at)
    @contract.setup_contracted_at(@contract.contracted_at)
  end

  def update
    Contract.transaction do
      @contract = Contract.find(params[:id], :conditions =>["deleted = 0"])
      @contract.attributes = params[:contract]
#      @contract.perse_closed_at(current_user)
      @contract.perse_contracted_at(current_user)
      @contract.upper_contract_term.attributes = params[:upper_contract_term]
      @contract.down_contract_term.attributes = params[:down_contract_term]
      set_user_column @contract
      set_user_column @contract.upper_contract_term
      set_user_column @contract.down_contract_term
      
#      if closed_at_date = DateTimeUtil.str_to_date(params[:contract][:closed_at])
#        @contract.closed_at = Time.local(closed_at_date.year, closed_at_date.month, closed_at_date.day, params[:closed_at_hour].to_i, params[:closed_at_minute].to_i)
#      end
      if contracted_at_date = DateTimeUtil.str_to_date(params[:contract][:contracted_at])
        @contract.contracted_at = Time.local(contracted_at_date.year, contracted_at_date.month, contracted_at_date.day, params[:contracted_at_hour].to_i, params[:contracted_at_minute].to_i)
      end
      
      @contract.save!
      @contract.upper_contract_term.save!
      @contract.down_contract_term.save!
    end
    flash[:notice] = 'Contract was successfully updated.'
    redirect_to :controller => 'approach', :action => 'show', :id => @contract.approach_id
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @contract = Contract.find(params[:id], :conditions =>["deleted = 0"])
    @contract.deleted = 9
    @contract.deleted_at = Time.now
    set_user_column @contract
    @contract.save!
    
    redirect_to(back_to || {:action => 'list'})
  end

  def do_action
    @contract = Contract.find(params[:id], :conditions =>["deleted = 0"])
    @contract.do_action(params[:a].to_sym, params[:type].to_sym)
    set_user_column @contract
    @contract.save!
    
    redirect_to back_to
  end

private
  def contract_objects_new
    # 案件
    @business = Business.new
    # 照会
    @biz_offer = BizOffer.new
    @biz_offer.business = @business
    # 提案
    @approach = Approach.new
    @approach.biz_offer = @biz_offer
    @approach_upper_contract_term = ContractTerm.new
    @approach_down_contract_term = ContractTerm.new
    @approach.approach_upper_contract_term = @approach_upper_contract_term
    @approach.approach_down_contract_term = @approach_down_contract_term
    # 契約
    @contract = Contract.new
    @upper_contract_term = ContractTerm.new
    @down_contract_term = ContractTerm.new
    @contract.approach = @approach
    @contract.upper_contract_term = @upper_contract_term
    @contract.down_contract_term = @down_contract_term
  end

  def init_values(contract)
#    contract.contract_status_type = 'open'
    contract.contract_status_type = 'contract'
#    contract.closed_at = Time.now
#    contract.upper_contract_status_type = 'waiting_order'
#    contract.down_contract_status_type = 'waiting_offer'
    contract.upper_contract_status_type = 'contracted'
    contract.down_contract_status_type = 'contracted'

    contract.upper_contract_term.term_type = 'suspense'
    contract.upper_contract_term.tax_type = 'exclude'
    contract.upper_contract_term.time_adjust_type = 'suspense'
    contract.upper_contract_term.time_adjust_base_type = 'suspense'
    contract.upper_contract_term.time_adjust_time = 60
    contract.upper_contract_term.cutoff_date_type = 'suspense'
    contract.upper_contract_term.payment_sight_type = 'suspense'
#    contract.upper_contract_term.contract_renewal_unit = 3
#    contract.upper_contract_term.contract_renewal_terms = 1
    contract.contract_renewal_unit = 3
    contract.contract_renewal_terms = 1

    contract.approach.approach_status_type = 'working'

    contract.approach.biz_offer.biz_offer_status_type = 'working'

    contract.approach.biz_offer.business.business_status_type = 'working'

  end

  def init_copies(contract)
    contract.down_contract_term.term_type = contract.upper_contract_term.term_type
    #contract.down_contract_term.payment = contract.upper_contract_term.payment
    contract.down_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.down_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.down_contract_term.time_adjust_upper = contract.upper_contract_term.time_adjust_upper
    contract.down_contract_term.time_adjust_limit = contract.upper_contract_term.time_adjust_limit
    contract.down_contract_term.time_adjust_under = contract.upper_contract_term.time_adjust_under
    contract.down_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.down_contract_term.over_time_payment = contract.upper_contract_term.over_time_payment
    contract.down_contract_term.under_time_penalty = contract.upper_contract_term.under_time_penalty
    contract.down_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.down_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.down_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type
#    contract.down_contract_term.contract_start_date = contract.upper_contract_term.contract_start_date
#    contract.down_contract_term.contract_end_date = contract.upper_contract_term.contract_end_date
#    contract.down_contract_term.contract_renewal_unit = contract.upper_contract_term.contract_renewal_unit
#    contract.down_contract_term.contract_renewal_terms = contract.upper_contract_term.contract_renewal_terms
    contract.down_contract_term.other_terms = contract.upper_contract_term.other_terms

#    contract.approach.approached_at = contract.closed_at
    now = Time.now
    contract.approach.approached_at = now
    contract.approach.closed_at = now
    contract.approach.start_date = contract.contract_start_date
    contract.approach.approach_pic_id = contract.contract_pic_id

    contract.approach.approach_upper_contract_term.term_type = contract.upper_contract_term.term_type
    contract.approach.approach_upper_contract_term.payment = contract.upper_contract_term.payment
    contract.approach.approach_upper_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.approach.approach_upper_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.approach.approach_upper_contract_term.time_adjust_upper = contract.upper_contract_term.time_adjust_upper
    contract.approach.approach_upper_contract_term.time_adjust_limit = contract.upper_contract_term.time_adjust_limit
    contract.approach.approach_upper_contract_term.time_adjust_under = contract.upper_contract_term.time_adjust_under
    contract.approach.approach_upper_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.approach.approach_upper_contract_term.over_time_payment = contract.upper_contract_term.over_time_payment
    contract.approach.approach_upper_contract_term.under_time_penalty = contract.upper_contract_term.under_time_penalty
    contract.approach.approach_upper_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.approach.approach_upper_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.approach.approach_upper_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type
#    contract.approach.approach_upper_contract_term.contract_start_date = contract.upper_contract_term.contract_start_date
#    contract.approach.approach_upper_contract_term.contract_end_date = contract.upper_contract_term.contract_end_date
#    contract.approach.approach_upper_contract_term.contract_renewal_unit = contract.upper_contract_term.contract_renewal_unit
#    contract.approach.approach_upper_contract_term.contract_renewal_terms = contract.upper_contract_term.contract_renewal_terms
    contract.approach.approach_upper_contract_term.other_terms = contract.upper_contract_term.other_terms

    contract.approach.approach_down_contract_term.term_type = contract.upper_contract_term.term_type
    contract.approach.approach_down_contract_term.payment = contract.down_contract_term.payment # ここだけ下流
    contract.approach.approach_down_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.approach.approach_down_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.approach.approach_down_contract_term.time_adjust_upper = contract.upper_contract_term.time_adjust_upper
    contract.approach.approach_down_contract_term.time_adjust_limit = contract.upper_contract_term.time_adjust_limit
    contract.approach.approach_down_contract_term.time_adjust_under = contract.upper_contract_term.time_adjust_under
    contract.approach.approach_down_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.approach.approach_down_contract_term.over_time_payment = contract.upper_contract_term.over_time_payment
    contract.approach.approach_down_contract_term.under_time_penalty = contract.upper_contract_term.under_time_penalty
    contract.approach.approach_down_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.approach.approach_down_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.approach.approach_down_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type
#    contract.approach.approach_down_contract_term.contract_start_date = contract.upper_contract_term.contract_start_date
#    contract.approach.approach_down_contract_term.contract_end_date = contract.upper_contract_term.contract_end_date
#    contract.approach.approach_down_contract_term.contract_renewal_unit = contract.upper_contract_term.contract_renewal_unit
#    contract.approach.approach_down_contract_term.contract_renewal_terms = contract.upper_contract_term.contract_renewal_terms
    contract.approach.approach_down_contract_term.other_terms = contract.upper_contract_term.other_terms

    contract.approach.biz_offer.biz_offered_at = now#contract.closed_at
    contract.approach.biz_offer.contact_pic_id = contract.contract_pic_id
    contract.approach.biz_offer.sales_pic_id = contract.contract_pic_id

    contract.approach.biz_offer.business.issue_datetime = now#contract.closed_at
    contract.approach.biz_offer.business.term_type = contract.upper_contract_term.term_type
  end

  def update_params(contract)
    # 案件
    contract.approach.biz_offer.business.attributes = params[:business]
    set_user_column contract.approach.biz_offer.business
    # 照会
    contract.approach.biz_offer.attributes = params[:biz_offer]
    set_user_column contract.approach.biz_offer
    # 提案
    contract.approach.attributes = params[:approach]
    contract.approach.approach_upper_contract_term.attributes = params[:approach_upper_contract_term]
    contract.approach.approach_down_contract_term.attributes = params[:approach_down_contract_term]
    set_user_column contract.approach
    set_user_column contract.approach.approach_upper_contract_term
    set_user_column contract.approach.approach_down_contract_term
    # 契約
    contract.attributes = params[:contract]
    contract.upper_contract_term.attributes = params[:upper_contract_term]
    contract.down_contract_term.attributes = params[:down_contract_term]
#    contract.perse_closed_at(current_user)
    set_user_column contract
    set_user_column contract.upper_contract_term
    set_user_column contract.down_contract_term
  end
  
  def save_all!(contract)
    # 案件
    contract.approach.biz_offer.business.save!
    # 照会
    contract.approach.biz_offer.business_id = contract.approach.biz_offer.business.id
    contract.approach.biz_offer.save!
    # 提案
    contract.approach.biz_offer_id = contract.approach.biz_offer.id
    contract.approach.approach_upper_contract_term.save!
    contract.approach.approach_down_contract_term.save!
    contract.approach.save!
    # 契約
    #contract.approach_id = contract.approach.id
    contract.upper_contract_term.save!
    contract.down_contract_term.save!
    contract.save!
  end
end
