# -*- encoding: utf-8 -*-
require 'pop3_client'

class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_auth!
  before_filter :api_auth_required, :except => [:error]

  def api_auth_required
    api_login = SysConfig.get_api_login
    if logged_in?
      return true
    elsif params[:login] == api_login.value1 && params[:password] == api_login.value2
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

  def jsontest
    render :json => {"a" => 123, "b" => 222}
  end

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
    ImportMail.analyze_all

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
  
  def bounce_mail_report
    recipient = params[:recipient]
    reason = params[:reason]
    
    if recipient && reason
      ActiveRecord::Base.transaction do
        bp_pics = BpPic.where(:email1 => recipient)
        bp_pics.each do |pic|
          pic.nondelivery_score += BpPic.score_nondelivery(reason)
          pic.save!
        end
      end
    end
    render :text => 'REQUEST OK!'
  end
  
  def worksheets
    render :json => BaseMonth.where("deleted = 0 and start_date = ?", params[:start_date]).first.monthly_workings.map{|m|
      {
        :employee_name => m.user.employee.employee_name,
        :total_hour => m.real_working_hour_count,
        :working_list => m.daily_workings.map{|w|
          {
            :working_date => w.working_date,
            :working_type => w.working_type_short_name,
            :in_time => w.in_time_format,
            :out_time => w.out_time_format,
            :summary => w.summary,
            :hour_total => w.hour_total_format,
            :rest_hour => w.rest_hour_format
          }
        }
      }
    }
  end

  def import_photo
    src = params[:attachment]
    sender = params[:sender]
    Photo.import_photo(src, sender)
    render :text => 'REQUEST OK!'
  end

  def close_contracts
    if params[:date]
      Contract.close_contracts(params[:date].to_date)
    else
      Contract.close_contracts
    end

    if params[:back_to]
      redirect_to params[:back_to]
    else
      render :text => 'REQUEST OK!'
    end
  end

  def make_next_contracts
    if params[:date]
      Contract.make_next(params[:date].to_date)
    else
      Contract.make_next
    end

    if params[:back_to]
      redirect_to params[:back_to]
    else
      render :text => 'REQUEST OK!'
    end
  end

end
