# -*- encoding: utf-8 -*-
require 'test_helper'

class HumanResourceTest < ActiveSupport::TestCase
  
  test "" do
  	assert_equal "23", HumanResource.normalize_age("23才")
  	assert_equal "30", HumanResource.normalize_age("３０歳")
  	# 変なデータは無視する
  	assert_equal "その他のﾃﾞｰﾀ", HumanResource.normalize_age("その他のデータ")
  end

end