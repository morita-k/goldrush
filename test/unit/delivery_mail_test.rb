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

end
