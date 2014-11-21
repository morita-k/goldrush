# -*- encoding: utf-8 -*-
class Auth::ConfirmationsController < Devise::ConfirmationsController
  def show
    super
    # 他にパラメータを渡す手段がなさそうなので、やむなくflashで渡している。
    flash[:first_confirmation] = true if resource.errors.empty?
  end

protected
  # override
  # see https://github.com/plataformatec/devise/blob/master/app/controllers/devise/confirmations_controller.rb 
  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      url_for :controller => '/help', :action => 'index'
    else
      new_session_path(resource_name)
    end
  end
end
