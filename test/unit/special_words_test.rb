# -*- encoding:utf-8 -*-
require 'test_helper'

class SpecialWordsTest < ActiveSupport::TestCase
  fixtures :special_words

  test "キャッシュがクリアされていること" do
    assert_nil SpecialWord.clear_special_words_cache
  end

  test "特別単語が取得できていること" do
    assert_not_nil SpecialWord.special_words
  end

  test "無視単語が取得できていること" do
    assert_not_nil SpecialWord.ignore_words
  end

  test "社員用無視が取得できていること" do
    assert_not_nil SpecialWord.ignore_word_propers
  end

  test "タイプが違う場合取得できないこと" do
    assert_empty SpecialWord.get_special_words("other")
  end
end