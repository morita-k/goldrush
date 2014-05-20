# -*- encoding: utf-8 -*-
FactoryGirl.define do
  factory :SpecialWord do
    target_word 'test_target_word'
    convert_to_word 'test_convert_word'
    memo 'test_memo'
    lock_version 0
    created_user "initial"
    updated_user "initial"
    deleted 0

    trait :test001 do
      special_word_type 'special_word'
    end

    trait :test002 do
      special_word_type 'ignore_word'
    end

    trait :test003 do
      special_word_type 'ignore_word_proper'
    end

    factory :special_words_test011, traits: [:test001]
    factory :special_words_test021, traits: [:test002]
    factory :special_words_test031, traits: [:test003]
  end
end
