# -*- encoding: utf-8 -*-
class BaseMonthController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @base_months = BaseMonth.where("delete = 0").order("start_date").page(params[:page]).per(50)
  end

  def show
    @base_month = BaseMonth.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @base_month = BaseMonth.new
  end

  def create
    @base_month = BaseMonth.new(params[:base_month])
    set_user_column @base_month
    if @base_month.save
      flash[:notice] = 'BaseMonth was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @base_month = BaseMonth.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update
    @base_month = BaseMonth.find(params[:id], :conditions => "deleted = 0 ")
    set_user_column @base_month
    if @base_month.update_attributes(params[:base_month])
      flash[:notice] = 'BaseMonth was successfully updated.'
      redirect_to :action => 'show', :id => @base_month
    else
      render :action => 'edit'
    end
  end

  def destroy
    #BaseMonth.find(params[:id]).destroy
    base_month = BaseMonth.find(params[:id], :conditions => "deleted = 0 ")
    base_month.deleted = 9
    set_user_column base_month
    base_month.save!
    redirect_to :action => 'list'
  end
end
