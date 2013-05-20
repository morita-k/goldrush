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
end
