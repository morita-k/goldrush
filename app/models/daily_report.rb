# -*- encoding: utf-8 -*-
class DailyReport < ActiveRecord::Base
  include AutoTypeName

  SELECT_SUMMARY_COLUMNS = "SUM(contracts) AS contracts, SUM(gross_profits) AS gross_profits, SUM(interviews) AS interviews, SUM(new_meetings) AS new_meetings, SUM(exist_meetings) AS exist_meetings "

  def self.get_daily_report(target_date, target_user_id)
    target_daily_reports = self.where("owner_id = :target_id AND report_date LIKE :target_date", {:target_id => "#{target_user_id}",:target_date => "#{target_date}%"})
                                      .order(:report_date)

    if target_daily_reports.size == 0
      target_daily_reports = create_daily_reports(target_date, target_user_id)
    end

    target_daily_reports
  end

  def self.create_daily_reports(target_date, target_user_id)
    target_month = Date.parse(target_date + '-01')

    target_daily_reports = Array.new

    1.upto(target_month.end_of_month.day) do |target_day|
      target_daily_report = self.new
      target_daily_report.owner_id = target_user_id
      target_daily_report.report_date = Date.new(target_month.year, target_month.month, target_day)
      target_daily_report.save!

      target_daily_reports.push(target_daily_report)
    end

    target_daily_reports
  end

  def self.update_daily_report(target_data)
    target_data.each do |key, value|
      target_contracts = value[:contracts]
      target_gross_profits = value[:gross_profits]
      target_interviews = value[:interviews]
      target_new_meetings = value[:new_meetings]
      target_exist_meetings = value[:exist_meetings]

      if  (target_contracts.nil? || target_contracts.size == 0) &&
          (target_gross_profits.nil? || target_gross_profits.size == 0) &&
          (target_interviews.nil? || target_interviews.size == 0) &&
          (target_new_meetings.nil? || target_new_meetings.size == 0) &&
          (target_exist_meetings.nil? || target_exist_meetings.size == 0)
        next
      end

      target_daily_report = self.where(:id => value[:id]).first
      target_daily_report.contracts = target_contracts
      target_daily_report.gross_profits = target_gross_profits
      target_daily_report.interviews = target_interviews
      target_daily_report.new_meetings = target_new_meetings
      target_daily_report.exist_meetings = target_exist_meetings
      target_daily_report.contact_matter = value[:contact_matter]
      target_daily_report.input_type = 'existinput'

      target_daily_report.save!
    end
  end

  def self.get_distinct_user
    target_user_ids = self.select(:owner_id).uniq
    target_user = User.where(:id => target_user_ids)

    target_user
  end

  def self.get_summary_report(daily_report_summary, target_date)
    term_flg = daily_report_summary[:summary_term_flg]
    target_flg = daily_report_summary[:summary_target_flg]
    method_flg = daily_report_summary[:summary_method_flg]

    case term_flg
      when 'year'
        if target_flg.nil?
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, owner_id AS user_id," + SELECT_SUMMARY_COLUMNS)
                .order(:target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where(:owner_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, owner_id AS user_id, " + SELECT_SUMMARY_COLUMNS)
                .where(:owner_id => target_flg)
                .order(:target_date)
          end
        end
      when 'month'
        current_date = target_date.split("-")[0]
        if target_flg.nil?
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, owner_id AS user_id, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .order(:target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .where(:owner_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, owner_id AS user_id, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .where(:owner_id => target_flg)
                .order(:target_date)
          end
        end
      when 'day'
        current_date = target_date
        if target_flg.nil?
          if method_flg == 'summary'
            self.group(:target_date)
                .select("report_date AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("report_date AS target_date, owner_id AS user_id, " + SELECT_SUMMARY_COLUMNS + ", contact_matter")
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .order(:target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("report_date AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .where(:owner_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("report_date AS target_date, owner_id AS user_id, " + SELECT_SUMMARY_COLUMNS + ", contact_matter")
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .where(:owner_id => target_flg)
                .order(:target_date)
          end
        end
      else
        nil
    end
  end
end