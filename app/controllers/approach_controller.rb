# -*- encoding: utf-8 -*-
class ApproachController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @approach_pages, @approaches = paginate :approaches, :conditions =>["deleted = 0"], :per => current_user.per_page
  end

  def show
    @approach = Approach.find(params[:id])
    @approach_upper_contract_term = ContractTerm.find(@approach.approach_upper_contract_term_id)
    @approach_down_contract_term = ContractTerm.find(@approach.approach_down_contract_term_id)
    @biz_offer = @approach.biz_offer
    @business = @biz_offer.business
    @bp_member = @approach.bp_member
    @human_resource = @bp_member.human_resource
    if @contract = @approach.contract
      @upper_contract_term = ContractTerm.find(@contract.upper_contract_term_id)
      @down_contract_term = ContractTerm.find(@contract.down_contract_term_id)
    end
    @interviews = @approach.interviews
    @attachment_files = AttachmentFile.get_attachment_files('approaches', @approach.id)

    if params[:approach_success]
      @approach.approach_status_type = 'result_waiting'
      set_user_column @approach
      @approach.save!
      redirect_to :controller => 'interview', :action => 'new', :newly => true, :approach => @approach
    elsif params[:approach_adjustment]
      @approach.approach_status_type = 'adjust'
      set_user_column @approach
      @approach.save!
      redirect_to :controller => 'approach', :action => 'edit', :id => @approach
    elsif params[:approach_reject]
      Approach.transaction do
        @approach.approach_status_type = 'approach_failure'
        set_user_column @approach
        @approach.save!

        # 照会ステータスを変更する（未実装）
        @biz_offer.change_status_type
        set_user_column @biz_offer
        @biz_offer.save!

        # 人材ステータスを変更する（未実装）
        @human_resource.change_status_type
        set_user_column @human_resource
        @human_resource.save!
      end
      redirect_to :controller => 'approach', :action => 'show', :id => @approach


    elsif params[:create_contract]
      redirect_to :controller => 'contract', :action => 'new', :approach => @approach

    elsif params[:result_wait]
      interview = @approach.last_interview
      interview.interview_status_type = 'result_waiting'
      set_user_column interview
      interview.save!
      redirect_to :controller => 'approach', :action => 'show', :approach => @approach
    elsif params[:create_interview]
      redirect_to :controller => 'interview', :action => 'new', :newly => true, :approach => @approach
    elsif params[:interview_finish]
      interview = @approach.last_interview
      interview.interview_status_type = 'finished'
      set_user_column interview
      interview.save!
      redirect_to :controller => 'interview', :action => 'new', :approach => @approach
    elsif params[:interview_reject]
      Approach.transaction do
        interview = @approach.last_interview
        interview.interview_status_type = 'interview_failure'
        set_user_column interview
        interview.save!

        # 提案ステータスを「面談失敗」へ変更
        @approach.approach_status_type = 'interview_failure'
        set_user_column @approach
        @approach.save!

        # 照会ステータスを変更する（未実装）
        @biz_offer.change_status_type
        set_user_column @biz_offer
        @biz_offer.save!

        # 人材ステータスを変更する（未実装）
        @human_resource.change_status_type
        set_user_column @human_resource
        @human_resource.save!
      end
      redirect_to :action => 'show', :approach => @approach
    end

  end

  def new
    @biz_offer = BizOffer.find(params[:biz_offer_id])
    @approach = Approach.new
    @approach.biz_offer = @biz_offer
    @approach.approached_at = Date.today
    @approached_at_hour = Time.new.hour
    @approached_at_min = (Time.new.min / 10) * 10

    @approach.closed_at = Date.today
    @closed_at_hour = Time.new.hour
    @closed_at_min = (Time.new.min / 10) * 10

    @approach.approach_upper_contract_term = ContractTerm.new
    @approach.approach_down_contract_term = ContractTerm.new
#    @business = Business.find(params[:business])
    @business = @biz_offer.business
  end

  def create
    Approach.transaction do
      @approach = create_model(:approaches, params[:approach])
      @approach.approach_status_type = 'approaching'
      @approach.approach_upper_contract_term = create_model(:contract_terms, params[:approach_upper_contract_term])
      @approach.approach_down_contract_term = create_model(:contract_terms, params[:approach_down_contract_term])
      set_user_column @approach
      set_user_column @approach.approach_upper_contract_term
      set_user_column @approach.approach_down_contract_term

      if date = DateTimeUtil.str_to_date(params[:approach][:approached_at])
        @approach.approached_at = Time.local(date.year, date.month, date.day, params[:approached_at_hour].to_i, params[:approached_at_minute].to_i)
      end

      if date = DateTimeUtil.str_to_date(params[:approach][:closed_at])
        @approach.closed_at = Time.local(date.year, date.month, date.day, params[:closed_at_hour].to_i, params[:closed_at_minute].to_i)
      end

      @approach.save!
      @approach.approach_upper_contract_term.save!
      @approach.approach_down_contract_term.save!

      @biz_offer = BizOffer.find(@approach.biz_offer)
      @biz_offer.biz_offer_status_type = 'approached'
      set_user_column @biz_offer
      @biz_offer.save!

      @human_resource = HumanResource.find(@approach.bp_member.human_resource_id)
      @human_resource.human_resource_status_type = 'approached'
      set_user_column @human_resource
      @human_resource.save!

    end
    flash[:notice] = 'Approach was successfully created.'
    redirect_to :controller => 'biz_offer', :action => 'show', :id => @approach.biz_offer
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @approach = Approach.find(params[:id])
    @approached_at_hour = @approach.approached_at.hour
    @approached_at_min = (@approach.approached_at.min / 10) * 10
    @closed_at_hour = @approach.closed_at.hour
    @closed_at_min = (@approach.closed_at.min / 10) * 10
    @approach.approach_upper_contract_term = ContractTerm.find(@approach.approach_upper_contract_term)
    @approach.approach_down_contract_term = ContractTerm.find(@approach.approach_down_contract_term)
    @business = Business.find(@approach.biz_offer.business)
    @bp_member = BpMember.find(@approach.bp_member)
  end

  def update
    Approach.transaction do
      @approach = Approach.find(params[:id], :conditions =>["deleted = 0"])
      @approach.approach_upper_contract_term = ContractTerm.find(@approach.approach_upper_contract_term, :conditions =>["deleted = 0"])
      @approach.approach_down_contract_term = ContractTerm.find(@approach.approach_down_contract_term, :conditions =>["deleted = 0"])
      @approach.attributes = params[:approach]
      @approach.approach_upper_contract_term.attributes = params[:approach_upper_contract_term]
      @approach.approach_down_contract_term.attributes = params[:approach_down_contract_term]
      set_user_column @approach
      set_user_column @approach.approach_upper_contract_term
      set_user_column @approach.approach_down_contract_term

      if date = DateTimeUtil.str_to_date(params[:approach][:approached_at])
        @approach.approached_at = Time.local(date.year, date.month, date.day, params[:approached_at_hour].to_i, params[:approached_at_minute].to_i)
      end

      if date = DateTimeUtil.str_to_date(params[:approach][:closed_at])
        @approach.closed_at = Time.local(date.year, date.month, date.day, params[:closed_at_hour].to_i, params[:closed_at_minute].to_i)
      end

      @approach.save!
      @approach.approach_upper_contract_term.save!
      @approach.approach_down_contract_term.save!
    end
    flash[:notice] = 'Approach was successfully updated.'
    redirect_to(back_to || {:action => 'show', :id => @approach})
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @approach = Approach.find(params[:id], :conditions =>["deleted = 0"])
    @approach.deleted = 9
    @approach.deleted_at = Time.now
    set_user_column @approach
    @approach.save!

    redirect_to :action => 'list'
  end
end
