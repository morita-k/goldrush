# -*- encoding: utf-8 -*-
class DepartmentController < ApplicationController
  before_filter :only_super_user

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @department_pages, @departments = paginate :departments, :per => 10, :conditions => "deleted = 0 "
  end

  def show
    @department = Department.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @department = Department.new
  end

  def create
    @department = create_model(:departments, params[:department])
    if @department.save
      flash[:notice] = 'Department was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @department = Department.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update
    @department = Department.find(params[:id], :conditions => "deleted = 0 ")
    if @department.update_attributes(params[:department])
      flash[:notice] = 'Department was successfully updated.'
      redirect_to :action => 'show', :id => @department
    else
      render :action => 'edit'
    end
  end

  def destroy
    #Department.find(params[:id]).destroy
    department = Department.find(params[:id], :conditions => "deleted = 0 ")
    department.deleted = 9
    department.save!
    redirect_to :action => 'list'
  end
end
