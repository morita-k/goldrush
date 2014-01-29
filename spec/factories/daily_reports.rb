# -*- encoding: utf-8 -*-
FactoryGirl.define do

  sequence :report_date01 do |n|
    Date.new(2014, 1, n)
  end

  sequence :report_date02 do |n|
    Date.new(2014, 1, n)
  end

  sequence :report_date03 do |n|
    Date.new(2013, 12, n)
  end

  factory :DailyReport do
    succeeds 1
    gross_profits 1
    interviews 1
    new_meetings 1
    exist_meetings 1
    contact_matter '連絡事項'
    report_date Date.new(2014, 1, 1)
    daily_report_input_type 'notinput'

    trait :test001 do
      user_id 1
    end

    trait :test002 do
      user_id 2
    end

    trait :test003 do
      user_id 2
      report_date Date.new(2014, 1, 2)
    end

    factory :daily_report_test011, traits: [:test001]
    factory :daily_report_test021, traits: [:test002]
    factory :daily_report_test022, traits: [:test003]

    factory :sequence_dates01, class: DailyReport do
      user_id 1
      report_date { FG.generate(:report_date01) }
    end

    factory :sequence_dates02, class: DailyReport do
      user_id 2
      report_date { FG.generate(:report_date02) }
    end

    factory :sequence_dates03, class: DailyReport do
      user_id 1
      report_date { FG.generate(:report_date03) }
    end
  end
end
