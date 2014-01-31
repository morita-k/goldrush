# -*- encoding: utf-8 -*-
FactoryGirl.define do

  factory :User do
    id 1
    owner_id nil
    login "system@aaa.com"
    fullname ""
    shortname ""
    nickname "システム"
    access_level_type "super"
    per_page 50
    email "system@aaa.com"
    encrypted_password "$2a$10$ojHlby3zaA6ux5w8/1QINO9ALaPwYboB1eYxSXq4G6ZAaVmaTvadi"
    password "$2a$10$ojHlby3zaA6ux5w8/1QINO9ALaPwYboB1eYxSXq4G6ZAaVmaTvadi"
    reset_password_token nil
    reset_password_sent_at nil
    remember_created_at nil
    sign_in_count 0
    failed_attempts 0
    lock_version 0
    created_user "initial"
    updated_user "initial"
    deleted 0
  end
end