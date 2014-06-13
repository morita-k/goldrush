# -*- encoding: utf-8 -*-
require 'date'

FactoryGirl.define do

  factory :BaseDate do
    owner_id nil 
    day_of_week 0
    day_of_year 0
    lastday_flg 0

    trait :non_holiday do
      calendar_date Date::new(2014,12,31)
      holiday_flg 0
      comment1 "テスト平日"
    end

    trait :holiday1 do
      calendar_date Date::new(2015,1,1)
      holiday_flg 1
      comment1 "テスト祝日1"
    end

    trait :holiday2 do
      calendar_date Date::new(2015,4,29)
      holiday_flg 1
      comment1 "テスト祝日2"
    end

    trait :holiday3 do
      calendar_date Date::new(2015,5,5)
      holiday_flg 1
      comment1 "テスト祝日3"
    end

    lock_version 0
    created_user "initial"
    updated_user "initial"
    deleted 0

    factory :base_date_non_holiday, traits: [:non_holiday]
    factory :base_date_holiday1, traits: [:holiday1]
    factory :base_date_holiday2, traits: [:holiday2]
    factory :base_date_holiday3, traits: [:holiday3]
  end
end

