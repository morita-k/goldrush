# -*- encoding: utf-8 -*-
class TypeController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @types = Type.where("deleted = 0").order("type_section, display_order1").page(params[:page]).per(100)
  end

  def show
    @type = Type.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @type = Type.new
  end

  def create
    @type = Type.new(params[:type])
    if @type.save
      flash[:notice] = 'Type was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @type = Type.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update
    @type = Type.find(params[:id], :conditions => "deleted = 0 ")
    if @type.update_attributes(params[:type])
      flash[:notice] = 'Type was successfully updated.'
      redirect_to :action => 'show', :id => @type
    else
      render :action => 'edit'
    end
  end

  def destroy
    #Type.find(params[:id]).destroy
    type = Type.find(params[:id], :conditions => "deleted = 0 ")
    type.deleted = 9
    type.save!
    redirect_to :action => 'list'
  end
end
