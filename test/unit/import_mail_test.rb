# -*- encoding:utf-8 -*-
require 'test_helper'

class ImportMailTest < ActiveSupport::TestCase
  setup do
  end
  
  test "import mail" do
    im = ImportMail.new
    im.mail_subject = 'java,c++,oracle'
    im.analyze(<<EOS)
    java
    cobol
    東京駅
    39歳
    29歳
    80～90万円
EOS
    assert_equal("cobol,java", im.tag_text)
    assert_equal("c++,java,oracle", im.subject_tag_text)
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

  test "detect_interviewing_count" do
    ### 面談回数不明パターン  
    assert_detect_interviewing_count(<<EOS, 0)
・面談回数　：
・社員区分　：正社員,契約社員
EOS

    ### 通常パターン
    assert_detect_interviewing_count(<<EOS, 1)
    単価　@50（140-180、スキルにより柔軟に増額可）
    面談　1回（弊社同席）　※即設定可能
    人数　1名
EOS

    assert_detect_interviewing_count(<<EOS, 2)
・面　談　　：２回
・備　考　　：外国籍可
EOS

    assert_detect_interviewing_count(<<EOS, 1)
　　　　　　　　　　■面談回数１回
　　　　　　　　　　■単価６０万程度（固定）
EOS

    assert_detect_interviewing_count(<<EOS, 1)
　■面談・・・・・・１回
　■単価・・・・・・６０万程度（固定）
EOS

    assert_detect_interviewing_count(<<EOS, 1)
・面接回数　：1回
・備　考　　：外国籍可
EOS

    assert_detect_interviewing_count(<<EOS, 3)
・打ち合わせ：3回
・備　考　　：外国籍可
EOS

    assert_detect_interviewing_count(<<EOS, 1)
・打合せ　　：1回
・備　考　　：外国籍不可
EOS

    ### 2行パターン
    assert_detect_interviewing_count(<<EOS, 2)
■面談回数
2回
■年齢
EOS

    ### 3行パターン
    assert_detect_interviewing_count(<<EOS, 1)
■面談回数
   
1回
■年齢
EOS

    ### 複数回数パターン
    assert_detect_interviewing_count(<<EOS, 2)
　　■面談回数：　１〜２回
　　■単価６０万程度（固定）
EOS

    ### 漢数字パターン
    assert_detect_interviewing_count(<<EOS, 1)
　　■面談回数：　一回
　　■単価６０万程度（固定）
EOS

    assert_detect_interviewing_count(<<EOS, 2)
　　■面談回数：　二回
　　■単価６０万程度（固定）
EOS
  end

  def assert_detect_interviewing_count(body, expected_count)
    im = ImportMail.new
    im.mail_subject = ""
    im.mail_body = body
    im.analyze
    assert_equal(expected_count, im.interviewing_count)
  end
end
