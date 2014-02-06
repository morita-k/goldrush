# -*- encoding: utf-8 -*-
class DailyReportSummary < ActiveRecord::Base
  include AutoTypeName

  belongs_to :user

  SELECT_SUMMARY_COLUMNS = "SUM(succeeds) AS succeeds, SUM(gross_profits) AS gross_profits, SUM(interviews) AS interviews, SUM(new_meetings) AS new_meetings, SUM(exist_meetings) AS exist_meetings "

  def self.update_daily_report_summary(target_date, target_user_id)
    target_daily_reports = DailyReport.where("user_id = :target_id AND report_date LIKE :target_date", {:target_id => "#{target_user_id}",:target_date => "#{target_date}%"})
                                      .order(:report_date)

    unless target_daily_reports.size == 0
      target_daily_report_summary = self.where("user_id = :target_id AND report_date LIKE :target_date", {:target_id => "#{target_user_id}",:target_date => "#{target_date}%"})
                                        .order(:report_date)
                                        .first

      if target_daily_report_summary.nil?
        target_daily_report_summary = self.new
        target_daily_report_summary.user_id = target_user_id
        target_daily_report_summary.report_date = target_date + '-01'
      end

      summary_succeeds = 0
      summary_gross_profits = 0
      summary_interviews = 0
      summary_new_meetings = 0
      summary_exist_meetings = 0

      target_daily_reports.each do |target_daily_report|
        summary_succeeds += target_daily_report.succeeds
        summary_gross_profits += target_daily_report.gross_profits
        summary_interviews += target_daily_report.interviews
        summary_new_meetings += target_daily_report.new_meetings
        summary_exist_meetings += target_daily_report.exist_meetings
      end

      target_daily_report_summary.succeeds = summary_succeeds
      target_daily_report_summary.gross_profits = summary_gross_profits
      target_daily_report_summary.interviews = summary_interviews
      target_daily_report_summary.new_meetings = summary_new_meetings
      target_daily_report_summary.exist_meetings = summary_exist_meetings

      target_daily_report_summary.save!
    end
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
                .order(:target_date).reverse_order
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, user_id," + SELECT_SUMMARY_COLUMNS)
                .order(:target_date).reverse_order
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where(:user_id => target_flg)
                .order(:target_date).reverse_order
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS)
                .where(:user_id => target_flg)
                .order(:target_date).reverse_order
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
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .order(:target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .where(:user_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS)
                .where("DATE_FORMAT(report_date, '%Y') = '#{current_date}'")
                .where(:user_id => target_flg)
                .order(:target_date)
          end
        end
      else
        nil
    end
  end

  def self.send_mail(target_date, target_user, domain_name)
    target_daily_report_summary = DailyReportSummary.where("user_id = :target_id AND report_date LIKE :target_date", {:target_id => "#{target_user.id}",:target_date => "#{target_date}%"})
                                                    .first
    unless target_daily_report_summary.nil?
      daily_report_mailer = DailyReportMailer.send_mail(target_daily_report_summary, target_date, target_user, domain_name)
      daily_report_mailer.deliver
    end
  end


  # Private Mailer
  class DailyReportMailer < ActionMailer::Base
    def send_mail(target_daily_report_summary, target_date, target_user, domain_name)
      headers['Message-ID'] = "#{SecureRandom.uuid}@#{ActionMailer::Base.smtp_settings[:domain]}"

      target_to = SysConfig.get_value(:daily_report, :send_mail)
      mail( to: target_to,
            cc: nil,
            bcc: nil,
            from: target_user.email,
            subject: "【AP営業部】営業日報 #{target_date}の更新",
            body: get_body(target_daily_report_summary, target_date, target_user, domain_name) )

      # Return-path の設定
      return_path = SysConfig.get_value(:delivery_mails, :return_path)
      if return_path
        headers[:return_path] = return_path
      else
        logger.warn '"Return-Path"が設定されていません。'
      end
    end

    def get_body(target_daily_report_summary, target_date, target_user, domain_name)
      <<EOS
#{target_user.employee.employee_name}の日報更新をお知らせします。

成約数
#{target_daily_report_summary.succeeds}

粗利（単位：万）
#{target_daily_report_summary.gross_profits}

面談数
#{target_daily_report_summary.interviews}

新規会合
#{target_daily_report_summary.new_meetings}

既存会合
#{target_daily_report_summary.exist_meetings}

詳細は以下のURLから確認できます。
https://#{domain_name}/daily_report/summary?date=#{target_date}&summary_method_flg=individual&summary_target_flg%5B%5D=#{target_user.id}&summary_term_flg=day
EOS
    end
  end
end
