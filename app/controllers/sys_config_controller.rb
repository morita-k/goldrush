# -*- encoding: utf-8 -*-
class SysConfigController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @sys_config_pages, @sys_configs = paginate :sys_configs, :per_page => 100, :conditions => "deleted = 0 ", :order => "id"
  end

  def show
    @sys_config = SysConfig.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @sys_config = SysConfig.new
  end

  def create
    @sys_config = SysConfig.new(params[:sys_config])
    if @sys_config.save
      flash[:notice] = 'SysConfig was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @sys_config = SysConfig.find(params[:id], :conditions => "deleted = 0 ")
  end

  def edit_sv
  end

  def update
    @sys_config = SysConfig.find(params[:id], :conditions => "deleted = 0 ")
    if @sys_config.update_attributes(params[:sys_config])
      flash[:notice] = 'SysConfig was successfully updated.'
      redirect_to :action => 'show', :id => @sys_config
    else
      render :action => 'edit'
    end
  end

  def destroy
    #SysConfig.find(params[:id]).destroy
    sys_config = SysConfig.find(params[:id], :conditions => "deleted = 0 ")
    sys_config.deleted = 9
    sys_config.deleted_at = Time.now
    sys_config.save!
    redirect_to :action => 'list'
  end
end
