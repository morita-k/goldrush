# -*- encoding: utf-8 -*-
class BusinessController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def set_conditions
    session[:business_search] = {
      :business_status_type => params[:business_status_type],
      :business_title => params[:business_title],
      :place => params[:place],
      :period => params[:period],
      :phase => params[:phase],
      :need_count => params[:need_count],
      :skill_must => params[:skill_must],
      :skill_want => params[:skill_want],
      :age_limit => params[:age_limit]
      }
  end

  def make_conditions
    param = []
    include = []
    sql = "businesses.deleted = 0"
    order_by = ""

    if !(business_status_type = session[:business_search][:business_status_type]).blank?
      sql += " and business_status_type = ?"
      param << business_status_type
    end

    if !(business_title = session[:business_search][:business_title]).blank?
      sql += " and business_title like ?"
      param << "%#{business_title}%"
    end

    if !(place = session[:business_search][:place]).blank?
      sql += " and place = ?"
      param << place
    end

    if !(period = session[:business_search][:period]).blank?
      sql += " and period = ?"
      param << period
    end

    if !(phase = session[:business_search][:phase]).blank?
      sql += " and phase = ?"
      param << phase
    end

    if !(need_count = session[:business_search][:need_count]).blank?
      sql += " and need_count = ?"
      param << need_count
    end

    if !(skill_must = session[:business_search][:skill_must]).blank?
      sql += " and skill_must = ?"
      param << skill_must
    end

    if !(skill_want = session[:business_search][:skill_want]).blank?
      sql += " and skill_want = ?"
      param << skill_want
    end

    if !(age_limit = session[:business_search][:age_limit]).blank?
      sql += " and age_limit = ?"
      param << age_limit
    end

    return {:conditions => param.unshift(sql), :include => include, :per => current_user.per_page}
  end


  def list
    session[:business_search] ||= {}
    if request.post?
      if params[:search_button]
        set_conditions
      elsif params[:clear_button]
        session[:business_search] = {}
      end
    end
    cond = make_conditions
    @business_pages, @businesses = paginate(:businesses, cond)
  end

  def show
    @business = Business.find(params[:id])
  end

  def new
    @business = Business.new
  end

  def create
    Business.transaction {
      @business = create_model(:businesses, params[:business])
      set_user_column @business
      @business.save!
      @biz_offer = @business.biz_offers.build
      @biz_offer.owner_id = @business.owner_id
      @biz_offer.business_partner_id = @business.eubp_id
      @biz_offer.bp_pic_id = @business.eubp_pic_id
      @biz_offer.biz_offered_at = Time.now
      @biz_offer.biz_offer_status_type = 'pending'
      set_user_column @biz_offer
      @biz_offer.save!
    }
    flash[:notice] = 'Business was successfully created.'
    redirect_to :action => 'list'
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @business = Business.find(params[:id])
  end

  def update
    @business = Business.find(params[:id], :conditions =>["deleted = 0"])
    @business.attributes = params[:business]
    set_user_column @business
    @business.save!
    flash[:notice] = 'Business was successfully updated.'
    redirect_to :action => 'show', :id => @business
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @business = Business.find(params[:id], :conditions =>["deleted = 0"])
    @business.deleted = 9
    @business.deleted_at = Time.now
    set_user_column @business
    @business.save!
    
    redirect_to :action => 'list'
  end
  
    def change_star
    business = Business.find(params[:id])
    if business.starred == 1
      business.starred = 0
    else
      business.starred = 1
    end
      set_user_column business
      business.save!
    render :text => business.starred
  end
end
