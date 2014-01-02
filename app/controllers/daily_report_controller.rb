# -*- encoding: utf-8 -*-
class DailyReportController < ApplicationController

  def list
    set_target_user
    set_date

    current_date = Date.parse(@target_date + '-01')
    @preview_date = current_date.prev_month.strftime('%Y-%m')
    @next_date = current_date.next_month.strftime('%Y-%m')

    @target_daily_reports = DailyReport.get_daily_report(@target_date, @target_user.id)
  end

  def update
    update_data = params[:target_daily_report]
    target_date = params[:date]

    DailyReport.update_daily_report(update_data)

    flash[:notice] = '日報を更新しました。'

    redirect_to :action => 'list', :date => target_date
  end

  def summary
    session[:daily_report_summary] ||= {}
    set_date

    @target_user = DailyReport.get_distinct_user

    if params[:clear_button]
      session[:daily_report_summary] = {}
      redirect_to
      return false
    else
      set_conditions
      @target_summary = DailyReport.get_summary_report(session[:daily_report_summary], @target_date)

      if session[:daily_report_summary][:summary_method_flg] == 'individual'
        @target_summary_individual = get_summary_individual
      end

      set_around_date
    end
  end

  def set_conditions
    session[:daily_report_summary] = {
        :summary_term_flg => params[:summary_term_flg],
        :summary_target_flg => params[:summary_target_flg],
        :summary_method_flg => params[:summary_method_flg],
    }
  end

  def get_summary_individual
    target_summary_individuals = Array.new

    @target_user.each do |target_user|
      target_summary_individual = Hash.new

      target_summary_individual[:user_id] = target_user.id
      target_summary_individual[:user_name] = target_user.employee.employee_name
      target_summary_individual[:target_summary_report] = Array.new

      target_summary_individuals.push(target_summary_individual)
    end

    @target_summary.each do |target_summary|
      target_summary_individuals.each do |target_summary_individual|
        if target_summary_individual[:user_id] == target_summary["user_id"]
          target_summary_individual[:target_summary_report].push(target_summary)
          break
        end
      end
    end

    target_summary_individuals
  end

  def set_date
    @target_date = params[:date]
    if @target_date.nil?
      @target_date = Date.today.strftime('%Y-%m')
    end
  end

  def set_around_date
    current_date = Date.parse(@target_date + '-01')

    if session[:daily_report_summary][:summary_term_flg] == 'month'
      @preview_date = current_date.prev_year.strftime('%Y-%m')
      @next_date = current_date.next_year.strftime('%Y-%m')
      @target_date_string = '年'
    else
      @preview_date = current_date.prev_month.strftime('%Y-%m')
      @next_date = current_date.next_month.strftime('%Y-%m')
      @target_date_string = '月'
    end
  end
end