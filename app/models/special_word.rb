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
  end
  SpecialWord.clear_special_words_cache

  def SpecialWord.special_words
    @@special_words || (@@special_words = get_SpecialWords('special_word'))
  end

  def SpecialWord.ignore_words
    @@ignore_words || (@@ignore_words = get_SpecialWords('ignore_word').map{|x| x.target_word})
  end

  def SpecialWord.bad_proper_words
    @@bad_proper_words || (@@bad_proper_words = get_SpecialWords('ignore_word_proper').map{|x| x.target_word})
  end

  def SpecialWord.get_SpecialWords(specialwordtype)
    require 'zen2han'
    specialword = where(deleted: 0, special_word_type: specialwordtype)
    specialword.map{|x|
      x.target_word = Zen2Han.toHan(x.target_word)
    }

    return specialword
  end
end