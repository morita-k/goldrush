# -*- encoding: utf-8 -*-
class VacationController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @vacation_pages, @vacations = paginate :vacations, :per_page => SysConfig.get_per_page_count, :conditions => "deleted = 0 "
  end

  def list_sv
    @calendar = true
    @start_date = SysConfig.get_summer_vacation_start_date.value1
    @end_date = SysConfig.get_summer_vacation_end_date.value1

    @vacation_pages, @vacations = paginate(:vacations, :per_page => SysConfig.get_per_page_count, :conditions => "deleted = 0 ", :order => 'id')
    @user_pages, @users = paginate(:users, :include => [:employee], :per_page => SysConfig.get_per_page_count, :conditions => "users.deleted = 0 ", :order => 'employees.insurance_code')
  end

  def annual_vacation
    @calculate_vacation_year = SysConfig.get_calculate_vacation_year
    cur_year = Date.today.year
    @arr_year = [
              [cur_year - 2, cur_year - 2],
              [cur_year - 1, cur_year - 1],
              [cur_year, cur_year],
              [cur_year + 1, cur_year + 1],
              [cur_year + 2, cur_year + 2],
                ]
  end

  def calculate_vacation
    @calculate_vacation_year = SysConfig.get_calculate_vacation_year
    @calculate_vacation_year.value1 = params[:calculate_vacation]
    set_user_column @calculate_vacation_year
    @calculate_vacation_year.save!

    year = SysConfig.get_calculate_vacation_year.value1
    Vacation.calculate_vacations(year)

    redirect_to :action => 'annual_vacation'
  end

  def show
    @vacation = Vacation.find(params[:id], :conditions => "deleted = 0 ")
  end

  def new
    @vacation = Vacation.new
  end

  def create
    @vacation = Vacation.new(params[:vacation])
    @vacation.user_id = current_user.id
    if @vacation.save
      flash[:notice] = 'Vacation was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @vacation = Vacation.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update
    @vacation = Vacation.find(params[:id], :conditions => "deleted = 0 ")
src_used_total = @vacation.used_total
    @vacation.attributes = params[:vacation]

    @vacation.compensatory_hour_total = @vacation.compensatory_hour_total.to_i
    @vacation.compensatory_used_total = @vacation.compensatory_used_total.to_i
    @vacation.cutoff_compensatory_hour_total = @vacation.cutoff_compensatory_hour_total.to_i
    @vacation.summer_vacation_day_total = @vacation.summer_vacation_day_total.to_f
    @vacation.summer_vacation_used_total = @vacation.summer_vacation_used_total.to_f
    @vacation.day_total = @vacation.day_total.to_f
    @vacation.used_total =@vacation.used_total.to_f
    @vacation.cutoff_day_total = @vacation.cutoff_day_total.to_f
    @vacation.life_plan_day_total = @vacation.life_plan_day_total.to_f
    @vacation.life_plan_used_total = @vacation.life_plan_used_total.to_f

Rails.logger.info("[VACATION USED TOTAL] action: vacation/update, at: #{Time.now}, used_total: #{@vacation.used_total}, effect: #{@vacation.used_total - src_used_total}, user: #{@vacation.user_id}, date: xxxx type: xxxx")

    set_user_column @vacation
    @vacation.save!
    flash[:notice] = '有給休暇を更新しました'
    redirect_to :action => 'show', :id => @vacation, :back_to => params[:back_to]
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def update_sv
    begin
      params[:summer_vacation_start_date].to_date
      params[:summer_vacation_end_date].to_date
    rescue
      raise ValidationAbort.new('日付が不正です')
    end
    @summer_vacation_start_date = SysConfig.get_summer_vacation_start_date
    @summer_vacation_end_date = SysConfig.get_summer_vacation_end_date

    ActiveRecord::Base.transaction do
      # 夏期休暇開始日を設定
      @summer_vacation_start_date.value1 = params[:summer_vacation_start_date]
      set_user_column @summer_vacation_start_date
      @summer_vacation_start_date.save!

      # 夏期休暇終了日を設定
      @summer_vacation_end_date.value1 = params[:summer_vacation_end_date]
      set_user_column @summer_vacation_end_date
      @summer_vacation_end_date.save!

      # 夏期休暇日数を全ユーザーに設定
      if params[:span_only].blank?
        @vacations = Vacation.find(:all, :conditions => "deleted = 0")
        @vacations.each do |vacation|
          vacation.summer_vacation_day_total = params[:summer_vacation_day_total][:day_total]
          vacation.summer_vacation_used_total = 0
          set_user_column vacation
          vacation.save!
        end
      end
    end
    redirect_to :action => 'list_sv'
  rescue ValidationAbort
    flash[:err] = $!
    redirect_to :action => 'list_sv'
#  rescue ActiveRecord::RecordInvalid
#    @calendar = true
#    @start_date = SysConfig.get_summer_vacation_start_date.value1
#    @end_date = SysConfig.get_summer_vacation_end_date.value1
#    render :action => 'list_sv'
  end

  def destroy
    #Vacation.find(params[:id]).destroy
    vacation = Vacation.find(params[:id], :conditions => "deleted = 0 ")
    vacation.deleted = 9
    vacation.save!
    redirect_to :action => 'list'
  end
  
  def calculate_annual
    Vacation.calculate_annual
    redirect_to params[:back_to]
  end
  
  def calculate_life_plan
    Vacation.calculate_life_plan
    redirect_to params[:back_to]
  end
  
end
