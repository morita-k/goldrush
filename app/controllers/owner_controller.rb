# -*- encoding: utf-8 -*-
class OwnerController < ApplicationController
  before_filter :only_super_user, :only => [:index, :list, :change_current_owner, :destroy]
  before_filter :only_manager, :only => [:list_user, :edit, :update]

  def index
    list
    render :action => :list
  end

  def list
    @owners = Owner.where(deleted: 0).page(params[:page]).per(current_user.per_page)
  end

  def list_user
    @users = find_login_owner(:users).where("deleted=0 and access_level_type<>'super'").page(params[:page]).per(10)
    @invites = find_login_owner(:invites).where(deleted: 0)

    render action: :list_user
  end

  def change_current_owner
    @owner = Owner.find(params[:id], :conditions => {:deleted => 0})
    current_user.update_attributes!(:owner_id => @owner.id)
    flash[:notice] = 'Owner of current user was successfully changed.'
    redirect_to back_to
  end

  def edit
    @owner = Owner.find(params[:id], :conditions => {:deleted => 0})
  end

  def update
    @owner = Owner.find(params[:id], :conditions => {:deleted => 0})
    @owner.attributes = params[:owner]
    @owner.change_smtp_mode(params[:advanced_smtp_mode]) if current_user.super?
    set_user_column @owner

    ActiveRecord::Base.transaction do
      @owner.save!
      flash[:notice] = 'Owner was successfully updated.'
      redirect_to root_path
    end
  rescue ActiveRecord::RecordInvalid
    render :action => :edit
  end

  def destroy
    @owner = Owner.find(params[:id], :conditions => {:deleted => 0})
    ActiveRecord::Base.transaction do
      Owner.delete_owner(@owner.id, current_user.login)
    end
    flash[:notice] = 'Owner was successfully deleted.'
    redirect_to back_to
  end
end
