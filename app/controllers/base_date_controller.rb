# -*- encoding: utf-8 -*-
class BaseDateController < ApplicationController
  before_filter :only_super_user

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @base_dates = BaseDate.where("holiday_flg = 1").order('calendar_date DESC').page(params[:page]).per(30)
  end

  def show
    @base_date = BaseDate.find(params[:id])
  end

  def new
    @calendar = true
    @base_date = BaseDate.new
  end

  def create_holiday
    @base_date = BaseDate.find(:first, :conditions => ["deleted = 0 and calendar_date = ?", params[:base_date][:calendar_date]])
    @base_date.comment1 = params[:base_date][:comment1]
    @base_date.holiday_flg = 1
    @base_date.save!
    flash[:notice] = '祝日を作成しました。'
    redirect_to :action => 'list'

  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

#  def create_holiday
#    @base_date = BaseDate.find(:first, :conditions => ["deleted = 0 and calendar_date = ?", params[:base_date][:calendar_date]])
#    @base_date.comment1 = params[:base_date][:comment1]
#    @base_date.holiday_flg = 1
#    if @base_date.save!
#      flash[:notice] = 'BaseDate was successfully updated.'
#      redirect_to :action => 'list'
#    else
#      render :action => 'new'
#    end
#  end

  def create
    @base_date = BaseDate.new(params[:base_date])
    if @base_date.save
      flash[:notice] = 'BaseDate was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @base_date = BaseDate.find(params[:id])
  end

  def update
    parseTimes(params)
    @base_date = BaseDate.find(params[:id])
    if @base_date.update_attributes(params[:base_date])
      flash[:notice] = 'BaseDate was successfully updated.'
      redirect_to :action => 'show', :id => @base_date
    else
      render :action => 'edit'
    end
  end

  def destroy_holiday
    #BaseDate.find(params[:id]).destroy
    base_date = BaseDate.find(params[:id], :conditions => "deleted = 0 ")
    base_date.holiday_flg = 0
    base_date.comment1 = ''
    base_date.save!
    redirect_to :action => 'list'
  end

  def destroy
    #BaseDate.find(params[:id]).destroy
    base_date = BaseDate.find(params[:id], :conditions => "deleted = 0 ")
    base_date.deleted = 9
    base_date.save!
    redirect_to :action => 'list'
  end
end
