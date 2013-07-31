# -*- encoding: utf-8 -*-
require 'test_helper'
require 'string_util'

class StringUtilTest < ActiveSupport::TestCase
   fixtures
   test "detect_words" do
     words = StringUtil.detect_words("")
     assert_equal [], words
     words = StringUtil.detect_words("aaa")
     assert_equal ["aaa"], words
     words = StringUtil.detect_words("aaa bbb")
     assert_equal ["aaa bbb"], words
     words = StringUtil.detect_words("aaa 日本語は無視bbb")
     assert_equal ["aaa","bbb"], words
     words = StringUtil.detect_words("Oracle8, C#, C++, UNIX-C, LINUX-C")
     assert_equal ["Oracle8","C#", "C++","UNIX-C","LINUX-C"].sort, words
     words = StringUtil.detect_words("VB.NET/PHP")
     assert_equal ["VB.NET","PHP"].sort, words
   end
   
   test"strip_with_full_size_space" do
     x = StringUtil.strip_with_full_size_space("　あああ　いいい　")
     assert_equal "あああ　いいい", x
   end
   
   test "splitplus" do
     res = StringUtil.splitplus("aaa")
     assert_equal ["aaa"], res
     res = StringUtil.splitplus("aaa+bbbb")
     assert_equal ["aaa","bbbb"], res
     res = StringUtil.splitplus("aaa++bbbb")
     assert_equal ["aaa++bbbb"], res
     res = StringUtil.splitplus("aaa+++bbbb")
     assert_equal ["aaa+++bbbb"], res
     res = StringUtil.splitplus("mysql+VC++")
     assert_equal ["mysql","VC++"], res
     res = StringUtil.splitplus("mysql+VC+++")
     assert_equal ["mysql","VC+++"], res
   end
   
  test "detect_payments" do
    res = StringUtil.detect_payments("")
    assert_equal [], res
    res = StringUtil.detect_payments("50万 50万 e90万円 60e万 800万")
    assert_equal ["50万","800万","90万"], res
  end
  
  test "detect_payments_value" do
    res = StringUtil.detect_payments("")
    assert_equal [], res
    res = StringUtil.detect_payments_value("50万 50万 e90万円 60e万 800万 00万")
    assert_equal ["00", "50","800","90"], res
  end
end
