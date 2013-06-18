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

  def contract_objects_new
    # 案件
    @business = Business.new(params[:business])
    # 人材
    @human_resource = HumanResource.new
    # 所属
    @bp_member = BpMember.new
    @bp_member.human_resource = @human_resource
    @bp_member.business_partner = BusinessPartner.new
    # 照会
    @biz_offer = BizOffer.new(params[:biz_offer])
    @biz_offer.business = @business
    # 提案
    @approach = Approach.new(params[:approach])
    @approach.biz_offer = @biz_offer
    @approach.bp_member = @bp_member
    @approach_upper_contract_term = ContractTerm.new(params[:approach_upper_contract_term])
    @approach_down_contract_term = ContractTerm.new(params[:approach_down_contract_term])
    @approach.approach_upper_contract_term = @approach_upper_contract_term
    @approach.approach_down_contract_term = @approach_down_contract_term
    # 契約
    @contract = Contract.new(params[:contract])
    @upper_contract_term = ContractTerm.new(params[:upper_contract_term])
    @down_contract_term = ContractTerm.new(params[:down_contract_term])
    @contract.approach = @approach
    @contract.upper_contract_term = @upper_contract_term
    @contract.down_contract_term = @down_contract_term
  end

  def quick_new
    contract_objects_new

    init_set(@contract)
  end

  def quick_create
    contract_objects_new
    
    ActiveRecord::Base.transaction do
    
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
  def init_set(contract)
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

    contract.down_contract_term.term_type = contract.upper_contract_term.term_type
    contract.down_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.down_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.down_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.down_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.down_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.down_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type

    contract.approach.approach_status_type = 'working'
    contract.approach.approached_at = contract.closed_at

    contract.approach.approach_upper_contract_term.term_type = contract.upper_contract_term.term_type
    contract.approach.approach_upper_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.approach.approach_upper_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.approach.approach_upper_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.approach.approach_upper_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.approach.approach_upper_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.approach.approach_upper_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type

    contract.approach.approach_down_contract_term.term_type = contract.upper_contract_term.term_type
    contract.approach.approach_down_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.approach.approach_down_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.approach.approach_down_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.approach.approach_down_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.approach.approach_down_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.approach.approach_down_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type

    contract.approach.biz_offer.biz_offer_status_type = 'working'
    contract.approach.biz_offer.biz_offered_at = contract.closed_at

    contract.approach.biz_offer.business.business_status_type = 'working'
    contract.approach.biz_offer.business.issue_datetime = contract.closed_at
    contract.approach.biz_offer.business.term_type = contract.upper_contract_term.term_type

    contract.approach.bp_member.employment_type = 'unknown'
    
    contract.approach.bp_member.human_resource.human_resource_status_type = 'waiting'
  end

  def create_set(contract)
    #contract.contract_status_type = 'open'
    #contract.closed_at = Time.now
    #contract.upper_contract_status_type = 'waiting_order'
    #contract.down_contract_status_type = 'waiting_offer'

    #contract.upper_contract_term.term_type = 'suspense'
    #contract.upper_contract_term.tax_type = 'exclude'
    #contract.upper_contract_term.time_adjust_type = 'suspense'
    #contract.upper_contract_term.time_adjust_base_type = 'suspense'
    contract.upper_contract_term.time_adjust_time = 60
    contract.upper_contract_term.cutoff_date_type = 'suspense'
    contract.upper_contract_term.payment_sight_type = 'suspense'

    contract.down_contract_term.term_type = contract.upper_contract_term.term_type
    contract.down_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.down_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.down_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.down_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.down_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.down_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type

    contract.approach.approach_status_type = 'working'
    contract.approach.approached_at = contract.closed_at

    contract.approach.approach_upper_contract_term.term_type = contract.upper_contract_term.term_type
    contract.approach.approach_upper_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.approach.approach_upper_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.approach.approach_upper_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.approach.approach_upper_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.approach.approach_upper_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.approach.approach_upper_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type

    contract.approach.approach_down_contract_term.term_type = contract.upper_contract_term.term_type
    contract.approach.approach_down_contract_term.tax_type = contract.upper_contract_term.tax_type
    contract.approach.approach_down_contract_term.time_adjust_type = contract.upper_contract_term.time_adjust_type
    contract.approach.approach_down_contract_term.time_adjust_base_type = contract.upper_contract_term.time_adjust_base_type
    contract.approach.approach_down_contract_term.time_adjust_time = contract.upper_contract_term.time_adjust_time
    contract.approach.approach_down_contract_term.cutoff_date_type = contract.upper_contract_term.cutoff_date_type
    contract.approach.approach_down_contract_term.payment_sight_type = contract.upper_contract_term.payment_sight_type

    contract.approach.biz_offer.biz_offer_status_type = 'working'
    contract.approach.biz_offer.biz_offered_at = contract.closed_at

    contract.approach.biz_offer.business.business_status_type = 'working'
    contract.approach.biz_offer.business.issue_datetime = contract.closed_at
    contract.approach.biz_offer.business.term_type = contract.upper_contract_term.term_type

    contract.approach.bp_member.employment_type = 'unknown'
    
    contract.approach.bp_member.human_resource.human_resource_status_type = 'waiting'
  end
end
