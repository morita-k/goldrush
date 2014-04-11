# -*- encoding: utf-8 -*-
class DailyReport < ActiveRecord::Base
  include AutoTypeName

  belongs_to :user

  SELECT_SUMMARY_COLUMNS = "SUM(succeeds) AS succeeds, SUM(gross_profits) AS gross_profits, SUM(interviews) AS interviews, SUM(new_meetings) AS new_meetings, SUM(exist_meetings) AS exist_meetings, SUM(send_delivery_mails) AS send_delivery_mails "

  def self.get_daily_report(target_date, target_user_id)
    target_daily_reports = self.where("user_id = :target_id AND report_date LIKE :target_date", {:target_id => "#{target_user_id}",:target_date => "#{target_date}%"})
                               .order(:report_date)

    if target_daily_reports.size == 0
      target_daily_reports = build_daily_reports(target_date)
    end

    target_daily_reports
  end

  def self.build_daily_reports(target_date)
    target_month = Date.parse(target_date + '-01')

    target_daily_reports = Array.new

    1.upto(target_month.end_of_month.day) do |target_day|
      target_daily_report = self.new
      target_daily_report.report_date = Date.new(target_month.year, target_month.month, target_day)

      target_daily_reports.push(target_daily_report)
    end

    target_daily_reports
  end

  def self.update_daily_report(target_data, target_user, delivery_mails)
    target_data.each do |key, value|
      target_date = value[:report_date]
      target_succeeds = value[:succeeds]
      target_gross_profits = value[:gross_profits]
      target_interviews = value[:interviews]
      target_new_meetings = value[:new_meetings]
      target_exist_meetings = value[:exist_meetings]

      if value[:id].nil? || value[:id] == ""
        target_daily_report = DailyReport.new
        target_daily_report.report_date = target_date
        target_daily_report.user_id = target_user.id
        target_daily_report.daily_report_input_type = 'notinput'
      else
        target_daily_report = self.where(:id => value[:id]).first
      end

      unless delivery_mails.nil?
        target_daily_report.send_delivery_mails = delivery_mails.select{|x| /^#{target_date}/ =~ x['send_end_at'].to_s && x['mail_from'] == target_user.email}.size
      end

      if  (target_succeeds.nil? || target_succeeds.size == 0) &&
          (target_gross_profits.nil? || target_gross_profits.size == 0) &&
          (target_interviews.nil? || target_interviews.size == 0) &&
          (target_new_meetings.nil? || target_new_meetings.size == 0) &&
          (target_exist_meetings.nil? || target_exist_meetings.size == 0)

        target_daily_report.save!
        next
      end

      target_daily_report.succeeds = target_succeeds.blank? ? 0 : target_succeeds
      target_daily_report.gross_profits = target_gross_profits.blank? ? 0 : target_gross_profits
      target_daily_report.interviews = target_interviews.blank? ? 0 : target_interviews
      target_daily_report.new_meetings = target_new_meetings.blank? ? 0 : target_new_meetings
      target_daily_report.exist_meetings = target_exist_meetings.blank? ? 0 : target_exist_meetings
      target_daily_report.contact_matter = value[:contact_matter]
      target_daily_report.daily_report_input_type = 'existinput'

      target_daily_report.save!
    end
  end

  def self.get_distinct_user
    self.select(:user_id).uniq
  end

  def self.get_summary_report(daily_report_summary, target_date)
    term_flg = daily_report_summary[:summary_term_flg]
    target_flg = daily_report_summary[:summary_target_flg]
    method_flg = daily_report_summary[:summary_method_flg]

    case term_flg
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
                .select("report_date AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS + ", contact_matter")
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .order(:user_id, :target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("report_date AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .where(:user_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("report_date AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS + ", contact_matter")
                .where("DATE_FORMAT(report_date, '%Y-%m') = '#{current_date}'")
                .where(:user_id => target_flg)
                .order(:user_id, :target_date)
          end
        end
      else
        nil
    end
  end
end
