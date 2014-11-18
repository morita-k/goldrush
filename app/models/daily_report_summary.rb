# -*- encoding: utf-8 -*-
class DailyReportSummary < ActiveRecord::Base
  include AutoTypeName

  belongs_to :user

  SELECT_SUMMARY_COLUMNS = "SUM(succeed_count) AS succeed_count, SUM(gross_profit_count) AS gross_profit_count, SUM(interview_count) AS interview_count, SUM(new_meeting_count) AS new_meeting_count, SUM(exist_meeting_count) AS exist_meeting_count, SUM(send_delivery_mail_count) AS send_delivery_mail_count "

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
        target_daily_report_summary.owner_id = User.find(target_user_id).owner_id
        target_daily_report_summary.report_date = target_date + '-01'
      end

      summary_succeed_count = 0
      summary_gross_profit_count = 0
      summary_interview_count = 0
      summary_new_meeting_count = 0
      summary_exist_meeting_count = 0
      summary_send_delivery_mail_count = 0

      target_daily_reports.each do |target_daily_report|
        summary_succeed_count += target_daily_report.succeed_count
        summary_gross_profit_count += target_daily_report.gross_profit_count
        summary_interview_count += target_daily_report.interview_count
        summary_new_meeting_count += target_daily_report.new_meeting_count
        summary_exist_meeting_count += target_daily_report.exist_meeting_count
        summary_send_delivery_mail_count += target_daily_report.send_delivery_mail_count
      end

      target_daily_report_summary.succeed_count = summary_succeed_count
      target_daily_report_summary.gross_profit_count = summary_gross_profit_count
      target_daily_report_summary.interview_count = summary_interview_count
      target_daily_report_summary.new_meeting_count = summary_new_meeting_count
      target_daily_report_summary.exist_meeting_count = summary_exist_meeting_count
      target_daily_report_summary.send_delivery_mail_count = summary_send_delivery_mail_count

      target_daily_report_summary.save!
    end
  end

  def self.get_summary_report(owner_id, daily_report_summary, target_date)
    term_flg = daily_report_summary[:summary_term_flg]
    target_flg = daily_report_summary[:summary_target_flg]
    method_flg = daily_report_summary[:summary_method_flg]

    case term_flg
      when 'year'
        if target_flg.nil?
          if method_flg == 'summary'
            self.group(:target_date)
                .where(:owner_id => owner_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .order(:target_date).reverse_order
          else
            self.group(:target_date, :user_id)
                .where(:owner_id => owner_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, user_id," + SELECT_SUMMARY_COLUMNS)
                .order(:target_date).reverse_order
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where(:owner_id => owner_id, :user_id => target_flg)
                .order(:target_date).reverse_order
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y') AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS)
                .where(:owner_id => owner_id, :user_id => target_flg)
                .order(:target_date).reverse_order
          end
        end
      when 'month'
        current_date = target_date.split("-")[0]
        if target_flg.nil?
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y') = ?", owner_id, current_date)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS)
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y') = ?", owner_id, current_date)
                .order(:target_date)
          end
        else
          if method_flg == 'summary'
            self.group(:target_date)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, " + SELECT_SUMMARY_COLUMNS)
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y') = ?", owner_id, current_date)
                .where(:user_id => target_flg)
                .order(:target_date)
          else
            self.group(:target_date, :user_id)
                .select("DATE_FORMAT(report_date, '%Y-%m') AS target_date, user_id, " + SELECT_SUMMARY_COLUMNS)
                .where("owner_id = ? and DATE_FORMAT(report_date, '%Y') = ?", owner_id, current_date)
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
      headers['Message-ID'] = "<#{SecureRandom.uuid}@#{ActionMailer::Base.smtp_settings[:domain]}>"

      # FIXME SysConfig.get_value(:daily_report, :send_mail, target_user.owner_id) は存在しないので、別のアドレスを設定
      target_to = SysConfig.get_value(:daily_report, :send_mail, target_user.owner_id)
      mail( to: target_to,
            cc: nil,
            bcc: nil,
            from: target_user.email,
            subject: "【AP営業部】営業日報 #{target_date}の更新",
            body: get_body(target_daily_report_summary, target_date, target_user, domain_name) )

      # Return-path の設定
      return_path = SysConfig.get_delivery_mails_return_path
      if return_path
        headers[:return_path] = return_path
      else
        logger.warn '"Return-Path"が設定されていません。'
      end
    end

    def get_body(target_daily_report_summary, target_date, target_user, domain_name)
      <<EOS
#{target_user.nickname}の日報更新をお知らせします。

成約数
#{target_daily_report_summary.succeed_count}

粗利（単位：万）
#{target_daily_report_summary.gross_profit_count}

面談数
#{target_daily_report_summary.interview_count}

新規会合
#{target_daily_report_summary.new_meeting_count}

既存会合
#{target_daily_report_summary.exist_meeting_count}

詳細は以下のURLから確認できます。
https://#{domain_name}/daily_report/summary?date=#{target_date}&summary_method_flg=individual&summary_target_flg%5B%5D=#{target_user.id}&summary_term_flg=day
EOS
    end
  end
end
