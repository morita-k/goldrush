# -*- encoding: utf-8 -*-

require 'test_helper'

class ImportMailTest < ActiveSupport::TestCase
  
  # test "shoud normalize age when import mail" do
  # 	# テスト用メールソースの作成が必要
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