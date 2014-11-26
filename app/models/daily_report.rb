# -*- encoding: utf-8 -*-
require 'auto_type_name'
class DailyReport < ActiveRecord::Base
  include AutoTypeName

  belongs_to :user

  SELECT_SUMMARY_COLUMNS = "SUM(succeed_count) AS succeed_count, SUM(gross_profit_count) AS gross_profit_count, SUM(interview_count) AS interview_count, SUM(new_meeting_count) AS new_meeting_count, SUM(exist_meeting_count) AS exist_meeting_count, SUM(send_delivery_mail_count) AS send_delivery_mail_count "

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
      target_succeed_count = value[:succeed_count]
      target_gross_profit_count = value[:gross_profit_count]
      target_interview_count = value[:interview_count]
      target_new_meeting_count = value[:new_meeting_count]
      target_exist_meeting_count = value[:exist_meeting_count]

      if value[:id].nil? || value[:id] == ""
        target_daily_report = DailyReport.new
        target_daily_report.owner_id = target_user.owner_id
        target_daily_report.report_date = target_date
        target_daily_report.user_id = target_user.id
        target_daily_report.daily_report_input_type = 'notinput'
      else
        target_daily_report = self.where(:id => value[:id]).first
      end

      unless delivery_mails.nil?
        target_daily_report.send_delivery_mail_count = delivery_mails.select{|x| /^#{target_date}/ =~ x['send_end_at'].to_s && x['mail_from'] == target_user.email}.size
      end

      if  (target_succeed_count.nil? || target_succeed_count.size == 0) &&
          (target_gross_profit_count.nil? || target_gross_profit_count.size == 0) &&
          (target_interview_count.nil? || target_interview_count.size == 0) &&
          (target_new_meeting_count.nil? || target_new_meeting_count.size == 0) &&
          (target_exist_meeting_count.nil? || target_exist_meeting_count.size == 0)

        target_daily_report.save!
        next
      end

      target_daily_report.succeed_count = target_succeed_count.blank? ? 0 : target_succeed_count
      target_daily_report.gross_profit_count = target_gross_profit_count.blank? ? 0 : target_gross_profit_count
      target_daily_report.interview_count = target_interview_count.blank? ? 0 : target_interview_count
      target_daily_report.new_meeting_count = target_new_meeting_count.blank? ? 0 : target_new_meeting_count
      target_daily_report.exist_meeting_count = target_exist_meeting_count.blank? ? 0 : target_exist_meeting_count
      target_daily_report.contact_matter = value[:contact_matter]
      target_daily_report.daily_report_input_type = 'existinput'

      target_daily_report.save!
    end
  end

  def self.get_distinct_user(owner_id)
    self.where(owner_id: owner_id).select(:user_id).uniq
  end

  def self.get_summary_report(owner_id, daily_report_summary, target_date)
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
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y-%m') = ?", owner_id, current_date)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("report_date AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS + ", contact_matter")
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y-%m') = ?", owner_id, current_date)
                .order(:user_id, :target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("report_date AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y-%m') = ?", owner_id, current_date)
                .where(:user_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("report_date AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS + ", contact_matter")
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y-%m') = ?", owner_id, current_date)
                .where(:user_id => target_flg)
                .order(:user_id, :target_date)
          end
        end
      else
        nil
    end
  end
end
