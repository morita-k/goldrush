# -*- encoding: utf-8 -*-
class BpPicController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list

    if params[:id].blank?
      condition = ["deleted = 0"]
    else
      condition = ["deleted = 0 and business_partner_id = ?", params[:id]]
      @business_partner = BusinessPartner.find(params[:id])
    end
    @bp_pic_pages, @bp_pics = paginate :bp_pics, :conditions => condition, :per_page => current_user.per_page
  end

  def show
    @bp_pic = BpPic.find(params[:id])
    @remarks = Remark.find(:all, :conditions => ["deleted = 0 and remark_key = ? and remark_target_id = ?", 'bp_pics', params[:id]])
  end

  def new
    @bp_pic = BpPic.new
    business_partner = BusinessPartner.find(params[:business_partner_id])
    @bp_pic.business_partner = business_partner
  end

  def create
    @bp_pic = BpPic.new(params[:bp_pic])
    set_user_column @bp_pic
    @bp_pic.save!
    flash[:notice] = 'BpPic was successfully created.'
    if params[:back_to].blank?
      redirect_to :action => 'list'
    else
      redirect_to params[:back_to]
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @bp_pic = BpPic.find(params[:id])
  end

  def update
    @bp_pic = BpPic.find(params[:id], :conditions =>["deleted = 0"])
    @bp_pic.attributes = params[:bp_pic]
    @bp_pic.bp_pic_name = params[:bp_pic][:bp_pic_name].gsub(/　/," ")
    set_user_column @bp_pic
    @bp_pic.save!
    flash[:notice] = 'BpPic was successfully updated.'
    redirect_to back_to || {:action => 'show', :id => @bp_pic}
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end
  
  def change_star
    bp_pic = BpPic.find(params[:id])
    if bp_pic.starred == 1
      bp_pic.starred = 0
    else
      bp_pic.starred = 1
    end
      set_user_column bp_pic
      bp_pic.save!
    render :text => bp_pic.starred
  end

  def destroy
    @bp_pic = BpPic.find(params[:id], :conditions =>["deleted = 0"])
    @bp_pic.deleted = 9
    @bp_pic.deleted_at = Time.now
    set_user_column @bp_pic
    @bp_pic.save!
    
    redirect_to :action => 'list'
  end
private
  def valid_of_business_partner_id
    if params[:business_partner_id].blank?
      raise ValidationAbort.new("Invalid paramater.[business_partner_id is not null]")
    end
  end
  
  def space_trim(bp_name)
    bp_name_list = bp_name.split(/[\s"　"]/)
    trimed_bp_name = ""
    bp_name_list.each do |bp_name_element|
      trimed_bp_name << bp_name_element
    end
    trimed_bp_name
  end
  
end
