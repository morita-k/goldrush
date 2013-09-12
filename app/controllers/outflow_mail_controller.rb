# -*- encoding: utf-8 -*-
class OutflowMailController < ApplicationController

  def list
  	@outflow_mails = OutflowMail.where(deleted: 0)
  end

  def quick_input
    params[:page] ||= "1"

    @outflow_mail ||= OutflowMail.where(deleted: 0).first

    @target_data = {:emptyFlag => true, :targetName => ''}
    if @outflow_mail.nil?
      @target_data[:emptyFlag] = true
    else
      @target_data[:emptyFlag] = false
      @target_data[:targetName] = :outflow_mail
    end

    render template: 'business_partner/quick_input', layout: 'blank'
  end
end