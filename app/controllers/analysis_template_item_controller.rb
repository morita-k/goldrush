# -*- encoding: utf-8 -*-
class AnalysisTemplateItemController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @analysis_template_item_pages, @analysis_template_items = paginate :analysis_template_items, :conditions =>["deleted = 0"], :per => current_user.per_page
  end

  def show
    @analysis_template_item = AnalysisTemplateItem.find(params[:id])
  end

  def new
    @analysis_template_item = AnalysisTemplateItem.new
    @analysis_template_item.analysis_template_id = params[:id]
  end

  def create
    @analysis_template_item = create_model(:analysis_template_items, params[:analysis_template_item])
    set_user_column @analysis_template_item
    @analysis_template_item.save!
    flash[:notice] = 'AnalysisTemplateItem was successfully created.'
    redirect_to(back_to || {:controller => 'analysis_template', :action => 'show', :id => @analysis_template_item.analysis_template_id})
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @analysis_template_item = AnalysisTemplateItem.find(params[:id])
  end

  def update
    @analysis_template_item = AnalysisTemplateItem.find(params[:id], :conditions =>["deleted = 0"])
    @analysis_template_item.attributes = params[:analysis_template_item]
    set_user_column @analysis_template_item
    @analysis_template_item.save!
    flash[:notice] = 'AnalysisTemplateItem was successfully updated.'
    redirect_to(back_to || {:controller => 'analysis_template', :action => 'show', :id => @analysis_template_item.analysis_template_id})
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @analysis_template_item = AnalysisTemplateItem.find(params[:id], :conditions =>["deleted = 0"])
    @analysis_template_item.deleted = 9
    @analysis_template_item.deleted_at = Time.now
    set_user_column @analysis_template_item
    @analysis_template_item.save!
    redirect_to :controller => 'analysis_template', :action => 'show', :id => @analysis_template_item.analysis_template_id
  end
end
