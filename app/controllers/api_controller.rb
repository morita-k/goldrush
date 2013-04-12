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

  # SESî•ñƒ[ƒ‹‚ðŽæ‚èž‚Þˆ—‚ðŒÄ‚Ño‚·
  def import_mail_pop3
    ImportMail.import
    render :text => 'REQUEST OK!'
  end
  
  # ƒ[ƒ‹Žæ‚èž‚Ý‹@”\
  #   POSTFIX‚È‚Ç‚ð—˜—p‚µ‚Äƒ[ƒ‹ƒeƒLƒXƒg‚ðPOST‚µ‚Ä‚à‚ç‚¤
  def import_mail
    src = params[:mail]
    # ƒ[ƒ‹ƒeƒLƒXƒg
    ImportMail.import_mail(Mail.new(src), src)
    render :text => 'REQUEST OK!'
  end
  
  def broadcast_mail
    DeliveryMail.send_mails
    
    render :text => 'REQUEST OK!'
  end

end
