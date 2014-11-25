# -*- encoding: utf-8 -*-
class HelpController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_auth!

  def index
    @first_confirmation = flash[:first_confirmation].present?
    @application_name = SysConfig.get_application_name
    @contact_address = SysConfig.get_contact_address
  end

  def terms
    @application_name = SysConfig.get_application_name
    @contact_address = SysConfig.get_contact_address
    render :action => 'terms'
  end

  def privacy
    @application_name = SysConfig.get_application_name
    @contact_address = SysConfig.get_contact_address
    render :action => 'privacy'
  end
end
