# -*- encoding: utf-8 -*-
class ContractController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @contract_pages, @contracts = paginate :contracts, :conditions =>["deleted = 0"], :per_page => current_user.per_page
  end

  def show
    @contract = Contract.find(params[:id])
  end

  def quick_new
    contract_objects_new
    init_values(@contract)
    init_copies(@contract)
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
  end

  def new
    @calendar = true
    @contract = Contract.new
    @contract.closed_at = Date.today
    @closed_at_hour = Time.new.hour
    @closed_at_min = (Time.new.min / 10) * 10
    @contract.contracted_at = Date.today
    @contracted_at_hour = Time.new.hour
    @contracted_at_min = (Time.new.min / 10) * 10
    @contract.upper_contract_term = ContractTerm.new
    @contract.down_contract_term = ContractTerm.new
  end

  def create
    @calendar = true
    Contract.transaction do
      @contract = Contract.new(params[:contract])
      @contract.upper_contract_term = ContractTerm.new(params[:upper_contract_term])
      @contract.down_contract_term = ContractTerm.new(params[:down_contract_term])
      set_user_column @contract
      set_user_column @contract.upper_contract_term
      set_user_column @contract.down_contract_term
      
      if closed_at_date = DateTimeUtil.str_to_date(params[:contract][:closed_at])
        @contract.closed_at = Time.local(closed_at_date.year, closed_at_date.month, closed_at_date.day, params[:closed_at_hour].to_i, params[:closed_at_minute].to_i)
      end
      if contracted_at_date = DateTimeUtil.str_to_date(params[:contract][:contracted_at])
        @contract.contracted_at = Time.local(contracted_at_date.year, contracted_at_date.month, contracted_at_date.day, params[:contracted_at_hour].to_i, params[:contracted_at_minute].to_i)
      end
      
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
    @calendar = true
    @contract = Contract.find(params[:id])
    @closed_at_hour = @contract.closed_at.hour
    @closed_at_min = (@contract.closed_at.min / 10) * 10
    @contracted_at_hour = @contract.contracted_at.hour
    @contracted_at_min = (@contract.contracted_at.min / 10) * 10
    @contract.upper_contract_term = ContractTerm.find(@contract.upper_contract_term)
    @contract.down_contract_term = ContractTerm.find(@contract.down_contract_term)
  end

  def update
    @calendar = true
    Contract.transaction do
      @contract = Contract.find(params[:id], :conditions =>["deleted = 0"])
      @contract.upper_contract_term = ContractTerm.find(@contract.upper_contract_term, :conditions =>["deleted = 0"])
      @contract.down_contract_term = ContractTerm.find(@contract.down_contract_term, :conditions =>["deleted = 0"])
      @contract.attributes = params[:contract]
      @contract.upper_contract_term.attributes = params[:upper_contract_term]
      @contract.down_contract_term.attributes = params[:down_contract_term]
      set_user_column @contract
      set_user_column @contract.upper_contract_term
      set_user_column @contract.down_contract_term
      
      if closed_at_date = DateTimeUtil.str_to_date(params[:contract][:closed_at])
        @contract.closed_at = Time.local(closed_at_date.year, closed_at_date.month, closed_at_date.day, params[:closed_at_hour].to_i, params[:closed_at_minute].to_i)
      end
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
    
    redirect_to :action => 'list'
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
    contract.contract_status_type = 'open'
    contract.closed_at = Time.now
    contract.upper_contract_status_type = 'waiting_order'
    contract.down_contract_status_type = 'waiting_offer'

    contract.upper_contract_term.term_type = 'suspense'
    contract.upper_contract_term.tax_type = 'exclude'
    contract.upper_contract_term.time_adjust_type = 'suspense'
    contract.upper_contract_term.time_adjust_base_type = 'suspense'
    contract.upper_contract_term.time_adjust_time = 60
    contract.upper_contract_term.cutoff_date_type = 'suspense'
    contract.upper_contract_term.payment_sight_type = 'suspense'
    contract.upper_contract_term.contract_renewal_unit = 3
    contract.upper_contract_term.contract_renewal_terms = 1

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
    contract.down_contract_term.contract_start_date = contract.upper_contract_term.contract_start_date
    contract.down_contract_term.contract_end_date = contract.upper_contract_term.contract_end_date
    contract.down_contract_term.contract_renewal_unit = contract.upper_contract_term.contract_renewal_unit
    contract.down_contract_term.contract_renewal_terms = contract.upper_contract_term.contract_renewal_terms
    contract.down_contract_term.other_terms = contract.upper_contract_term.other_terms

    contract.approach.approached_at = contract.closed_at
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
    contract.approach.approach_upper_contract_term.contract_start_date = contract.upper_contract_term.contract_start_date
    contract.approach.approach_upper_contract_term.contract_end_date = contract.upper_contract_term.contract_end_date
    contract.approach.approach_upper_contract_term.contract_renewal_unit = contract.upper_contract_term.contract_renewal_unit
    contract.approach.approach_upper_contract_term.contract_renewal_terms = contract.upper_contract_term.contract_renewal_terms
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
    contract.approach.approach_down_contract_term.contract_start_date = contract.upper_contract_term.contract_start_date
    contract.approach.approach_down_contract_term.contract_end_date = contract.upper_contract_term.contract_end_date
    contract.approach.approach_down_contract_term.contract_renewal_unit = contract.upper_contract_term.contract_renewal_unit
    contract.approach.approach_down_contract_term.contract_renewal_terms = contract.upper_contract_term.contract_renewal_terms
    contract.approach.approach_down_contract_term.other_terms = contract.upper_contract_term.other_terms

    contract.approach.biz_offer.biz_offered_at = contract.closed_at
    contract.approach.biz_offer.contact_pic_id = contract.contract_pic_id
    contract.approach.biz_offer.sales_pic_id = contract.contract_pic_id

    contract.approach.biz_offer.business.issue_datetime = contract.closed_at
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
    contract.approach_id = contract.approach.id
    contract.upper_contract_term.save!
    contract.down_contract_term.save!
    contract.save!
  end
end
