# -*- encoding: utf-8 -*-
FactoryGirl.define do

  factory :DailyReportSummary do
    succeed_count 31
    gross_profit_count 31
    interview_count 31
    new_meeting_count 31
    exist_meeting_count 31
    send_delivery_mail_count 31
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
