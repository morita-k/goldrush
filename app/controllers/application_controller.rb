# -*- encoding: utf-8 -*-
#require 'gettext/rails'

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :authenticate_auth!
  before_filter :set_gettext_locale
  before_filter :check_popup_mode
  protect_from_forgery
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
#  protect_from_forgery :secret => '7d7e4d4f90a4b9c8127ea2ef0a6f8edd'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

#  init_gettext "gxt"

  include NameUtil
  include TypeUtil

#  include AuthenticatedSystem

  # connect to the external database.
#  ExternalDbModel.establish_connection CbroboConnection.configurations['external_' + (ENV['RAILS_ENV'] || 'development').to_s]

  # Pick a unique cookie name to distinguish our session data from others'
#  session :session_key => "_#{ActiveRecord::Base.configurations[RAILS_ENV]['database']}_session_id"
#  session :secret      => 'e9ed3a2358afe17d5e0f36a8418caa1158a02502a80ca539678a2be2ab86a4088a406dc'
#  before_filter :login_required  

  def current_user
    current_auth
  end

  def logged_in?
    auth_signed_in?
  end

  def self.verify(param)
    #dummy
  end 

  def paginate(table_name, param_map)
    [[], eval(table_name.to_s.classify).select(param_map[:select]).includes(param_map[:include]).where(param_map[:conditions]).order(param_map[:order]).page(params[:page]).per(param_map[:per])]
  end

  def rescue_action_in_public(exception)
    case exception
      when ValidationAbort
        flash[:err] = exception.message
        redirect_to :controller => '/'
      when ::ActiveRecord::StaleObjectError
        flash[:err] = '対象のデータは、同時に更新されようとしました。恐れ入りますが、最初からやり直してください。'
        redirect_to :controller => '/'
      else
        super
    end
  end

  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  def rescue_action_locally(exception)
    case exception
      when ValidationAbort
        flash[:err] = exception.message
        redirect_to :controller => '/'
        super
      when ::ActiveRecord::StaleObjectError
        flash[:err] = '対象のデータは、同時に更新されようとしました。恐れ入りますが、最初からやり直してください。'
        redirect_to :controller => '/'
      else
        super
    end
  end

  def parseCurrency(_params, &block)
    _params.each{|k,v|
      next if v.blank?
      if v.is_a? Hash
        parseCurrency v, &block
        next
      end
      if k.match(/_amount$/) or k.match('amount') or (block_given? && block.call(k))
        _params[k] = v.to_s.delete("^0-9.").to_f
      end
    }
  end

  def parseTimes(_params, &block)
    _params.each{|k,v|
      next if v.blank?
      if v.is_a? Hash
        parseTimes v, &block
        next
      end
      if k.match(/_at$/)
        _params[k] = DateTime.parse(v.to_s)
      end
      if k.match(/_on$/)
        _params[k] = DateTime.parse(v.to_s)
      end
      if k.match(/_date$/)
        _params[k] = DateTime.parse(v.to_s)
      end
      if block_given? && block.call(k)
        _params[k] = DateTime.parse(v.to_s)
      end
    }
  end

  def back_to
    params[:back_to]
  end

  def _redirect_or_back_to(option)
    if !params[:back_to].blank?
      redirect_to params[:back_to]
    elsif request.env["HTTP_REFERER"] =~ /#{url_for(:only_path => false, :controller => '/')}/ #'
      redirect_to :back
    else
      redirect_to option
    end
  end

  def set_user_column(model, default_user = 'default_user')
    if logged_in?
      model.created_user = current_user.login if model.new_record?
      model.updated_user = current_user.login
    else
      model.created_user = default_user if model.new_record?
      model.updated_user = default_user
    end
  end

  def check_popup_mode
    @popup_mode = params[:popup]
  end

=begin
  def method_missing(method_symbol, *parameters)
    unless method_symbol.to_s.match(/^popup_(.*)/)
      raise UnknownAction, "No action responded to #{action_name}", caller
    end
    unless respond_to?($1)
      raise UnknownAction, "No action responded to #{action_name}", caller
    end
    @popup_mode = true
    send $1
    render :action => $1, :layout => 'popup' unless performed?
  end
=end
  def check_datetime_field(paramater, model)
   paramater.each do |key,val|
      if key =~ /_at$/
        time_key = "#{model.class.name.tableize.singularize}_#{key}_time"
        if at = DateTimeUtil.str_to_datetime("#{paramater[key]} #{params[time_key]}")
          paramater[key] = at
        else
          model.errors.add(key, _("A format of time is not good."))
          raise ActiveRecord::RecordInvalid.new(model)
        end
      end # if key
    end # each
  end

  def j(str)
    str.gsub("'", "\\\\'")
  end
  
  def popup?
    @popup_mode
  end

  def set_target_user
    if target_user_id = params[:user_id]
      @target_user = User.find(target_user_id, :conditions => "deleted = 0")
    else
      @target_user = current_user
    end
    @target_employee = @target_user.employee
  end
end
