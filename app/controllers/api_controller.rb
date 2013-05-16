# -*- encoding: utf-8 -*-
require 'pop3_client'

class ApiController < ApplicationController
  skip_before_filter :authenticate_auth!
  before_filter :api_auth_required, :except => [:error]

  def api_auth_required
    if logged_in?
      return true
    elsif params[:login] == 'goldrush' && params[:password] == 'furuponpon'
      return true
    else
      redirect_to :action => :error
      return false
    end
  end

  def error
    render :text => 'REQUEST ERROR!!'
  end

  #-----------------------------------------------------------------------------
  # API Start
  #-----------------------------------------------------------------------------

  def import_mail_pop3
    ImportMail.import
    if params[:back_to]
      redirect_to params[:back_to]
    else
      render :text => 'REQUEST OK!'
    end
  end
  
  def import_mail
    src = params[:mail]
    ImportMail.import_mail(Mail.new(src), src)
    render :text => 'REQUEST OK!'
  end
  
  def broadcast_mail
    DeliveryMail.send_mails
    
    render :text => 'REQUEST OK!'
  end

  def analyze_tags
    ImportMail.analyze_tags

    if params[:back_to]
      redirect_to params[:back_to], :notice => "Analyze tags successfully finished."
    else
      render :text => 'REQUEST OK!'
    end
  end

  def summry_tags
    TagJournal.summry_tags!

    if params[:back_to]
      redirect_to params[:back_to]
    else
      render :text => 'REQUEST OK!'
    end
  end

end
