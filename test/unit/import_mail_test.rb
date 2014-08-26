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

  test "detect_interview_count" do
    ### 面談回数不明パターン  
    assert_detect_interview_count(<<EOS, 0)
・面談回数　：
・社員区分　：正社員,契約社員
EOS

    ### 通常パターン
    assert_detect_interview_count(<<EOS, 1)
    単価　@50（140-180、スキルにより柔軟に増額可）
    面談　1回（弊社同席）　※即設定可能
    人数　1名
EOS

    assert_detect_interview_count(<<EOS, 2)
・面　談　　：２回
・備　考　　：外国籍可
EOS

    assert_detect_interview_count(<<EOS, 1)
　　　　　　　　　　■面談回数１回
　　　　　　　　　　■単価６０万程度（固定）
EOS

    assert_detect_interview_count(<<EOS, 1)
　■面談・・・・・・１回
　■単価・・・・・・６０万程度（固定）
EOS

    assert_detect_interview_count(<<EOS, 1)
・面接回数　：1回
・備　考　　：外国籍可
EOS

    assert_detect_interview_count(<<EOS, 3)
・打ち合わせ：3回
・備　考　　：外国籍可
EOS

    assert_detect_interview_count(<<EOS, 1)
・打合せ　　：1回
・備　考　　：外国籍不可
EOS

    assert_detect_interview_count(<<EOS, 2)
・面回数　：２ 回
・備　考　：外国籍可
EOS

    assert_detect_interview_count(<<EOS, 1)
・面会　：1回
・備　考　：外国籍可
EOS

    ### 2行パターン
    assert_detect_interview_count(<<EOS, 2)
■面談回数
2回
■年齢
EOS

    ### 3行パターン
    assert_detect_interview_count(<<EOS, 1)
■面談回数
   
1回
■年齢
EOS

    ### 4行パターン
    assert_detect_interview_count(<<EOS, 3)
■面談回数
   
   
3回
■年齢
EOS

    ### 複数回数パターン
    assert_detect_interview_count(<<EOS, 2)
　　■面談回数：　１〜２回
　　■単価６０万程度（固定）
EOS

    ### 漢数字パターン
    assert_detect_interview_count(<<EOS, 1)
　　■面談回数：　一回
　　■単価６０万程度（固定）
EOS

    assert_detect_interview_count(<<EOS, 2)
　　■面談回数：　二回
　　■単価６０万程度（固定）
EOS
 
    ### 複数「面談」文言パターン
    assert_detect_interview_count(<<EOS, 1)
※所属(御社or1社下)、雇用形態(社員or契約or個人)、並行営業状況(提案or面談or結果待ち)をお伝え下さい
----------------------------------------------------------------------

...

■期間
9月〜長期
■面談回数
1回
----------------------------------------------------------------------
EOS
  end
 
  test "detect_biz_offer_foreign_type" do
    ### 記載なしパターン
    assert_detect_biz_offer_foreign_type(<<EOS, 'unknown')
人数　　　　　　３名
備考　　　　　　貴社社員まで
　　　　　　　　日本人、外国人共に多い現場です。
EOS
 
    ### 外国籍可パターン
    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
・外国人O.K.
※外国籍の方の場合事前打ち合わせをさせて頂きます。
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
・国籍： 外国可
備考：長期を見込んで参画出来る方を希望
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
面談：2回
備考：長期を見込んで参画出来る方を希望
　　　※外国人大丈夫です。
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
外国籍：OK
備考：長期を見込んで参画出来る方を希望
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
・外国籍可
備考：長期を見込んで参画出来る方を希望
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
外国籍：不問
備考　：長期を見込んで参画出来る方を希望
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
備考：長期を見込んで参画出来る方を希望
　　　※外国籍大丈夫です。
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'foreign')
【外国籍】
　可
【面談】
　１回
EOS

    ### 外国籍不可パターン
    assert_detect_biz_offer_foreign_type(<<EOS, 'internal')
■国　籍：外国不可

■所　属：御社迄
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'internal')
募集人数　　　2〜3名
外国籍　　　　不可
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'internal')
・外国籍不可
・貴社 社員・契約社員まで
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'internal')
備　考：勤怠・コミュニケーションに問題ない方
　　　　自己管理が出来る方
　　　　業務知識は特にいりません
　　　　外国籍NG
　　　　稼働は安定しています（平均150〜170ｈ）
　　　　今後も増員予定の案件になります
EOS

    assert_detect_biz_offer_foreign_type(<<EOS, 'internal')
【外国籍】 
　不可
【面談】
　１回
EOS
  end

  test "detect_bp_member_foreign_type" do
    ### 記載なしパターン
    assert_detect_bp_member_foreign_type(<<EOS, 'unknown')
    名　　前：KH(男性)
    年　　齢：30歳 
EOS

    ### 自国籍パターン
    assert_detect_bp_member_foreign_type(<<EOS, 'internal')
    【名　前】TH(37歳)　男性 日本人 
    【スキル】html, css, JavaScript, PHP, mysql
EOS

    assert_detect_bp_member_foreign_type(<<EOS, 'internal')
    【性　別】　　男性 
    【年　齢】　　37歳 
    【国　籍】　　日本
EOS

    assert_detect_bp_member_foreign_type(<<EOS, 'internal')
    【性　別】　　女性 
    【年　齢】　　32歳 日本人
EOS

    ### 外国籍パターン
    assert_detect_bp_member_foreign_type(<<EOS, 'foreign')
    名　　前：YK
    年　　齢：30歳・男性 
    日本語　：日本語検定1級 
EOS

   assert_detect_bp_member_foreign_type(<<EOS, 'foreign')
    年　　齢：30歳・男性 
    国　　籍：中国 
    来日年数：来日3ヶ月　※日本のプロジェクトに入場中 
EOS

    assert_detect_bp_member_foreign_type(<<EOS, 'foreign')
    所属：一社下社員 
    国籍：パキスタン国籍（日本の永住権あり） 
    稼動：即日〜
EOS

    assert_detect_bp_member_foreign_type(<<EOS, 'foreign')
    ■ 名　前　：BR　31歳　男　台湾国籍 
    　最寄駅　：○○線　XX駅 
    　雇用形態：BP正社員 
EOS

    assert_detect_bp_member_foreign_type(<<EOS, 'foreign')
    【国　　籍　】アメリカ 
    【年　　齢　】26 
EOS

    assert_detect_bp_member_foreign_type(<<EOS, 'foreign')
    氏名：　 李Y　　韓国 
    日本語：　２級弱レベル 
EOS
  end

private
  def assert_detect_interview_count(body, expected_count)
    im = ImportMail.new
    im.mail_subject = ""
    im.mail_body = body
    im.analyze
    assert_equal(expected_count, im.interview_count)
  end

  def assert_detect_biz_offer_foreign_type(body, expected_foreign_type)
    im = ImportMail.new
    im.biz_offer_flg = 1
    im.mail_subject = ""
    im.mail_body = body
    im.analyze
    assert_equal(expected_foreign_type, im.foreign_type)
  end

  def assert_detect_bp_member_foreign_type(body, expected_foreign_type)
    im = ImportMail.new
    im.bp_member_flg = 1
    im.mail_subject = ""
    im.mail_body = body
    im.analyze
    assert_equal(expected_foreign_type, im.foreign_type)
  end
end
