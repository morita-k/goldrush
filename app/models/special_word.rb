# -*- encoding: utf-8 -*-
class SpecialWord < ActiveRecord::Base
  include AutoTypeName

  before_save :clear_special_words_cache

  def clear_special_words_cache
    SpecialWord.clear_special_words_cache
  end

  def SpecialWord.clear_special_words_cache
    @@special_words = nil
  end
  SpecialWord.clear_special_words_cache

  def SpecialWord.bp_member_words(owner_id)
    get_special_words(owner_id, 'bp_member_word').map{|x| Regexp.new(x.target_word, Regexp::IGNORECASE)}
  end

  def SpecialWord.special_words(owner_id)
    get_special_words(owner_id, 'special_word')
  end

  def SpecialWord.ignore_words(owner_id)
    get_special_words(owner_id, 'ignore_word').map(&:target_word)
  end

  def SpecialWord.ignore_word_propers(owner_id)
    get_special_words(owner_id, 'ignore_word_proper').map(&:target_word)
  end

  def SpecialWord.country_words_foreign(owner_id)
    get_special_words(owner_id, 'country_word_foreign').map(&:target_word)
  end

  def SpecialWord.get_special_words(owner_id, special_word_type)
    require 'zen2han'
    unless @@special_words
      @@special_words = where(deleted: 0).each{|x| x.target_word = Zen2Han.toHan(x.target_word).downcase}
    end
    @@special_words.select {|x| x.owner_id == owner_id && x.special_word_type == special_word_type}
  end
end
