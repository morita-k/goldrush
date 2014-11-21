# -*- encoding: utf-8 -*-
class InterviewController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @interview_pages, @interviews = paginate :interviews, :conditions =>["deleted = 0"], :per => current_user.per_page
  end

  def show
    @interview = Interview.find(params[:id])
  end

  def new
    @calendar = true
    if params[:interview_end]
      redirect_to :controller => 'approach', :action => 'show', :id => params[:interview][:approach_id]
    end
    @interview = Interview.new
    @interview.interview_appoint_at = Date.today
    @interview_appoint_at_hour = Time.new.hour
    @interview_appoint_at_min = (Time.new.min / 10) * 10
  end

  def create
    @calendar = true
    @interview = create_model(:interviews, params[:interview])
    
    if date = DateTimeUtil.str_to_date(params[:interview][:interview_appoint_at])
      @interview.interview_appoint_at = Time.local(date.year, date.month, date.day, params[:interview_appoint_at_hour].to_i, params[:interview_appoint_at_minute].to_i)
    end
    
    last_number = Interview.find(:first, :conditions => ["deleted = 0 and approach_id = ?", @interview.approach_id], :order => 'interview_number desc')
    @interview.interview_number = (last_number && last_number.interview_number.to_i + 1) || 1
    @interview.interview_status_type = 'interview_waiting'
    
    set_user_column @interview
    @interview.save!
    flash[:notice] = 'Interview was successfully created.'
    redirect_to :controller => 'approach', :action => 'show', :id => @interview.approach_id
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @calendar = true
    @interview = Interview.find(params[:id])
    @interview_appoint_at_hour = @interview.interview_appoint_at.hour
    @interview_appoint_at_min = (@interview.interview_appoint_at.min / 10) * 10
  end

  def update
    @calendar = true
    @interview = Interview.find(params[:id], :conditions =>["deleted = 0"])
    @interview.attributes = params[:interview]
    set_user_column @interview
    
    if date = DateTimeUtil.str_to_date(params[:interview][:interview_appoint_at])
      @interview.interview_appoint_at = Time.local(date.year, date.month, date.day, params[:interview_appoint_at_hour].to_i, params[:interview_appoint_at_minute].to_i)
    end
    
    @interview.save!
    flash[:notice] = 'Interview was successfully updated.'
    redirect_to :controller => 'approach', :action => 'show', :id => @interview.approach_id
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @interview = Interview.find(params[:id], :conditions =>["deleted = 0"])
    approach = @interview.approach_id
    @interview.deleted = 9
    @interview.deleted_at = Time.now
    set_user_column @interview
    @interview.save!
    
    redirect_to :controller => 'approach', :action => 'show', :id => approach
  end
end
