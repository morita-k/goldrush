# -*- encoding: utf-8 -*-
class OwnerController < ApplicationController
  def list_user
    @users = find_login_owner(:users).where(deleted: 0).page(params[:page]).per(10)
    @invites = find_login_owner(:invites).where(deleted: 0)

    render action: :list_user
  end

  def edit
    @owner = Owner.find(params[:id], :conditions => {:deleted => 0})
  end

  def update
    @owner = Owner.find(params[:id], :conditions => {:deleted => 0})
    @owner.attributes = params[:owner]
    @owner.change_smtp_mode(params[:advanced_smtp_mode])
    set_user_column @owner

    ActiveRecord::Base.transaction do
      @owner.save!
      flash[:notice] = 'Owner was successfully updated.'
      redirect_to root_path
    end
  rescue ActiveRecord::RecordInvalid
    render :action => :edit
  end
end
