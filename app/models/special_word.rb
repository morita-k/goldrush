# -*- encoding: utf-8 -*-
class SpecialWord < ActiveRecord::Base
  include AutoTypeName

  before_save :clear_special_words_cache

  def clear_special_words_cache
    SpecialWord.clear_special_words_cache
  end

  def SpecialWord.clear_special_words_cache
    @@special_words = nil
    @@ignore_words = nil
    @@bad_proper_words = nil
    @@bp_member_words = nil
    @@country_words_foreign = nil
  end
  SpecialWord.clear_special_words_cache

  def SpecialWord.bp_member_words
    @@bp_member_words|| (@@bp_member_words = get_special_words('bp_member_word').map{|x| Regexp.new(x.target_word, Regexp::IGNORECASE)})
  end

  def SpecialWord.special_words
    @@special_words || (@@special_words = get_special_words('special_word'))
  end

  def SpecialWord.ignore_words
    @@ignore_words || (@@ignore_words = get_special_words('ignore_word').map{|x| x.target_word})
  end

  def SpecialWord.ignore_word_propers
    @@bad_proper_words || (@@bad_proper_words = get_special_words('ignore_word_proper').map{|x| x.target_word})
  end

  def SpecialWord.country_words_foreign
    @@country_words_foreign || (@@country_words_foreign = get_special_words('country_word_foreign').map{|x| x.target_word})
  end

  def SpecialWord.get_special_words(specialwordtype)
    require 'zen2han'
    specialword = where(deleted: 0, special_word_type: specialwordtype)
    specialword.map{|x|
      x.target_word = Zen2Han.toHan(x.target_word).downcase
    }

    return specialword
  end
end
