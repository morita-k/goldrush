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
    assert_equal("39", im.age_text)
    assert_equal("90万", im.payment_text)
  end

  # test "shoud normalize age when import mail" do
  #   # テスト用メールソースの作成が必要
  # end

  test "shoud normalize age_text when execute to_normalize_age_all!" do
    ImportMail.to_normalize_age_all!
    assert_equal("20", ImportMail.find(2).age_text)
    assert_equal("30", ImportMail.find(3).age_text)
    assert_equal("40", ImportMail.find(4).age_text)
    assert_equal("50", ImportMail.find(5).age_text)
    assert_equal("その他", ImportMail.find(6).age_text)
  end

end