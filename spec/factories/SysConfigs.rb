# -*- encoding: utf-8 -*-
FactoryGirl.define do
  factory :SysConfig do
    value2 ""
    value3 ""
    config_description_text ""
    lock_version 0
    created_user "initial"
    updated_user "initial"
    deleted 0

    trait :SysConfig001 do
      config_section "daily_report"
      config_key "send_mail"
      value1 "planning@applicative.jp"
    end

    trait :SysConfig002 do
      config_section "delivery_mails"
      config_key "return_path"
      value1 "dev.error@gr.applicative.jp"
    end

    trait :SysConfig003 do
      config_section "per_page_count"
      config_key "default"
      value1 "50"
    end

    factory :SysConfig_test001, traits: [:SysConfig001]
    factory :SysConfig_test002, traits: [:SysConfig002]
    factory :SysConfig_test003, traits: [:SysConfig003]
  end
end
