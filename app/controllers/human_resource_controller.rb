# -*- encoding: utf-8 -*-
class HumanResourceController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @human_resource_pages, @human_resources = paginate :human_resources, :conditions =>["deleted = 0"], :per => current_user.per_page
  end

  def show
    @human_resource = HumanResource.find(params[:id])
  end

  def new
    @calendar = true
    @human_resource = HumanResource.new
  end

  def create
    @human_resource = create_model(:human_resources, params[:human_resource])
    set_user_column @human_resource
    @human_resource.save!
    flash[:notice] = 'HumanResource was successfully created.'
    redirect_to :action => 'list'
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @calendar = true
    @human_resource = HumanResource.find(params[:id])
  end

  def update
    @human_resource = HumanResource.find(params[:id], :conditions =>["deleted = 0"])
    @human_resource.attributes = params[:human_resource]
    set_user_column @human_resource
    @human_resource.save!
    flash[:notice] = 'HumanResource was successfully updated.'
    redirect_to :action => 'show', :id => @human_resource
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @human_resource = HumanResource.find(params[:id], :conditions =>["deleted = 0"])
    @human_resource.deleted = 9
    @human_resource.deleted_at = Time.now
    set_user_column @human_resource
    @human_resource.save!
    
    redirect_to :action => 'list'
  end
  
  def change_star
    puts '<<<<<<<<<< human_resource #{params[:id]}'
    human_resource = HumanResource.find(params[:id])
    if human_resource.starred == 1
      human_resource.starred = 0
    else
      human_resource.starred = 1
    end
      set_user_column human_resource
      human_resource.save!
    render :text => human_resource.starred
  end
end
