# -*- encoding: utf-8 -*-
class InviteController < ApplicationController
  def index
    redirect_to :action => :list
  end

  def list
    @invites = find_login_owner(:invites).where(:deleted => 0).page(params[:page]).per(50)
  end

  def new
  end

  def create
    if find_login_owner(:users).exists?(:deleted => 0, :email => params[:email])
      raise ValidationAbort.new("メールアドレスのユーザーは既に存在します。")
    end

    ActiveRecord::Base.transaction do
      # 既に招待しているメールアドレスの場合、過去のデータを無効にする
      Invite.delete_old_invitation!(params[:email], current_user.login)

      @invite = create_model(:invites, :email => params[:email])
      @invite.activation_code = @invite.calculate_activation_code
      set_user_column @invite
      @invite.save!

      # メール送信
      Invite.send_invitation_mail(current_user, @invite.email, @invite.activation_code)

      flash[:notice] = 'Invitation mail was successfully sent.'
      redirect_to :controller => '/owner', :action => :list_user
    end
  rescue ActiveRecord::RecordInvalid
    render :action => :new
  rescue ValidationAbort
    flash.now[:err] = $!.to_s
    render :action => :new
  end

  def destroy
    @invite = Invite.find(params[:id], :conditions => {:deleted => 0})
    @invite.deleted = 9
    @invite.deleted_at = Time.now
    set_user_column @invite
    @invite.save!

    flash[:notice] = 'Invite was successfully deleted.'
    redirect_to back_to
  end
end
