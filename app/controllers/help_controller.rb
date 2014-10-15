# -*- encoding: utf-8 -*-
class HelpController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_auth!

  def index
    #@application_name = SysConfig.application_name
    #@contact_address = SysConfig.contact_address
    @first_confirmation = flash[:first_confirmation].present?
  end

  def terms
    #@application_name = SysConfig.application_name
    #@contact_address = SysConfig.contact_address
    render :action => 'terms'
  end

  def privacy
    #@application_name = SysConfig.application_name
    #@contact_address = SysConfig.contact_address
    render :action => 'privacy'
  end
end
