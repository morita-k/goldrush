# -*- encoding: utf-8 -*-
require 'test_helper'
require 'smtp_password_encryptor'

class DeliveryMailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "message_id format" do
    domain = "test_domain.com"
    message_id = NoticeMailer.create_mail(domain, "destination@aaatttest.com", "", "", "from <destination@aaatttest.com>", "subject", "body", []).header['Message-ID']
    assert_match(/.*@#{domain}/, message_id.to_s)
  end
  
  test "two message_ids not equal" do
    domain = "test_domain.com"
    message_id_1 = NoticeMailer.create_mail(domain, "destination@aaatttest.com", "", "", "from <destination@aaatttest.com>", "subject", "body", []).header['Message-ID']
    message_id_2 = NoticeMailer.create_mail(domain, "destination@bbbtttest.com", "", "", "from <destination@bbbtttest.com>", "subject", "body", []).header['Message-ID']

    assert_not_nil(message_id_1)
    assert_not_nil(message_id_2)
    assert_not_equal(message_id_1.to_s, message_id_2.to_s)
  end
  
  test "save message_id in delivery_mail_targets" do
    assert(ActionMailer::Base.delivery_method == :test)

    DeliveryMail.send_mails
    target = DeliveryMailTarget.find(1)
    mail_sender = DeliveryMail.find(1).delivery_user
    assert_match(/.*@#{mail_sender.smtp_settings_domain}/, target.message_id)
  end

  test "error handling 001" do
 
    errs_before = DeliveryError.find(:all).size
 
    mail_sender = User.find(1)
    mail = DeliveryMail.find(2)
    DeliveryMail.send_mail_to_each_targets(mail_sender, mail)

    assert_equal(errs_before + 1, DeliveryError.find(:all).size)

    err = DeliveryError.find(:all).last
    assert_equal(2, err.delivery_mail_id)
    assert_equal("send_error", err.mail_error_type)
    assert_equal(4, err.bp_pic_id)
  end
  
  test "setup_planned_setting_at 001" do
    date = "2013/07/19"
    hour = "14"
    minute = "55"
    time_str = date + " " + [hour,minute,"00"].join(":")
    time = User.find(1).zone_parse(time_str)

    mail = DeliveryMail.find(1)
    mail.setup_planned_setting_at(time)

    # Asserts
    assert_equal(date, mail.planned_setting_at_date)
    assert_equal(hour, mail.planned_setting_at_hour)
    assert_equal(minute, mail.planned_setting_at_minute)
  end
  
  test "planned_setting_at_time 001" do
    hour = "14"
    minute = "55"

    mail = DeliveryMail.new

    mail.planned_setting_at_hour = nil
    mail.planned_setting_at_minute = nil
    assert_equal("", mail.planned_setting_at_time)

    mail.planned_setting_at_hour = ""
    mail.planned_setting_at_minute = nil
    assert_equal("", mail.planned_setting_at_time)

    mail.planned_setting_at_hour = nil
    mail.planned_setting_at_minute = ""
    assert_equal("", mail.planned_setting_at_time)

    mail.planned_setting_at_hour = ""
    mail.planned_setting_at_minute = ""
    assert_equal("", mail.planned_setting_at_time)

    mail.planned_setting_at_hour = hour
    mail.planned_setting_at_minute = ""
    assert_equal("", mail.planned_setting_at_time)

    mail.planned_setting_at_hour = ""
    mail.planned_setting_at_minute = minute
    assert_equal("", mail.planned_setting_at_time)

    mail.planned_setting_at_hour = hour
    mail.planned_setting_at_minute = minute
    assert_equal("14:55:00", mail.planned_setting_at_time)
  end

  # 特定の送信先でエラーを吐かせる為に、既存のメソッドを加工
  class Mail::Message
    alias deliver_org deliver
    def deliver
      if self.to[0] == "hogehoge"
        raise "hogehoge"
      else
        deliver_org
      end
    end
  end
end
