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

end
