# -*- encoding:utf-8 -*-
require 'test_helper'

class ImportMailTest < ActiveSupport::TestCase
  setup do
  end
  
  test "import mail" do
    im = ImportMail.new
    im.analyze(<<EOS)
    java
    cobol
    東京駅
    39歳
    29歳
    80～90万円
EOS
    assert_equal("cobol,java", im.tag_text)
    assert_equal("東京駅", im.nearest_station)
    # 年齢正規化処理の為、「歳」は消去。
    assert_equal(39, im.age)
    assert_equal(90.0, im.payment)
  end

  test "import reply mail" do
    src = <<EOS
Date: Wed, 11 Jun 2014 17:38:29 +0900
From: system@gr.applicative.jp
To: dummy@applicative.jp
Message-ID: <xxxxxxxxxxxxxxxxx>
In-Reply-To: aaa
Subject: Hello!
Mime-Version: 1.0
Content-Type: text/plain;
 charset=UTF-8

Hello!!!


EOS
    m = Mail.new(src)
    assert_equal("aaa", m.in_reply_to)
    d = DeliveryMailTarget.where(message_id: m.in_reply_to).first
    assert_equal("aaa", d.message_id)
    ImportMail.import_reply_mail(m, src)
    subject = ImportMail.tryConv(m, 'Subject') { m.subject }
    im = ImportMail.where(mail_subject: subject).first
    assert_equal(1, im.delivery_mail_id)
  end


end
