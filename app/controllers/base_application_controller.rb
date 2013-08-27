# -*- encoding: utf-8 -*-
class BaseApplicationController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def do_accounting_search
    session[:date_from] = params[:date_from] if params[:date_from]
    session[:date_to] = params[:date_to]  if params[:date_to]
    session[:filter_type] = params[:filter_type]  if params[:filter_type]

    do_list_by_accounting

    render :action => :list_by_accounting
  end

  def set_date_conditions(sql, cond)
    if !session[:date_from].blank?
      sql += " and application_date >= ?"
      cond << session[:date_from]
    end
    if !session[:date_to].blank?
      sql += " and application_date <= ?"
      cond << session[:date_to]
    end
    return sql, cond
  end

  def do_list_by_accounting
    set_data

    case session[:filter_type]
    when 'waiting'
      sql = "base_applications.deleted = 0 and ((application_type in (?) and (payment_per_months.cutoff_status_type = ? or payment_per_cases.cutoff_status_type = ?)) 
            or (application_type = ? and accounting_approval_flg = 1 and expense_applications.payment_flg = 0))
            and base_applications.approval_status_type <> ? "
      cond = [['payment_per_month_app','payment_per_case_app'], session[:filter_type], session[:filter_type], 'expense_app', 'canceled']
      sql, cond = set_date_conditions(sql, cond)
      cond.unshift(sql)
      @base_application_pages, @base_applications = paginate(:base_applications,
        :include => [:payment_per_month, :payment_per_case, :expense_application],
        :per_page => SysConfig.get_per_page_count,
        :conditions => cond,
        :order => 'base_applications.application_date desc, base_applications.id desc')
    when 'closed'
      sql = "base_applications.deleted = 0 and application_type in (?) and (payment_per_months.cutoff_status_type = ? or payment_per_cases.cutoff_status_type = ?)
            and base_applications.approval_status_type <> ? "
      cond = [['payment_per_month_app','payment_per_case_app'], session[:filter_type], session[:filter_type], 'canceled']
      sql, cond = set_date_conditions(sql, cond)
      cond.unshift(sql)
      @base_application_pages, @base_applications = paginate(:base_applications,
        :include => [:payment_per_month, :payment_per_case],
        :per_page => SysConfig.get_per_page_count,
        :conditions => cond,
        :order => 'base_applications.application_date desc, base_applications.id desc')
    when 'paied'
      sql = "base_applications.deleted = 0 and base_applications.application_type = ? and base_applications.accounting_approval_flg = 1 and expense_applications.payment_flg = 1 and base_applications.approval_status_type <> ? "
      cond = ['expense_app', 'canceled']
      sql, cond = set_date_conditions(sql, cond)
      cond.unshift(sql)
      @base_application_pages, @base_applications = paginate(:base_applications,
        :include => [:expense_application],
        :per_page => SysConfig.get_per_page_count,
        :conditions => cond,
        :order => 'base_applications.application_date desc, base_applications.id desc')
    else
      sql = "deleted = 0 and (application_type in (?) or (application_type = ? and accounting_approval_flg = 1))
            and base_applications.approval_status_type <> ? "
      cond = [['payment_per_month_app','payment_per_case_app'], 'expense_app', 'canceled']
      sql, cond = set_date_conditions(sql, cond)
      cond.unshift(sql)
      @base_application_pages, @base_applications = paginate(:base_applications,
        :per_page => SysConfig.get_per_page_count,
        :conditions => cond,
        :order => 'application_date desc, id desc')
    end


  end

  def list_by_accounting
    session_clear

    do_list_by_accounting
  end

  def set_data
    # TODO: 承認者じゃなければエラーとする処理
    set_target_user
    @filter_types = getTypes('approval_status_type').dup.unshift([])
    @calendar = true
    if params[:mode]
      @types = BaseApplication.send("#{params[:mode]}_application_typs")
    end
  end

  def list
    set_data
    #current_month = BaseMonth.get_base_month_by_date
    #last_month = current_month.last_month
    if params[:mode] == 'expense'
      sql = "base_applications.deleted = 0 and base_applications.user_id = ? 
             and base_applications.application_type in (?) and expense_applications.expense_app_type in (?) and base_applications.approval_status_type in (?)"
      incl = [ ]
      cond = [@target_user.id, @types, ['expense_account_app','meeting_expenses_app','material_expenses_app']]
      if session[:filter_type].blank?
        cond << ['entry','retry','approved','reject']
      else
        cond << [session[:filter_type]]
      end
      if !session[:date_from].blank?
        sql += " and base_applications.application_date >= ?"
        cond << session[:date_from]
      end
      if !session[:date_to].blank?
        sql += " and base_applications.application_date <= ?"
        cond << session[:date_to]
      end

      cond.unshift(sql)
      
      @base_application_pages, @base_applications = paginate(:base_applications,
      :per_page => SysConfig.get_per_page_count,
      :include => [:expense_application],
      :conditions => cond,
      :order => 'base_applications.application_date desc')
    else
      sql = "base_applications.deleted = 0 and base_applications.user_id = ? and base_applications.application_type in (?) and base_applications.approval_status_type in (?)"
      incl = [ ]
      cond = [@target_user.id, @types]
      if session[:filter_type].blank?
        cond << ['entry','retry','approved','reject']
      else
        cond << [session[:filter_type]]
      end
      if !session[:date_from].blank?
        sql += " and base_applications.application_date >= ?"
        cond << session[:date_from]
      end
      if !session[:date_to].blank?
        sql += " and base_applications.application_date <= ?"
        cond << session[:date_to]
      end

      cond.unshift(sql)
      
      @base_application_pages, @base_applications = paginate(:base_applications,
      :per_page => SysConfig.get_per_page_count,
      :include => incl,
      :conditions => cond,
      :order => 'base_applications.application_date desc')
    end
  end

  def session_clear
    session[:date_from] = nil
    session[:date_to] = nil
    session[:filter_type] = nil
  end
  
  def working_list
    #params[:mode] = 'working'
    session_clear
    list
  end
  
  
  def expense_list
    params[:mode] = 'expense'
    session_clear
    list
  end

  def do_search
    session[:date_from] = params[:date_from] if params[:date_from]
    session[:date_to] = params[:date_to]  if params[:date_to]
    session[:filter_type] = params[:filter_type]  if params[:filter_type]
    
    if params[:by_approver]
      list_by_approver
    else
      list
    end
    if params[:mode] == 'expense'
      render :action => "#{params[:mode]}_list"
    else
      render :action => "working_list"
    end
  end

  # 承認者が見る申請一覧。自分宛の申請がすべて表示される
  def list_by_approver
    set_data
    #current_month = BaseMonth.get_base_month_by_date
    #last_month = current_month.last_month
    if params[:mode] == 'expense'
      sql = "base_applications.deleted = 0 and application_approvals.approver_id = ?
             and base_applications.application_type in (?) and expense_applications.expense_app_type in (?) and application_approvals.approval_status_type in (?)"
      incl = [:application_approvals, :expense_application]
      cond = [@target_user.id, @types, ['expense_account_app','meeting_expenses_app','material_expenses_app']]
      if session[:filter_type].blank?
#        cond << ['entry', 'retry','approved', 'reject']
        cond << ['entry','retry']
      else
        cond << [session[:filter_type]]
      end
      if !session[:date_from].blank?
        sql += " and base_applications.application_date >= ?"
        cond << session[:date_from]
      end
      if !session[:date_to].blank?
        sql += " and base_applications.application_date <= ?"
        cond << session[:date_to]
      end
      cond.unshift(sql)
      
      @base_application_pages, @base_applications = paginate(:base_applications,
        :per_page => SysConfig.get_per_page_count,
        :include => incl,
        :conditions => cond,
        :order => 'base_applications.application_date desc')
    else
      sql = "base_applications.deleted = 0 and application_approvals.approver_id = ? and base_applications.application_type in (?) and application_approvals.approval_status_type in (?)"
      incl = [:application_approvals]
      cond = [@target_user.id, @types]
      if session[:filter_type].blank?
#        cond << ['entry', 'retry','approved', 'reject']
        cond << ['entry','retry']
      else
        cond << [session[:filter_type]]
      end
      if !session[:date_from].blank?
        sql += " and base_applications.application_date >= ?"
        cond << session[:date_from]
      end
      if !session[:date_to].blank?
        sql += " and base_applications.application_date <= ?"
        cond << session[:date_to]
      end
      cond.unshift(sql)
      
      @base_application_pages, @base_applications = paginate(:base_applications,
        :per_page => SysConfig.get_per_page_count,
        :include => incl,
        :conditions => cond,
        :order => 'base_applications.application_date desc')
    end
  end

  def working_list_by_approver
    #params[:mode] = 'working'
    params[:by_approver] = true
    session_clear
    list_by_approver
    render :action => :working_list
  end

  def expense_list_by_approver
    params[:mode] = 'expense'
    params[:by_approver] = true
    session_clear
    list_by_approver
    render :action => :expense_list
  end

  def cancel
    base_application = BaseApplication.find(params[:id], :conditions => "deleted = 0")
    ActiveRecord::Base.transaction do
      base_application.cancel_application!(current_user.login)
    end
    redirect_to (params[:back_to] || '/')
  end

  def retry
    base_application = BaseApplication.find(params[:id], :conditions => "deleted = 0")
    ActiveRecord::Base.transaction do
      base_application.application_approvals.each do |application_approval|
        application_approval.approval_status_type = 'entry'
        application_approval.approval_date = nil
        set_user_column application_approval
        application_approval.save!
      end
      base_application.approval_status_type = 'retry'
      base_application.approval_date = nil
      set_user_column base_application
      base_application.save!
    end
    flash[:notice] = 'ステータスを再申請に変更しました'
    redirect_to :controller => params[:redirect_controller], :action => 'edit', :id => params[:redirect_id], :back_to => params[:back_to]
#    redirect_to (params[:back_to] || '/')
  end

  def payment
    base_application_id = nil
    cutoff_date = nil
    params.each_key{|key|
      if /^btn_date_(\d+)$/ =~ key
        base_application_id = $1
        cutoff_date = params["date_#{$1}"]
        break
      end
    }
    unless (base_application_id && cutoff_date)
      flash[:err] = 'パラメータが不正です'
      redirect_to params[:back_to]
      return
    end
    begin
      cutoff_date.to_date
    rescue
      flash[:err] = 'パラメータが不正です'
      redirect_to params[:back_to]
      return
    end
    base_application = BaseApplication.find(base_application_id, :conditions => "deleted = 0")
    case base_application.application_type
      when 'payment_per_month_app'
        redirect_to :controller => :expense_detail, :action => :cutoff_month, :id => base_application.payment_per_month, :paid_date => cutoff_date, :back_to => params[:back_to]
        return
      when 'payment_per_case_app'
        redirect_to :controller => :expense_detail, :action => :cutoff_case, :id => base_application.payment_per_case, :paid_date => cutoff_date, :back_to => params[:back_to]
        return
      when 'expense_app'
        redirect_to :controller => :expense_application, :action => :fix_payment, :id => base_application.expense_application, :paid_date => cutoff_date, :back_to => params[:back_to]
        return
    end

    flash[:err] = '不明のエラーです'
    redirect_to params[:back_to]
  end

end
