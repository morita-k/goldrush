# -*- encoding: utf-8 -*-
require 'test_helper'

class DeliveryMailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "message_id format" do
    message_id = DeliveryMail::MyMailer.send_del_mail("destination@aaatttest.com", "", "", "from <destination@aaatttest.com>", "subject", "body", []).header['Message-ID']
    
    assert_match(/.*@#{ActionMailer::Base.smtp_settings[:domain]}/, message_id.to_s)
  end
  
  test "two message_ids not equal" do
    message_id_1 = DeliveryMail::MyMailer.send_del_mail("destination@aaatttest.com", "", "", "from <destination@aaatttest.com>", "subject", "body", []).header['Message-ID']
    message_id_2 = DeliveryMail::MyMailer.send_del_mail("destination@bbbtttest.com", "", "", "from <destination@bbbtttest.com>", "subject", "body", []).header['Message-ID']
    
    assert_not_nil(message_id_1)
    assert_not_nil(message_id_2)
    assert_not_equal(message_id_1.to_s, message_id_2.to_s)
  end
  
  test "save message_id in delivery_mail_targets" do
    assert(ActionMailer::Base.delivery_method == :test)
    
    DeliveryMail.send_mails
    target = DeliveryMailTarget.find(1)
    assert_match(/.*@#{ActionMailer::Base.smtp_settings[:domain]}/, target.message_id)
  end
  
  
  test "error handling 001" do
    
    errs_before = DeliveryError.find(:all).size
    
    mail = DeliveryMail.find(2)
    DeliveryMail.send_mail_to_each_targets(mail)
    
    assert_equal(errs_before + 1, DeliveryError.find(:all).size)
    
    err = DeliveryError.find(:all).last
    assert_equal("send_error", err.mail_error_type)
    assert_equal(4, err.bp_pic_id)
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
