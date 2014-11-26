# -*- encoding: utf-8 -*-
class NameController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @names = Name.where("deleted = 0").page(params[:page]).per(10)
  end

  def show
    @name = Name.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @name = Name.new
  end

  def create
    @name = Name.new(params[:name])
    if @name.save
      flash[:notice] = 'Name was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @name = Name.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update
    @name = Name.find(params[:id], :conditions => "deleted = 0 ")
    if @name.update_attributes(params[:name])
      flash[:notice] = 'Name was successfully updated.'
      redirect_to :action => 'show', :id => @name
    else
      render :action => 'edit'
    end
  end

  def destroy
    #Name.find(params[:id]).destroy
    name = Name.find(params[:id], :conditions => "deleted = 0 ")
    name.deleted = 9
    name.save!
    redirect_to :action => 'list'
  end
end
