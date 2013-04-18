# -*- encoding: utf-8 -*-
class Vacation < ActiveRecord::Base
  include AutoTypeName
  include DateTimeUtil
  
  belongs_to :user

  def remain_total
    self.day_total - self.used_total
  end

  def life_plan_remain_total
    self.life_plan_day_total - self.life_plan_used_total
  end

  def compensatory_remain_total
    self.compensatory_hour_total - self.compensatory_used_total
  end

  def calHourMinuteFormatJa(sec)
    DateTimeUtil.calHourMinuteFormatJa(sec)
  end

  def compensatory_remain_total_format
    calHourMinuteFormatJa(compensatory_remain_total)
  end

  def cutoff_compensatory_hour_total_format
     calHourMinuteFormatJa((cutoff_compensatory_hour_total < 0 ? 0 : cutoff_compensatory_hour_total))
  end

  def compensatory_hour_total_format
    calHourMinuteFormatJa(compensatory_hour_total)
  end

  def compensatory_used_total_format
    calHourMinuteFormatJa(compensatory_used_total)
  end

  def summer_vacation_remain_total(target_date)
    start_date = SysConfig.get_summer_vacation_start_date.value1.to_date
    end_date = SysConfig.get_summer_vacation_end_date.value1.to_date
    if start_date <= target_date && target_date <= end_date
      self.summer_vacation_day_total - self.summer_vacation_used_total
    else
      0
    end
  end

  def Vacation.in_summer_vacation_period?(start_date, end_date)
    conf_start_date = SysConfig.get_summer_vacation_start_date.value1.to_date
    conf_end_date = SysConfig.get_summer_vacation_end_date.value1.to_date

    conf_start_date <= start_date && start_date <= conf_end_date && conf_start_date <= end_date && end_date <= conf_end_date
  end

  def calced_cutoff_day_total_format
    self.cutoff_day_total > self.used_total ? self.cutoff_day_total - self.used_total : 0
  end

  def self.set_user_column(vac, login)
    vac.created_user = login if vac.new_record?
    vac.updated_user = login
  end

  def Vacation.create_init_vacation(user, date)
    vacation = Vacation.init_vacation(user.id)
    set_user_column vacation, 'create_init_vacation'
    vacation.save!
    # 初年度の計算
    today = date
    today = today.prev_year if today.month < 4 # 1～3月なら、1マイナス
    conf_year_start_date = SysConfig.get_year_start_date.value1
    process_date = Time.parse(today.year.to_s + '/' + conf_year_start_date).to_date
    # 新年度分、年次有給の付与
    Vacation.calculate_day_total(user, process_date)
    # トータルの有給を計算する
    Vacation.calculate_current_vacation(user, vacation)
    # 有給今期迄を計算する
    Vacation.calculate_cutoff_day_total(user, vacation, process_date)
  end

  def self.init_vacation(user_id)
    Vacation.new({
      :user_id => user_id,
      :compensatory_hour_total => 0,
      :compensatory_used_total => 0,
      :cutoff_compensatory_hour_total => 0,
      :summer_vacation_day_total => 0,
      :summer_vacation_used_total => 0,
      :day_total => 0,
      :used_total => 0,
      :cutoff_day_total => 0,
      :life_plan_day_total => 0,
      :life_plan_used_total => 0
    })
  end

  # 有給計算処理概要説明
  # 1. [有給休暇]は、年度別の有給を計算した結果の値を保持。オンライン処理で利用する
  # 2. [年次有給休暇]は、その年度の有給休暇状況を保持
  # 3. 年度処理でライフプランフラグが立てられたレコードは、ライフプラン転換済みで、有給数には数えない
  # 4. 年度処理
  #   *1 [有給休暇]を読み込み、消費された有給をライフプラン化されていないレコードに対して、年度の古い順に消しこみを行う
  #   *2 [有給休暇]を読み込み、消費されたライフプラン休暇をライフプラン化されたレコードに対して、年度の古い順に消しこみを行う
  #   *3 *1で残ったレコードに対して、ライフプラン転換処理を行う(ライフプランフラグ=1)
  #   *4 新年度分、年次有給の付与
  #   *5 最終的な有給残数を計算し、カレントレコードを初期化する
  #   *6 最終的な計算の結果、MAXをoverしていいたらその分減じる
  # 
  # 引数: year: 次に有効になる年度("2008"など・・・)
  def self.calculate_vacations(year)
    logger.debug "Start calculate_vacations: year => #{year}, at => #{Time.now}"
    conf_year_start_date = SysConfig.get_year_start_date.value1
    process_date = Time.parse(year + '/' + conf_year_start_date).to_date

    day_total = 0
    User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.resignation_date is null"]).each do |user|
      logger.debug "Proc user: #{user.login}"

      unless vacation = Vacation.find(:first, :conditions => ["deleted = 0 and user_id = ?", user.id])
        vacation = Vacation.init_vacation(user.id)
        set_user_column vacation, 'calculate_vacations'
        vacation.save!
      end

      # 有給休暇消費分の消しこみ
      Vacation.write_back_used_total(user, vacation.used_total)

      # ライフプラン休暇消費分の消しこみ
      Vacation.write_back_life_plan_used_total(user, vacation.life_plan_used_total)

      # MAX年数を超えた有給をライフプランに転換
      Vacation.calculate_life_plan(user, process_date)

      # 新年度分、年次有給の付与
      Vacation.calculate_day_total(user, process_date)

      # トータルの有給を計算する
      Vacation.calculate_current_vacation(user, vacation)

      # 夏季休暇のクリア
      #Vacation.clear_summar_vacation(user, vacation)

      # MAX超過分を減じる
      Vacation.reduse_max_over(user, vacation)

      # 有給今期迄を計算する
      Vacation.calculate_cutoff_day_total(user, vacation, process_date)

    end
    logger.debug "End calculate_vacations: year => #{year}, at => #{Time.now}"
  end

  #
  # 有給休暇消費分の消しこみ
  #
  def Vacation.write_back_used_total(user, used_total)
    # ライフプラン休暇に組み込まれていず、カレントレコードでもない有給情報を年度の古い順に取得
    AnnualVacation.find(:all, :conditions => ["deleted = 0 and user_id = ? and life_plan_flg = 0", user.id], :order => "year").each do |annual|
      if annual.remain_total > used_total
        annual.used_total += used_total
        used_total = 0
      else
        used_total -= annual.remain_total
        annual.used_total =  annual.day_total
      end
      set_user_column annual, 'write_back_used_total'
      annual.save!
      break if used_total == 0
    end
  end

  #
  # ライフプラン休暇消費分の消しこみ
  #
  def Vacation.write_back_life_plan_used_total(user, life_plan_used_total)
    # ライフプラン休暇で、カレントレコードでない有給情報を年度の古い順に取得
    AnnualVacation.find(:all, :conditions => ["deleted = 0 and user_id = ? and life_plan_flg = 1", user.id], :order => "year").each do |annual|
      if annual.life_plan_remain_total > life_plan_used_total
        annual.life_plan_used_total += life_plan_used_total
        life_plan_used_total = 0
      else
        life_plan_used_total -= annual.life_plan_remain_total
        annual.life_plan_used_total = annual.life_plan_day_total
      end
      set_user_column annual, 'write_back_life_plan_used_total'
      annual.save!
    end
  end

  #
  # MAX年数を超えた有給をライフプランに転換
  #
  def self.calculate_life_plan(user, process_date)
    life_plan_day_behavior_max = SysConfig.get_life_plan_behavior_max
    before_year_count = SysConfig.get_before_year_count
    before_date = process_date - before_year_count.to_i.year

    AnnualVacation.find(:all, :conditions => ["deleted = 0 and life_plan_flg = 0 and year <= ? and user_id = ?", before_date.year, user.id]).each do |annual|
      if annual.remain_total > life_plan_day_behavior_max
        annual.life_plan_day_total = life_plan_day_behavior_max
      else
        annual.life_plan_day_total = annual.remain_total
      end
      annual.life_plan_flg = 1
      set_user_column annual, 'calculate_life_plan'
      annual.save!
    end
  end

  #
  # 新年度分、年次有給の付与
  #
  def self.calculate_day_total(user, process_date)
    # 次の年を基準に計算する
    base_date = process_date.next_year
    monthes = user.employee.calWorkingMonthes(base_date)
    # 半年を経過した回数で計算
    if (day_total = SysConfig.get_vacation_half_year((monthes.to_i - 1) / 6)).blank?
      day_total = SysConfig.get_vacation_month(monthes.to_i).value1
    end
    day_total = day_total.to_i
    #存在のチェック
    annual = AnnualVacation.find(:first, :conditions => ["deleted = 0 and year = ? and user_id = ?", process_date.year, user.id])
    if !annual
      annual = AnnualVacation.new
      annual.user_id = user.id
      annual.year = process_date.year
      annual.start_date = process_date
      annual.end_date = process_date + 1.year - 1.day
      annual.day_total = day_total
      annual.used_total = 0
      annual.life_plan_day_total = 0
      annual.life_plan_used_total = 0
      annual.life_plan_flg = 0
      set_user_column annual, 'calculate_day_total'
      annual.save!
    else
      logger.debug "AnnualVacation exist. user: #{user.id} year: #{process_date.year}"
    end #AnnualVacation
  end
  
  #
  # トータルの有給を計算する
  #
  def self.calculate_current_vacation(user, vacation)
    # ライフプランで無い有給残数計算
    annual = AnnualVacation.find(:first, :select => "sum(day_total - used_total) sum_remain_total", :conditions => ["deleted = 0 and user_id = ? and life_plan_flg = 0", user.id])

    vacation.day_total = annual.sum_remain_total
    vacation.used_total = 0

    # ライフプラン休暇残数計算
    annual = AnnualVacation.find(:first, :select => "sum(life_plan_day_total - life_plan_used_total) sum_remain_total", :conditions => ["deleted = 0 and user_id = ? and life_plan_flg = 1", user.id])
    #vacation.life_plan_day_total = annual.sum_remain_total
    vacation.life_plan_day_total = annual.sum_remain_total if (annual.sum_remain_total != nil)
    vacation.life_plan_used_total = 0

    set_user_column vacation, 'calculate_current_vacation'
    vacation.save!
  end

  # 夏季休暇のクリア
  def Vacation.clear_summar_vacation(user, vacation)
    vacation.summer_vacation_day_total = 0
    vacation.summer_vacation_used_total = 0

    set_user_column vacation, 'clear_summar_vacation'
    vacation.save!
  end

  # MAX超過分を減じる
  def self.reduse_max_over(user, vacation)
    day_max = SysConfig.get_day_max
    life_plan_day_max = SysConfig.get_life_plan_day_max

    if vacation.day_total > day_max
      # 有給休暇消費分の消しこみ
      Vacation.write_back_used_total(user, vacation.day_total - day_max)
      vacation.day_total = day_max
    end

    if vacation.life_plan_day_total > life_plan_day_max
      # ライフプラン休暇消費分の消しこみ
      Vacation.write_back_life_plan_used_total(user, vacation.life_plan_day_total - life_plan_day_max)
      vacation.life_plan_day_total = life_plan_day_max
    end

    set_user_column vacation, 'reduse_max_over'
    vacation.save!
  end

  # 有給今期迄を計算する
  def Vacation.calculate_cutoff_day_total(user, vacation, process_date)
    before_year_count = SysConfig.get_before_year_count.to_i - 1
    before_date = process_date - before_year_count.year

    annual = AnnualVacation.find(:first, :conditions => ["deleted = 0 and life_plan_flg = 0 and year = ? and user_id = ?", before_date.year, user.id])
    vacation.cutoff_day_total = annual ? annual.remain_total : 0

    set_user_column vacation, 'calculate_cutoff_day_total'
    vacation.save!
  end

  # 代休計算処理概要説明
  # 1. [有給休暇.代休積算時間]に有効期限が来ていない、代休として使える休出時間の残数を保持する
  # 2. 代休を使用した場合、[有給休暇.代休使用時間]に即時に加算していく
  # 3. 休日出勤が承認された場合、[有給休暇.代休積算時間]に即時に加算していく
  # 
  # この処理では、1の残数算出を行う。月末、または月初に一括実行される想定である。
  # 1. [有給休暇.代休使用時間]を[作業月.代休使用時間]に振り分ける(消しこみ)
  # 2. 有効な[作業月]の[代休積算時間 - 代休使用時間]を積算して[有給休暇.代休積算時間]を更新する
  # 3. 対象月が最終月となる[作業月]の[代休積算時間 - 代休使用時間]を取得して[代休今月迄]を更新する
  # 
  # 引数: next_month: 次に有効になる月度の開始日("2008/4/21"など・・・)
#  def Vacation.calculate_compensatories(next_month_start_date, user_id = nil)
  def Vacation.calculate_compensatories(base_application)
    user = User.find(:first, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.resignation_date is null and users.id = ?", base_application.user_id])
    vacation = user.vacation
#    vacation = Vacation.find(:first, :conditions => ["deleted = 0 and user_id = ?", base_application.user_id])
    next_month = base_application.monthly_working.base_month.next_month
    before_month_count = SysConfig.get_before_month_count
    logger.info "Start month: #{next_month.start_date}"

    # 申請却下用に、vacationの各値を保持する
    vacation.pre_resist

    # 月別実績を保持
    # こいつは何度上書きしても問題ないので、キャンセル後の再承認対策として先に処理
    # monthly_working.hold_flgが0の時のみ実績保持
    # 承認却下でhold_flgを0に戻す
    base_application.monthly_working.resist(vacation, next_month.start_date) if base_application.monthly_working.hold_flg == 0
    logger.info "monthly_workings(#{base_application.monthly_working.start_date}～) result record !"

    # 二回処理するとまずいので、一度処理したらbase_application.accounting_approval_flgを立てる
    # フラグが立っていたら処理しない
#####    return if base_application.accounting_approval_flg == 1

    # 当月を含まずに、before_month_count+1分もってくる(現在月にとっての有効月)
    monthes = BaseMonth.find(:all, :conditions => ["deleted = 0 and start_date < ?", next_month.start_date.to_date], :order => "start_date desc", :limit => (before_month_count + 1)).reverse
 #   user = User.find(:first, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.resignation_date is null and users.id = ?", base_application.user_id])
    logger.info "Proc user: #{user.login}"

    tmp_monthes = monthes.dup # あとで1個削るのでコピーして使う
    # 各作業月の代休残時間の消しこみ
 #   vacation = user.vacation
#    used_hour = vacation.compensatory_used_total
    # 対象月の代休日数を数え、所定労働時間をかける
    compensatory_count = base_application.monthly_working.calc_compensatory_dayoff_count
    used_hour = compensatory_count * (user.employee.regular_working_hour * 60 * 60).to_i
    vacation.compensatory_used_total -= used_hour # 当月使った分を引く
    tmp_monthes.each{|month|
      logger.info " >> month: " + month.start_date.to_s
puts">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>base_monthes.id : #{month.id}"
      next unless monthly_working = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and base_month_id = ?", user.id, month.id])
      
      # 承認解除（fixed → entry）用に、monthly_workingの各値を保持する
puts">>>>>>>>>>>>>>>>>>>>>>>>resist_monthly_working.id : #{monthly_working.id}"
      monthly_working.pre_comp_used_total = monthly_working.compensatory_used_total
puts">>>>>>>>>>>>>>monthly_working.pre_comp_used_total : #{monthly_working.pre_comp_used_total}"
      
      if monthly_working.remain_compensatory_hour_total > used_hour
        monthly_working.compensatory_used_total += used_hour
        used_hour = 0
      else
        used_hour -= monthly_working.remain_compensatory_hour_total
        monthly_working.compensatory_used_total = monthly_working.compensatory_hour_total
      end
      set_user_column monthly_working, 'calculate_compensatories'
      monthly_working.save!
      break if used_hour == 0
    }

    tmp_monthes.shift # 最古の一月を除外

    total_remain = 0
    tmp_remain = 0
    first_month = true
    # 来月有効な代休時間の合計と今月まで有効な代休時間を求める
    tmp_monthes.each{|month|
      unless monthly_working = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and base_month_id = ?", user.id, month.id])
        first_month = false
        next
      end
      logger.info " >>remain_compensatory_hour_total: " + monthly_working.remain_compensatory_hour_total.to_s
      total_remain += monthly_working.remain_compensatory_hour_total
      # 最古の一月の今月まで有効な代休を求める(なければ0)
      if first_month
        logger.info " >>first_month: " + monthly_working.start_date.to_s
        tmp_remain = monthly_working.remain_compensatory_hour_total
        logger.info " >>remain_compensatory_hour_total: " + monthly_working.remain_compensatory_hour_total.to_s
      end
      first_month = false
    }
    
    # 承認月の次の月以降で先に代休承認＋日報登録されていた場合、それもV.代休積算に加える必要がある
    future_compensatory_hour_total = DailyWorking.count_comp(user, next_month.start_date)

    vacation.compensatory_hour_total = total_remain + future_compensatory_hour_total
    vacation.cutoff_compensatory_hour_total = tmp_remain
    set_user_column vacation, 'calculate_compensatories'
    vacation.save!
#    このタイミングだと遅い
#    # 2011/3/11 月別休暇データの取得 ==================
#    base_application.monthly_working.resist(vacation)
#    base_application.monthly_working.save!
#    # ================================================

    # 二回処理しないようにフラグを立てる
    base_application.accounting_approval_flg = 1
    base_application.save!
  end

  def Vacation.grant_summar_vacation(day_count, grant_user = 'grant_summar_vacation')
    # 全ユーザ分繰り返し
    User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.resignation_date is null"]).each do |user|
      vacation = user.vacation
      vacation.summer_vacation_day_total = day_count
      vacation.summer_vacation_used_total = 0
      set_user_column vacation, grant_user
      vacation.save!
    end
  end

  def pre_resist
    self.pre_comp_hour_total = self.compensatory_hour_total
    self.pre_comp_used_total = self.compensatory_used_total
    self.pre_cutoff_comp_hour_total = self.cutoff_compensatory_hour_total
    self.save!
 end

  def pre_resist_back
    self.compensatory_hour_total = self.pre_comp_hour_total
    self.compensatory_used_total = self.pre_comp_used_total
    self.cutoff_compensatory_hour_total = self.pre_cutoff_comp_hour_total
    self.save!
 end

end
