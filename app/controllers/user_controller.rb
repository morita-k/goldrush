# -*- encoding: utf-8 -*-
class UserController < ApplicationController
  before_filter :only_manager, :only => [:change_access_level, :destroy]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @user_pages, @users = paginate(:users, :per => 50, :conditions => "deleted = 0 and access_level_type <> 'super'")

    if params[:popup] && params[:mode].blank?
      flash[:warning] = 'ポップアップのパラメータが不正です'
    end
  end

  def fixmessage
    session[:msgids] ||= ""
    session[:msgids] = (session[:msgids].split(",") << params[:id]).uniq.join(",")
    respond_to do |format|
      format.js {render :text => ";"}
    end
  end

  def change_access_level
    # ここでシステム管理者になることはないので、'super'が来たらスキップ
    if params[:access_level_type] != 'super'
      @user = User.find(params[:id], :conditions => {:deleted => 0})
      @user.access_level_type = params[:access_level_type]
      set_user_column @user
      @user.save!
    end
    flash[:notice] = 'User access level was successfully updated.'
    redirect_to back_to
  end

  def destroy
    @user = User.find(params[:id], :conditions => {:deleted => 0})
    @user.deleted = 9
    @user.deleted_at = Time.now
    set_user_column @user
    @user.save!

    flash[:notice] = 'User was successfully deleted.'
    redirect_to back_to
  end
end
