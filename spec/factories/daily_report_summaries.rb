# -*- encoding: utf-8 -*-
FactoryGirl.define do

  factory :DailyReportSummary do
    succeeds 31
    gross_profits 31
    interviews 31
    new_meetings 31
    exist_meetings 31
    send_delivery_mails 31
    report_date Date.new(2014, 1, 1)

    trait :test001 do
      user_id 1
    end

    trait :test002 do
      user_id 2
    end

    trait :test003 do
      user_id 2
      report_date Date.new(2014, 2, 1)
    end

    factory :daily_report_summary_test011, traits: [:test001]
    factory :daily_report_summary_test021, traits: [:test002]
    factory :daily_report_summary_test022, traits: [:test003]

  end
end
