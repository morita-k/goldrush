# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "analysis_template_items", :force => true do |t|
    t.integer  "owner_id",                    :limit => 8
    t.integer  "analysis_template_id",        :limit => 8,                 :null => false
    t.string   "analysis_template_item_name",                              :null => false
    t.string   "pattern",                                                  :null => false
    t.integer  "ignore_flg",                                :default => 0
    t.string   "target_table_name"
    t.string   "target_column_name"
    t.text     "before_set_code"
    t.text     "after_set_code"
    t.text     "memo"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.integer  "lock_version",                :limit => 8,  :default => 0
    t.string   "created_user",                :limit => 80
    t.string   "updated_user",                :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                   :default => 0
  end

  add_index "analysis_template_items", ["id"], :name => "id", :unique => true

  create_table "analysis_templates", :force => true do |t|
    t.integer  "owner_id",               :limit => 8
    t.integer  "business_partner_id",    :limit => 8
    t.integer  "bp_pic_id",              :limit => 8
    t.string   "analysis_template_name",                              :null => false
    t.string   "analysis_template_type", :limit => 40,                :null => false
    t.text     "memo"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "lock_version",           :limit => 8,  :default => 0
    t.string   "created_user",           :limit => 80
    t.string   "updated_user",           :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                              :default => 0
  end

  add_index "analysis_templates", ["id"], :name => "id", :unique => true

  create_table "announcements", :force => true do |t|
    t.integer  "owner_id",         :limit => 8
    t.string   "announce_section", :limit => 40,                :null => false
    t.string   "announce_key",     :limit => 40,                :null => false
    t.string   "announce_subject"
    t.string   "announce_message"
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "lock_version",     :limit => 8,  :default => 0
    t.string   "created_user",     :limit => 80
    t.string   "updated_user",     :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                        :default => 0
  end

  add_index "announcements", ["id"], :name => "id", :unique => true

  create_table "annual_vacations", :force => true do |t|
    t.integer  "owner_id",                :limit => 8
    t.integer  "user_id",                 :limit => 8
    t.integer  "year",                    :limit => 8
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "day_total",               :limit => 8,  :default => 0
    t.integer  "used_total",              :limit => 8,  :default => 0
    t.integer  "previous_year_day_total", :limit => 8,  :default => 0
    t.integer  "life_plan_flg",           :limit => 8,  :default => 0
    t.integer  "life_plan_day_total",     :limit => 8,  :default => 0
    t.integer  "life_plan_used_total",    :limit => 8,  :default => 0
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "lock_version",            :limit => 8,  :default => 0
    t.string   "created_user",            :limit => 80
    t.string   "updated_user",            :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                               :default => 0
  end

  add_index "annual_vacations", ["id"], :name => "id", :unique => true

  create_table "application_approvals", :force => true do |t|
    t.integer  "owner_id",              :limit => 8
    t.integer  "user_id",               :limit => 8
    t.integer  "approval_authority_id", :limit => 8
    t.integer  "base_application_id",   :limit => 8
    t.string   "application_type",      :limit => 40
    t.date     "application_date"
    t.integer  "approver_id",           :limit => 8
    t.string   "approval_status_type",  :limit => 40
    t.date     "approval_date"
    t.integer  "approval_order",        :limit => 8
    t.text     "memo"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "lock_version",          :limit => 8,  :default => 0
    t.string   "created_user",          :limit => 80
    t.string   "updated_user",          :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                             :default => 0
  end

  add_index "application_approvals", ["id"], :name => "id", :unique => true

  create_table "approaches", :force => true do |t|
    t.integer  "owner_id",                        :limit => 8
    t.integer  "biz_offer_id",                    :limit => 8,                 :null => false
    t.integer  "bp_member_id",                    :limit => 8,                 :null => false
    t.string   "approach_status_type",            :limit => 40,                :null => false
    t.datetime "approached_at"
    t.integer  "approach_pic_id",                 :limit => 8
    t.date     "approach_start_date"
    t.date     "can_interview_date"
    t.integer  "approach_upper_contract_term_id", :limit => 8,                 :null => false
    t.integer  "approach_down_contract_term_id",  :limit => 8,                 :null => false
    t.text     "memo"
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.integer  "lock_version",                    :limit => 8,  :default => 0
    t.string   "created_user",                    :limit => 80
    t.string   "updated_user",                    :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                       :default => 0
  end

  add_index "approaches", ["id"], :name => "id", :unique => true

  create_table "approval_authorities", :force => true do |t|
    t.integer  "owner_id",      :limit => 8
    t.integer  "user_id",       :limit => 8
    t.integer  "approver_id",   :limit => 8
    t.string   "approver_type", :limit => 40
    t.integer  "active_flg",                  :default => 0
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.integer  "lock_version",  :limit => 8,  :default => 0
    t.string   "created_user",  :limit => 80
    t.string   "updated_user",  :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                     :default => 0
  end

  add_index "approval_authorities", ["id"], :name => "id", :unique => true

  create_table "attachment_files", :force => true do |t|
    t.integer  "owner_id",          :limit => 8
    t.string   "parent_table_name",                              :null => false
    t.integer  "parent_id",         :limit => 8
    t.string   "file_name",                                      :null => false
    t.string   "extention",                                      :null => false
    t.string   "file_path",                                      :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "lock_version",      :limit => 8,  :default => 0
    t.string   "created_user",      :limit => 80
    t.string   "updated_user",      :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                         :default => 0
  end

  add_index "attachment_files", ["id"], :name => "id", :unique => true

  create_table "base_applications", :force => true do |t|
    t.integer  "owner_id",                :limit => 8
    t.integer  "user_id",                 :limit => 8
    t.string   "application_type",        :limit => 40
    t.string   "approval_status_type",    :limit => 40
    t.date     "approval_date"
    t.date     "application_date"
    t.integer  "accounting_approval_flg",               :default => 0
    t.integer  "unfixed_flg",                           :default => 0
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "lock_version",            :limit => 8,  :default => 0
    t.string   "created_user",            :limit => 80
    t.string   "updated_user",            :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                               :default => 0
  end

  add_index "base_applications", ["id"], :name => "id", :unique => true

  create_table "base_dates", :force => true do |t|
    t.integer  "owner_id",      :limit => 8
    t.date     "calendar_date",                              :null => false
    t.integer  "day_of_week",                 :default => 0
    t.integer  "day_of_year",                 :default => 0
    t.integer  "lastday_flg",                 :default => 0
    t.integer  "holiday_flg",                 :default => 0
    t.text     "comment1"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.integer  "lock_version",  :limit => 8,  :default => 0
    t.string   "created_user",  :limit => 80
    t.string   "updated_user",  :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                     :default => 0
  end

  add_index "base_dates", ["id"], :name => "id", :unique => true

  create_table "base_months", :force => true do |t|
    t.integer  "owner_id",     :limit => 8
    t.integer  "report_month", :limit => 8,                 :null => false
    t.date     "start_date",                                :null => false
    t.date     "end_date",                                  :null => false
    t.integer  "last_flg",                   :default => 0
    t.integer  "current_flg",                :default => 0
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "lock_version", :limit => 8,  :default => 0
    t.string   "created_user", :limit => 80
    t.string   "updated_user", :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                    :default => 0
  end

  add_index "base_months", ["id"], :name => "id", :unique => true

  create_table "biz_offers", :force => true do |t|
    t.integer  "owner_id",                :limit => 8
    t.integer  "business_id",             :limit => 8,                                                  :null => false
    t.integer  "business_partner_id",     :limit => 8,                                                  :null => false
    t.integer  "bp_pic_id",               :limit => 8,                                                  :null => false
    t.string   "biz_offer_status_type",   :limit => 40,                                                 :null => false
    t.datetime "biz_offered_at",                                                                        :null => false
    t.date     "due_date"
    t.integer  "reprint_flg",                                                          :default => 0
    t.string   "winning_rate"
    t.string   "sales_route"
    t.integer  "contact_pic_id",          :limit => 8
    t.integer  "sales_pic_id",            :limit => 8
    t.string   "payment_text"
    t.decimal  "payment_max",                           :precision => 12, :scale => 2, :default => 0.0
    t.string   "time_adjust_text"
    t.integer  "skill_consideration_flg",                                              :default => 0
    t.integer  "interview_times",         :limit => 8,                                 :default => 0
    t.string   "interview_times_memo"
    t.string   "sales_route_limit"
    t.text     "application_format"
    t.integer  "import_mail_id",          :limit => 8
    t.text     "memo"
    t.datetime "created_at",                                                                            :null => false
    t.datetime "updated_at",                                                                            :null => false
    t.integer  "lock_version",            :limit => 8,                                 :default => 0
    t.string   "created_user",            :limit => 80
    t.string   "updated_user",            :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                              :default => 0
  end

  add_index "biz_offers", ["id"], :name => "id", :unique => true

  create_table "bp_members", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "human_resource_id",   :limit => 8,                                                  :null => false
    t.integer  "business_partner_id", :limit => 8,                                                  :null => false
    t.integer  "bp_pic_id",           :limit => 8,                                                  :null => false
    t.string   "employment_type",     :limit => 40,                                                 :null => false
    t.integer  "reprint_flg",                                                      :default => 0
    t.date     "can_start_date"
    t.date     "can_interview_date"
    t.string   "race_condition"
    t.string   "payment_memo"
    t.decimal  "payment_min",                       :precision => 12, :scale => 2, :default => 0.0
    t.integer  "import_mail_id",      :limit => 8
    t.string   "time_adjust_term"
    t.text     "memo"
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "lock_version",        :limit => 8,                                 :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                          :default => 0
  end

  add_index "bp_members", ["id"], :name => "id", :unique => true

  create_table "bp_pic_group_details", :force => true do |t|
    t.integer  "owner_id",        :limit => 8
    t.integer  "bp_pic_group_id", :limit => 8,                 :null => false
    t.integer  "bp_pic_id",       :limit => 8,                 :null => false
    t.integer  "suspended",                     :default => 0
    t.text     "memo"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "lock_version",    :limit => 8,  :default => 0
    t.string   "created_user",    :limit => 80
    t.string   "updated_user",    :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                       :default => 0
  end

  add_index "bp_pic_group_details", ["id"], :name => "id", :unique => true

  create_table "bp_pic_groups", :force => true do |t|
    t.integer  "owner_id",          :limit => 8
    t.string   "bp_pic_group_name",                              :null => false
    t.text     "memo"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "lock_version",      :limit => 8,  :default => 0
    t.string   "created_user",      :limit => 80
    t.string   "updated_user",      :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                         :default => 0
  end

  add_index "bp_pic_groups", ["id"], :name => "id", :unique => true

  create_table "bp_pics", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "business_partner_id", :limit => 8,                   :null => false
    t.string   "bp_pic_name",                                        :null => false
    t.string   "bp_pic_short_name",                                  :null => false
    t.string   "bp_pic_name_kana",                                   :null => false
    t.string   "depertment"
    t.string   "position"
    t.string   "tel_direct",          :limit => 40
    t.string   "tel_mobile",          :limit => 40
    t.string   "email1",                                             :null => false
    t.string   "email2"
    t.date     "contact_date"
    t.integer  "sales_pic_id",        :limit => 8
    t.integer  "contact_mail_flg"
    t.integer  "nondelivery_score",                 :default => 0
    t.integer  "starred",                           :default => 0
    t.float    "rating",                            :default => 0.0
    t.integer  "import_mail_id",      :limit => 8
    t.string   "tag_text"
    t.text     "memo"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "lock_version",        :limit => 8,  :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                           :default => 0
  end

  add_index "bp_pics", ["id"], :name => "id", :unique => true

  create_table "business_partners", :force => true do |t|
    t.integer  "owner_id",                    :limit => 8
    t.string   "sales_code",                  :limit => 80
    t.string   "business_partner_code",       :limit => 80
    t.string   "sales_management_code",       :limit => 80
    t.string   "business_partner_name",                                      :null => false
    t.string   "business_partner_short_name",                                :null => false
    t.string   "business_partner_name_kana"
    t.string   "business_partner_name_en"
    t.string   "sales_status_type",           :limit => 40,                  :null => false
    t.string   "basic_contract_status_type", :limit => 40,                  :null => false
    t.string   "nda_status_type",             :limit => 40,                  :null => false
    t.string   "ceo_name"
    t.string   "url"
    t.string   "zip",                         :limit => 40
    t.string   "address1"
    t.string   "address2"
    t.string   "tel",                         :limit => 40
    t.string   "fax",                         :limit => 40
    t.string   "email"
    t.string   "category"
    t.integer  "self_flg",                                  :default => 0
    t.integer  "eu_flg",                                    :default => 0
    t.integer  "upper_flg",                                 :default => 0
    t.integer  "down_flg",                                  :default => 0
    t.integer  "starred",                                   :default => 0
    t.float    "rating",                                    :default => 0.0
    t.integer  "import_mail_id",              :limit => 8
    t.string   "tag_text"
    t.text     "memo"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.integer  "lock_version",                :limit => 8,  :default => 0
    t.string   "created_user",                :limit => 80
    t.string   "updated_user",                :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                   :default => 0
  end

  add_index "business_partners", ["id"], :name => "id", :unique => true

  create_table "business_trip_applications", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "user_id",             :limit => 8
    t.integer  "base_application_id", :limit => 8
    t.date     "application_date"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "day_total",           :limit => 8
    t.string   "reason"
    t.string   "content"
    t.string   "location"
    t.string   "client"
    t.string   "book_no",             :limit => 40
    t.decimal  "approximate_amount",                :precision => 12, :scale => 2
    t.integer  "active_flg",                                                       :default => 0
    t.integer  "sales_person_id",     :limit => 8
    t.text     "memo"
    t.datetime "created_at",                                                                      :null => false
    t.datetime "updated_at",                                                                      :null => false
    t.integer  "lock_version",        :limit => 8,                                 :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                          :default => 0
  end

  add_index "business_trip_applications", ["id"], :name => "id", :unique => true

  create_table "businesses", :force => true do |t|
    t.integer  "owner_id",             :limit => 8
    t.integer  "eubp_id",              :limit => 8
    t.integer  "eubp_pic_id",          :limit => 8
    t.string   "business_status_type", :limit => 40,                  :null => false
    t.datetime "issue_datetime",                                      :null => false
    t.date     "due_date"
    t.string   "term_type",            :limit => 40
    t.string   "business_title",                                      :null => false
    t.string   "business_point"
    t.string   "business_description"
    t.integer  "member_change_flg",                  :default => 0
    t.string   "place"
    t.string   "period"
    t.string   "phase"
    t.integer  "need_count",           :limit => 8
    t.string   "skill_title"
    t.string   "skill_must"
    t.string   "skill_want"
    t.string   "skill_tag"
    t.string   "business_hours"
    t.integer  "assumed_hour",         :limit => 8
    t.string   "career_years"
    t.string   "age_limit"
    t.string   "nationality_limit"
    t.string   "sex_limit"
    t.string   "communication"
    t.integer  "starred",                            :default => 0
    t.float    "rating",                             :default => 0.0
    t.text     "link",                  :limit => 1000
    t.text     "memo"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "lock_version",         :limit => 8,  :default => 0
    t.string   "created_user",         :limit => 80
    t.string   "updated_user",         :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                            :default => 0
  end

  add_index "businesses", ["id"], :name => "id", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "owner_id",                :limit => 8
    t.integer  "weekly_report_id",        :limit => 8
    t.integer  "application_approval_id", :limit => 8
    t.integer  "user_id",                 :limit => 8
    t.date     "comment_date"
    t.text     "content"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "lock_version",            :limit => 8,  :default => 0
    t.string   "created_user",            :limit => 80
    t.string   "updated_user",            :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                               :default => 0
  end

  add_index "comments", ["id"], :name => "id", :unique => true

  create_table "contact_histories", :force => true do |t|
    t.integer  "owner_id",                  :limit => 8
    t.integer  "contact_user_id",           :limit => 8,                 :null => false
    t.integer  "business_partner_id",       :limit => 8,                 :null => false
    t.datetime "contacted_at",                                           :null => false
    t.string   "business_partner_pic_name"
    t.string   "contact_reason"
    t.text     "contact_content"
    t.string   "contact_result"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "lock_version",              :limit => 8,  :default => 0
    t.string   "created_user",              :limit => 80
    t.string   "updated_user",              :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                 :default => 0
  end

  add_index "contact_histories", ["id"], :name => "id", :unique => true

  create_table "contract_terms", :force => true do |t|
    t.integer  "owner_id",               :limit => 8
    t.string   "term_type",              :limit => 40,                                                 :null => false
    t.decimal  "payment",                              :precision => 12, :scale => 2, :default => 0.0
    t.integer  "time_adjust_flg",        :limit => 8
    t.integer  "time_adjust_upper",      :limit => 8
    t.integer  "time_adjust_limit",      :limit => 8
    t.integer  "time_adjust_under",      :limit => 8
    t.string   "time_adjust_type",       :limit => 40,                                                 :null => false
    t.decimal  "over_time_payment",                    :precision => 12, :scale => 2, :default => 0.0
    t.decimal  "under_time_penalty",                   :precision => 12, :scale => 2, :default => 0.0
    t.integer  "cutoff_date",            :limit => 8
    t.string   "payment_sight_type",     :limit => 40,                                                 :null => false
    t.date     "contract_end_date"
    t.integer  "contract_renewal_unit",  :limit => 8
    t.text     "contract_renewal_terms"
    t.text     "other_terms"
    t.text     "memo"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
    t.integer  "lock_version",           :limit => 8,                                 :default => 0
    t.string   "created_user",           :limit => 80
    t.string   "updated_user",           :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                             :default => 0
  end

  add_index "contract_terms", ["id"], :name => "id", :unique => true

  create_table "contracts", :force => true do |t|
    t.integer  "owner_id",               :limit => 8
    t.integer  "approach_id",            :limit => 8,                 :null => false
    t.string   "contract_status_type",   :limit => 40,                :null => false
    t.datetime "closed_at",                                           :null => false
    t.datetime "contracted_at"
    t.integer  "contract_pic_id",        :limit => 8
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "upper_contract_term_id", :limit => 8
    t.integer  "down_contract_term_id",  :limit => 8
    t.text     "memo"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "lock_version",           :limit => 8,  :default => 0
    t.string   "created_user",           :limit => 80
    t.string   "updated_user",           :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                              :default => 0
  end

  add_index "contracts", ["id"], :name => "id", :unique => true

  create_table "daily_workings", :force => true do |t|
    t.integer  "owner_id",               :limit => 8
    t.integer  "user_id",                :limit => 8
    t.integer  "base_date_id",           :limit => 8
    t.integer  "weekly_report_id",       :limit => 8
    t.integer  "monthly_working_id",     :limit => 8
    t.string   "working_type",           :limit => 40
    t.date     "application_date"
    t.date     "working_date"
    t.integer  "in_time",                :limit => 8
    t.integer  "out_time",               :limit => 8
    t.integer  "rest_hour",              :limit => 8
    t.integer  "hour_total",             :limit => 8
    t.integer  "over_time",              :limit => 8
    t.integer  "come_lately_flg",                      :default => 0
    t.integer  "leave_early_flg",                      :default => 0
    t.integer  "direct_in_flg",                        :default => 0
    t.integer  "direct_out_flg",                       :default => 0
    t.integer  "over_time_taxi_flg",                   :default => 0
    t.integer  "over_time_meel_flg",                   :default => 0
    t.string   "location"
    t.string   "summary"
    t.string   "action_type",            :limit => 40
    t.integer  "holiday_flg",                          :default => 0
    t.integer  "delayed_cancel_flg",                   :default => 0
    t.integer  "delayed_cancel_user_id", :limit => 8
    t.integer  "taxi_flg",                             :default => 0
    t.integer  "business_trip_flg",                    :default => 0
    t.text     "memo"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "lock_version",           :limit => 8,  :default => 0
    t.string   "created_user",           :limit => 80
    t.string   "updated_user",           :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                              :default => 0
  end

  add_index "daily_workings", ["id"], :name => "id", :unique => true
  add_index "daily_workings", ["user_id", "base_date_id"], :name => "idx_daily_workings_7", :unique => true
  add_index "daily_workings", ["user_id", "working_date"], :name => "idx_daily_workings_6", :unique => true

  create_table "delivery_errors", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "business_partner_id", :limit => 8
    t.integer  "bp_pic_id",           :limit => 8
    t.string   "email"
    t.string   "mail_error_type",     :limit => 40,                :null => false
    t.text     "mail_error_text"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "lock_version",        :limit => 8,  :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                           :default => 0
  end

  add_index "delivery_errors", ["id"], :name => "id", :unique => true

  create_table "delivery_mail_targets", :force => true do |t|
    t.integer  "owner_id",         :limit => 8
    t.integer  "delivery_mail_id", :limit => 8,                 :null => false
    t.integer  "bp_pic_id",        :limit => 8,                 :null => false
    t.string   "message_id"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "lock_version",     :limit => 8,  :default => 0
    t.string   "created_user",     :limit => 80
    t.string   "updated_user",     :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                        :default => 0
  end

  add_index "delivery_mail_targets", ["id"], :name => "id", :unique => true

  create_table "delivery_mails", :force => true do |t|
    t.integer  "owner_id",              :limit => 8
    t.integer  "bp_pic_group_id",       :limit => 8
    t.string   "mail_status_type",      :limit => 40,                        :null => false
    t.string   "subject",                                                    :null => false
    t.text     "content",               :limit => 2147483647,                :null => false
    t.string   "mail_from_name",                                             :null => false
    t.string   "mail_from",                                                  :null => false
    t.string   "mail_cc"
    t.string   "mail_bcc"
    t.datetime "planned_setting_at",                                         :null => false
    t.string   "mail_send_status_type", :limit => 40,                        :null => false
    t.datetime "send_end_at"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.integer  "lock_version",          :limit => 8,          :default => 0
    t.string   "created_user",          :limit => 80
    t.string   "updated_user",          :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                     :default => 0
  end

  add_index "delivery_mails", ["id"], :name => "id", :unique => true

  create_table "departments", :force => true do |t|
    t.integer  "owner_id",             :limit => 8
    t.string   "department_code",      :limit => 40,                 :null => false
    t.string   "department_name",      :limit => 100,                :null => false
    t.string   "department_shortname", :limit => 100,                :null => false
    t.integer  "display_order",        :limit => 8,   :default => 0
    t.text     "memo"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "lock_version",         :limit => 8,   :default => 0
    t.string   "created_user",         :limit => 80
    t.string   "updated_user",         :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                             :default => 0
  end

  add_index "departments", ["id"], :name => "id", :unique => true

  create_table "employees", :force => true do |t|
    t.integer  "owner_id",             :limit => 8
    t.integer  "user_id",              :limit => 8
    t.integer  "department_id",        :limit => 8
    t.string   "employee_type",        :limit => 40,                 :null => false
    t.string   "position",             :limit => 100
    t.string   "employee_code",        :limit => 40,                 :null => false
    t.string   "insurance_code",       :limit => 40
    t.string   "employee_name",        :limit => 100,                :null => false
    t.string   "employee_kana_name",   :limit => 100,                :null => false
    t.string   "employee_short_name",  :limit => 100,                :null => false
    t.date     "birthday_date",                                      :null => false
    t.string   "sex_type",             :limit => 40,                 :null => false
    t.string   "email",                :limit => 40
    t.string   "zip1",                 :limit => 40
    t.string   "address1_1"
    t.string   "address1_2"
    t.string   "address1_3"
    t.string   "address1_4"
    t.string   "tel1",                 :limit => 40
    t.string   "fax",                  :limit => 40
    t.string   "mobile",               :limit => 40
    t.string   "mobile_email",         :limit => 40
    t.string   "name2",                :limit => 100
    t.string   "zip2",                 :limit => 40
    t.string   "address2_1"
    t.string   "address2_2"
    t.string   "address2_3"
    t.string   "address2_4"
    t.string   "tel2",                 :limit => 40
    t.string   "zip3",                 :limit => 40
    t.string   "address3_1"
    t.string   "address3_2"
    t.string   "address3_3"
    t.string   "address3_4"
    t.string   "tel3",                 :limit => 40
    t.date     "entry_date",                                         :null => false
    t.date     "resignation_date"
    t.string   "resignation_reason"
    t.string   "attached_file1"
    t.string   "attached_file2"
    t.string   "attached_file3"
    t.string   "attached_file4"
    t.string   "bank_name",            :limit => 100
    t.string   "branch_name",          :limit => 100
    t.string   "account_type",         :limit => 40
    t.string   "account_number",       :limit => 40
    t.string   "account_name"
    t.date     "active_date"
    t.date     "inactive_date"
    t.integer  "leave_day",            :limit => 8,   :default => 0
    t.integer  "active_flg",                          :default => 0
    t.integer  "approver_flg",                        :default => 0
    t.integer  "credit_card_flg",                     :default => 0
    t.integer  "regular_working_hour", :limit => 8,   :default => 0
    t.text     "memo"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "lock_version",         :limit => 8,   :default => 0
    t.string   "created_user",         :limit => 80
    t.string   "updated_user",         :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                             :default => 0
  end

  add_index "employees", ["id"], :name => "id", :unique => true

  create_table "expense_applications", :force => true do |t|
    t.integer  "owner_id",                :limit => 8
    t.integer  "user_id",                 :limit => 8
    t.integer  "base_application_id",     :limit => 8
    t.string   "expense_app_type",        :limit => 40,                                                :null => false
    t.date     "application_date"
    t.date     "plan_buy_date"
    t.date     "preferred_date"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "day_total",               :limit => 8
    t.string   "book_no",                 :limit => 40
    t.string   "account_item",            :limit => 40
    t.string   "purpose"
    t.string   "content"
    t.string   "client",                  :limit => 100
    t.string   "location"
    t.integer  "participation_number",    :limit => 8
    t.string   "company_name",            :limit => 80
    t.string   "participant_name",        :limit => 80
    t.string   "staff_name",              :limit => 80
    t.string   "remark"
    t.string   "attached_material"
    t.string   "attached_material_name"
    t.string   "payment_no",              :limit => 100
    t.string   "payee_name",              :limit => 100
    t.string   "payee_name_kana",         :limit => 100
    t.string   "payee_zip",               :limit => 40
    t.string   "payee_address"
    t.string   "payee_tel",               :limit => 40
    t.string   "payee_bank_name",         :limit => 100
    t.string   "payee_branch_name",       :limit => 100
    t.string   "payee_account_name",      :limit => 100
    t.string   "payee_account_name_kana", :limit => 100
    t.string   "account_type",            :limit => 40
    t.string   "account_number",          :limit => 40
    t.string   "work_place_zip",          :limit => 40
    t.string   "work_place_address"
    t.string   "work_place_tel",          :limit => 40
    t.string   "work_place_fax",          :limit => 40
    t.string   "unit1",                   :limit => 100
    t.string   "unit2",                   :limit => 100
    t.string   "abstract"
    t.string   "production_name",         :limit => 100
    t.string   "contact_person",          :limit => 100
    t.string   "payment_method_type",     :limit => 40
    t.decimal  "payment_amount",                         :precision => 12, :scale => 2
    t.decimal  "withholding_tax",                        :precision => 12, :scale => 2
    t.decimal  "other_expenses",                         :precision => 12, :scale => 2
    t.decimal  "approximate_amount",                     :precision => 12, :scale => 2
    t.integer  "temporary_app_flg",                                                     :default => 0
    t.integer  "temporary_scrip_flg",                                                   :default => 0
    t.integer  "payment_flg",                                                           :default => 0
    t.date     "payment_date"
    t.string   "app_status_type",         :limit => 40
    t.integer  "sales_person_id",         :limit => 8
    t.text     "memo"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
    t.integer  "lock_version",            :limit => 8,                                  :default => 0
    t.string   "created_user",            :limit => 80
    t.string   "updated_user",            :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                               :default => 0
  end

  add_index "expense_applications", ["id"], :name => "id", :unique => true

  create_table "expense_details", :force => true do |t|
    t.integer  "owner_id",                     :limit => 8
    t.integer  "user_id",                      :limit => 8
    t.integer  "expense_application_id",       :limit => 8
    t.integer  "business_trip_application_id", :limit => 8
    t.integer  "payment_per_month_id",         :limit => 8
    t.integer  "payment_per_case_id",          :limit => 8
    t.string   "expense_type",                 :limit => 40
    t.date     "buy_date"
    t.string   "book_no",                      :limit => 40
    t.string   "account_item",                 :limit => 40
    t.string   "purpose"
    t.string   "content"
    t.decimal  "amount",                                     :precision => 12, :scale => 2
    t.integer  "business_trip_flg",                                                         :default => 0
    t.integer  "temporary_flg",                                                             :default => 0
    t.integer  "temporary_scrip_flg",                                                       :default => 0
    t.integer  "temporary_payment_flg",                                                     :default => 0
    t.integer  "credit_card_flg",                                                           :default => 0
    t.string   "cutoff_status_type",           :limit => 40
    t.text     "memo"
    t.datetime "created_at",                                                                               :null => false
    t.datetime "updated_at",                                                                               :null => false
    t.integer  "lock_version",                 :limit => 8,                                 :default => 0
    t.string   "created_user",                 :limit => 80
    t.string   "updated_user",                 :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                                   :default => 0
  end

  add_index "expense_details", ["id"], :name => "id", :unique => true

  create_table "holiday_applications", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "user_id",             :limit => 8
    t.integer  "base_application_id", :limit => 8
    t.string   "working_type",        :limit => 40
    t.date     "application_date"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "start_time",          :limit => 8
    t.integer  "end_time",            :limit => 8
    t.integer  "day_total",           :limit => 8
    t.integer  "hour_total",          :limit => 8,  :default => 0
    t.string   "reason"
    t.string   "content"
    t.integer  "taxi_flg",                          :default => 0
    t.integer  "active_flg",                        :default => 0
    t.text     "memo"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "lock_version",        :limit => 8,  :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                           :default => 0
  end

  add_index "holiday_applications", ["id"], :name => "id", :unique => true

  create_table "human_resources", :force => true do |t|
    t.integer  "owner_id",                   :limit => 8
    t.string   "human_resource_name"
    t.string   "human_resource_short_name"
    t.string   "human_resource_name_kana"
    t.string   "initial",                    :limit => 80,                  :null => false
    t.string   "email"
    t.string   "tel1",                       :limit => 40
    t.string   "tel2",                       :limit => 40
    t.string   "age",                        :limit => 40
    t.date     "birthday_date"
    t.string   "sex_type",                   :limit => 40
    t.string   "nationality"
    t.string   "railroad"
    t.string   "near_station"
    t.string   "max_move_time"
    t.string   "experience"
    t.string   "skill_title"
    t.text     "business_skill"
    t.text     "skill"
    t.string   "skill_tag"
    t.text     "qualification"
    t.string   "communication_type",         :limit => 40,                  :null => false
    t.string   "attendance"
    t.string   "human_resource_status_type", :limit => 40
    t.integer  "starred",                                  :default => 0
    t.float    "rating",                                   :default => 0.0
    t.string   "link",                         :limit => 1000
    t.text     "memo"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.integer  "lock_version",               :limit => 8,  :default => 0
    t.string   "created_user",               :limit => 80
    t.string   "updated_user",               :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                  :default => 0
  end

  add_index "human_resources", ["id"], :name => "id", :unique => true

  create_table "import_mails", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "business_partner_id", :limit => 8
    t.integer  "bp_pic_id",           :limit => 8
    t.string   "in_reply_to"
    t.datetime "received_at",                                              :null => false
    t.string   "mail_subject",        :limit => 1024,                      :null => false
    t.text     "mail_body",                                                :null => false
    t.string   "mail_from",                                                :null => false
    t.string   "mail_sender_name",                                         :null => false
    t.string   "mail_to",             :limit => 1024
    t.string   "mail_cc",             :limit => 1024
    t.string   "mail_bcc",            :limit => 1024
    t.text     "message_source",      :limit => 2147483647,                :null => false
    t.string   "message_id"
    t.integer  "biz_offer_flg",                             :default => 0
    t.integer  "bp_member_flg",                             :default => 0
    t.integer  "registed",                                  :default => 0
    t.integer  "unwanted",                                  :default => 0
    t.text     "tag_text"
    t.string   "payment_text"
    t.string   "age_text"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.integer  "lock_version",        :limit => 8,          :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                   :default => 0
  end

  add_index "import_mails", ["id"], :name => "id", :unique => true

  create_table "interviews", :force => true do |t|
    t.integer  "owner_id",              :limit => 8
    t.integer  "approach_id",           :limit => 8,                 :null => false
    t.string   "interview_status_type", :limit => 40,                :null => false
    t.integer  "interview_number",      :limit => 8
    t.datetime "interview_appoint_at"
    t.string   "interview_prace"
    t.integer  "interview_pic_id",      :limit => 8
    t.integer  "interview_bp_id",       :limit => 8
    t.integer  "interview_bp_pic_id",   :limit => 8
    t.integer  "succeed",                             :default => 0
    t.text     "memo"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "lock_version",          :limit => 8,  :default => 0
    t.string   "created_user",          :limit => 80
    t.string   "updated_user",          :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                             :default => 0
  end

  add_index "interviews", ["id"], :name => "id", :unique => true

  create_table "mail_templates", :force => true do |t|
    t.integer  "owner_id",               :limit => 8
    t.string   "mail_template_category",                              :null => false
    t.string   "mail_template_name",                                  :null => false
    t.string   "subject",                                             :null => false
    t.text     "content",                                             :null => false
    t.string   "mail_from_name"
    t.string   "mail_from"
    t.string   "mail_cc"
    t.string   "mail_bcc"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "lock_version",           :limit => 8,  :default => 0
    t.string   "created_user",           :limit => 80
    t.string   "updated_user",           :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                              :default => 0
  end

  add_index "mail_templates", ["id"], :name => "id", :unique => true

  create_table "monthly_workings", :force => true do |t|
    t.integer  "owner_id",                       :limit => 8
    t.integer  "user_id",                        :limit => 8
    t.integer  "base_application_id",            :limit => 8
    t.integer  "base_month_id",                  :limit => 8
    t.date     "application_date"
    t.integer  "report_month",                   :limit => 8
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "last_flg",                                     :default => 0
    t.integer  "next_time_flg",                                :default => 0
    t.integer  "labor_day_total",                :limit => 8,  :default => 0
    t.integer  "compensatory_hour_total",        :limit => 8,  :default => 0
    t.integer  "compensatory_used_total",        :limit => 8,  :default => 0
    t.integer  "pre_comp_used_total",            :limit => 8,  :default => 0
    t.integer  "working_day_total",              :limit => 8,  :default => 0
    t.integer  "remain_total",                   :limit => 8,  :default => 0
    t.integer  "compensatory_remain_total",      :limit => 8,  :default => 0
    t.integer  "cutoff_day_total",               :limit => 8,  :default => 0
    t.integer  "cutoff_compensatory_hour_total", :limit => 8,  :default => 0
    t.integer  "summer_vacation_remain_total",   :limit => 8,  :default => 0
    t.integer  "life_plan_remain_total",         :limit => 8,  :default => 0
    t.integer  "hold_flg",                                     :default => 0
    t.text     "memo"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.integer  "lock_version",                   :limit => 8,  :default => 0
    t.string   "created_user",                   :limit => 80
    t.string   "updated_user",                   :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                      :default => 0
  end

  add_index "monthly_workings", ["id"], :name => "id", :unique => true

  create_table "names", :force => true do |t|
    t.integer  "owner_id",         :limit => 8
    t.string   "name_lcale",       :limit => 40,                 :null => false
    t.string   "name_section",     :limit => 40,                 :null => false
    t.string   "name_key",         :limit => 40,                 :null => false
    t.string   "long_name",        :limit => 100,                :null => false
    t.string   "short_name",       :limit => 100,                :null => false
    t.string   "other_name",       :limit => 100,                :null => false
    t.string   "name_description"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "lock_version",     :limit => 8,   :default => 0
    t.string   "created_user",     :limit => 80
    t.string   "updated_user",     :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                         :default => 0
  end

  add_index "names", ["id"], :name => "id", :unique => true
  add_index "names", ["name_lcale", "name_section", "name_key"], :name => "idx_names_1", :unique => true

  create_table "other_applications", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "user_id",             :limit => 8
    t.integer  "base_application_id", :limit => 8
    t.string   "working_option_type", :limit => 40
    t.date     "application_date"
    t.date     "target_date"
    t.integer  "start_time",          :limit => 8
    t.integer  "end_time",            :limit => 8
    t.integer  "hour_total",          :limit => 8,  :default => 0
    t.string   "reason"
    t.string   "content"
    t.integer  "taxi_flg",                          :default => 0
    t.integer  "active_flg",                        :default => 0
    t.integer  "delayed_cancel_flg",                :default => 0
    t.text     "memo"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "lock_version",        :limit => 8,  :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                           :default => 0
  end

  add_index "other_applications", ["id"], :name => "id", :unique => true

  create_table "owners", :force => true do |t|
    t.integer  "union_user_id",        :limit => 8,                 :null => false
    t.string   "union_user_login",     :limit => 80,                :null => false
    t.string   "union_email",          :limit => 60,                :null => false
    t.string   "init_password",        :limit => 40,                :null => false
    t.string   "init_password_salt",   :limit => 40,                :null => false
    t.string   "owner_fullname",       :limit => 80,                :null => false
    t.string   "owner_shortname",      :limit => 80
    t.integer  "user_max_count",                     :default => 0
    t.integer  "available_user_count",               :default => 0
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.integer  "lock_version",         :limit => 8,  :default => 0
    t.string   "created_user",         :limit => 80
    t.string   "updated_user",         :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                            :default => 0
  end

  add_index "owners", ["id"], :name => "id", :unique => true

  create_table "payment_per_cases", :force => true do |t|
    t.integer  "owner_id",              :limit => 8
    t.integer  "user_id",               :limit => 8
    t.integer  "base_application_id",   :limit => 8
    t.integer  "payment_per_month_id",  :limit => 8
    t.date     "expense_paid_date"
    t.string   "cutoff_status_type",    :limit => 40,                                               :null => false
    t.decimal  "total_amount",                        :precision => 12, :scale => 2
    t.integer  "temporary_scrip_flg",                                                :default => 0
    t.integer  "temporary_payment_flg",                                              :default => 0
    t.date     "payment_date"
    t.text     "memo"
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "lock_version",          :limit => 8,                                 :default => 0
    t.string   "created_user",          :limit => 80
    t.string   "updated_user",          :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                            :default => 0
  end

  add_index "payment_per_cases", ["id"], :name => "id", :unique => true

  create_table "payment_per_months", :force => true do |t|
    t.integer  "owner_id",               :limit => 8
    t.integer  "user_id",                :limit => 8
    t.integer  "base_application_id",    :limit => 8
    t.integer  "base_month_id",          :limit => 8
    t.integer  "cutoff_period",          :limit => 8
    t.date     "cutoff_start_date"
    t.date     "cutoff_end_date"
    t.date     "expense_paid_date"
    t.string   "cutoff_status_type",     :limit => 40,                                               :null => false
    t.decimal  "temporary_amount_total",               :precision => 12, :scale => 2
    t.decimal  "total_amount",                         :precision => 12, :scale => 2
    t.integer  "temporary_scrip_flg",                                                 :default => 0
    t.integer  "temporary_payment_flg",                                               :default => 0
    t.text     "memo"
    t.datetime "created_at",                                                                         :null => false
    t.datetime "updated_at",                                                                         :null => false
    t.integer  "lock_version",           :limit => 8,                                 :default => 0
    t.string   "created_user",           :limit => 80
    t.string   "updated_user",           :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                             :default => 0
  end

  add_index "payment_per_months", ["id"], :name => "id", :unique => true

  create_table "personal_sales", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "user_id",             :limit => 8,                                                  :null => false
    t.integer  "project_id",          :limit => 8,                                                  :null => false
    t.integer  "base_month_id",       :limit => 8,                                                  :null => false
    t.decimal  "planed_sales_amount",               :precision => 12, :scale => 2, :default => 0.0
    t.decimal  "sales_amount",                      :precision => 12, :scale => 2, :default => 0.0
    t.text     "memo"
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "lock_version",        :limit => 8,                                 :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                          :default => 0
  end

  add_index "personal_sales", ["id"], :name => "id", :unique => true

  create_table "project_members", :force => true do |t|
    t.integer  "owner_id",     :limit => 8
    t.integer  "user_id",      :limit => 8,                 :null => false
    t.integer  "project_id",   :limit => 8,                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "lock_version", :limit => 8,  :default => 0
    t.string   "created_user", :limit => 80
    t.string   "updated_user", :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                    :default => 0
  end

  add_index "project_members", ["id"], :name => "id", :unique => true

  create_table "projects", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "business_partner_id", :limit => 8,                                                  :null => false
    t.string   "project_name",                                                                      :null => false
    t.string   "project_short_name",                                                                :null => false
    t.string   "project_name_kana",                                                                 :null => false
    t.string   "project_code_name",                                                                 :null => false
    t.integer  "pic_id",              :limit => 8
    t.date     "project_start_date",                                                                :null => false
    t.date     "project_end_date",                                                                  :null => false
    t.decimal  "order_amount",                      :precision => 12, :scale => 2, :default => 0.0
    t.decimal  "subcontract_cost",                  :precision => 12, :scale => 2, :default => 0.0
    t.string   "project_type",        :limit => 40,                                                 :null => false
    t.string   "project_status_type", :limit => 40,                                                 :null => false
    t.text     "memo"
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.integer  "lock_version",        :limit => 8,                                 :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                          :default => 0
  end

  add_index "projects", ["id"], :name => "id", :unique => true

  create_table "remarks", :force => true do |t|
    t.integer  "owner_id",         :limit => 8
    t.string   "remark_key",                                    :null => false
    t.integer  "remark_target_id", :limit => 8,                 :null => false
    t.text     "remark_content",                                :null => false
    t.integer  "rating",                         :default => 0
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "lock_version",     :limit => 8,  :default => 0
    t.string   "created_user",     :limit => 80
    t.string   "updated_user",     :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                        :default => 0
  end

  add_index "remarks", ["id"], :name => "id", :unique => true

  create_table "route_expense_details", :force => true do |t|
    t.integer  "owner_id",          :limit => 8
    t.integer  "route_expense_id",  :limit => 8
    t.string   "organization_name", :limit => 100,                                               :null => false
    t.string   "station_from",      :limit => 100,                                               :null => false
    t.string   "station_to",        :limit => 100,                                               :null => false
    t.decimal  "monthly_amount",                   :precision => 12, :scale => 2,                :null => false
    t.text     "memo"
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
    t.integer  "lock_version",      :limit => 8,                                  :default => 0
    t.string   "created_user",      :limit => 80
    t.string   "updated_user",      :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                         :default => 0
  end

  add_index "route_expense_details", ["id"], :name => "id", :unique => true

  create_table "route_expenses", :force => true do |t|
    t.integer  "owner_id",     :limit => 8
    t.integer  "user_id",      :limit => 8
    t.decimal  "total_amount",               :precision => 12, :scale => 2
    t.text     "memo"
    t.datetime "created_at",                                                               :null => false
    t.datetime "updated_at",                                                               :null => false
    t.integer  "lock_version", :limit => 8,                                 :default => 0
    t.string   "created_user", :limit => 80
    t.string   "updated_user", :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                                   :default => 0
  end

  add_index "route_expenses", ["id"], :name => "id", :unique => true

  create_table "schema_versions", :primary_key => "version", :force => true do |t|
  end

  create_table "sessions", :force => true do |t|
    t.integer  "owner_id",     :limit => 8
    t.string   "session_id",                                :null => false
    t.text     "data"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "created_user", :limit => 80
    t.string   "updated_user", :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                    :default => 0
  end

  add_index "sessions", ["id"], :name => "id", :unique => true

  create_table "sys_configs", :force => true do |t|
    t.integer  "owner_id",                :limit => 8
    t.string   "config_section",          :limit => 40,                :null => false
    t.string   "config_key",              :limit => 40,                :null => false
    t.string   "value1"
    t.string   "value2"
    t.string   "value3"
    t.text     "config_description_text"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "lock_version",            :limit => 8,  :default => 0
    t.string   "created_user",            :limit => 80
    t.string   "updated_user",            :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                               :default => 0
  end

  add_index "sys_configs", ["config_section", "config_key"], :name => "idx_sys_configs_3", :unique => true
  add_index "sys_configs", ["id"], :name => "id", :unique => true

  create_table "system_logs", :force => true do |t|
    t.integer  "owner_id",     :limit => 8
    t.string   "log_code",     :limit => 40
    t.string   "log_title"
    t.text     "log_contents", :limit => 2147483647
    t.string   "log_type",     :limit => 40
    t.string   "log_sub_type", :limit => 40
    t.string   "log_tag1"
    t.string   "log_tag2"
    t.string   "log_tag3"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.integer  "lock_version", :limit => 8,          :default => 0
    t.string   "created_user", :limit => 80
    t.string   "updated_user", :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                            :default => 0
  end

  add_index "system_logs", ["id"], :name => "id", :unique => true

  create_table "tag_details", :force => true do |t|
    t.integer  "owner_id",     :limit => 8
    t.integer  "tag_id",       :limit => 8,                 :null => false
    t.integer  "parent_id",    :limit => 8,                 :null => false
    t.string   "tag_key",                                    :null => false
    t.string   "tag_text",                                  :null => false
    t.integer  "opened",                     :default => 0
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "lock_version", :limit => 8,  :default => 0
    t.string   "created_user", :limit => 80
    t.string   "updated_user", :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                    :default => 0
  end

  add_index "tag_details", ["id"], :name => "id", :unique => true

  create_table "tag_journals", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "tag_id",              :limit => 8,                 :null => false
    t.integer  "adjust",              :limit => 8,  :default => 0
    t.integer  "opened",                            :default => 0
    t.string   "summary_status_type", :limit => 40,                :null => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "lock_version",        :limit => 8,  :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                           :default => 0
  end

  add_index "tag_journals", ["id"], :name => "id", :unique => true

  create_table "tags", :force => true do |t|
    t.integer  "owner_id",       :limit => 8
    t.string   "tag_key",                                     :null => false
    t.string   "tag_text",                                    :null => false
    t.integer  "tag_count",      :limit => 8,  :default => 0
    t.integer  "inc_count",      :limit => 8,  :default => 0
    t.integer  "tag_level",                    :default => 0
    t.integer  "display_order1", :limit => 8
    t.integer  "display_order2", :limit => 8
    t.integer  "display_order3", :limit => 8
    t.integer  "starred",                      :default => 0
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "lock_version",   :limit => 8,  :default => 0
    t.string   "created_user",   :limit => 80
    t.string   "updated_user",   :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                      :default => 0
  end

  add_index "tags", ["id"], :name => "id", :unique => true

  create_table "types", :force => true do |t|
    t.integer  "owner_id",              :limit => 8
    t.string   "type_section",          :limit => 40,                 :null => false
    t.string   "type_key",              :limit => 40,                 :null => false
    t.string   "long_name",             :limit => 100,                :null => false
    t.string   "short_name",            :limit => 100,                :null => false
    t.string   "other_name",            :limit => 100,                :null => false
    t.string   "type_description"
    t.text     "type_description_text"
    t.integer  "display_order1"
    t.integer  "display_order2"
    t.string   "logic_bind_type",       :limit => 40,                 :null => false
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.integer  "lock_version",          :limit => 8,   :default => 0
    t.string   "created_user",          :limit => 80
    t.string   "updated_user",          :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                              :default => 0
  end

  add_index "types", ["id"], :name => "id", :unique => true
  add_index "types", ["type_section", "type_key"], :name => "idx_types_2", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "owner_id",                 :limit => 8
    t.string   "login",                                                 :null => false
    t.string   "fullname"
    t.string   "shortname"
    t.string   "nickname"
    t.string   "access_level_type",        :limit => 40,                :null => false
    t.integer  "per_page",                               :default => 0
    t.string   "email",                                                 :null => false
    t.string   "encrypted_password",                                    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.text     "mail_signature"
    t.integer  "contact_mail_template_id", :limit => 8
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.integer  "lock_version",             :limit => 8,  :default => 0
    t.string   "created_user",             :limit => 80
    t.string   "updated_user",             :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                :default => 0
  end

  add_index "users", ["email"], :name => "idx_users_5"
  add_index "users", ["id"], :name => "id", :unique => true
  add_index "users", ["login"], :name => "idx_users_4", :unique => true

  create_table "vacations", :force => true do |t|
    t.integer  "owner_id",                       :limit => 8
    t.integer  "user_id",                        :limit => 8
    t.integer  "compensatory_hour_total",        :limit => 8,  :default => 0
    t.integer  "compensatory_used_total",        :limit => 8,  :default => 0
    t.integer  "cutoff_compensatory_hour_total", :limit => 8,  :default => 0
    t.integer  "summer_vacation_day_total",      :limit => 8,  :default => 0
    t.integer  "summer_vacation_used_total",     :limit => 8,  :default => 0
    t.integer  "day_total",                      :limit => 8,  :default => 0
    t.integer  "used_total",                     :limit => 8,  :default => 0
    t.integer  "cutoff_day_total",               :limit => 8,  :default => 0
    t.integer  "life_plan_day_total",            :limit => 8,  :default => 0
    t.integer  "life_plan_used_total",           :limit => 8,  :default => 0
    t.integer  "pre_comp_hour_total",            :limit => 8,  :default => 0
    t.integer  "pre_comp_used_total",            :limit => 8,  :default => 0
    t.integer  "pre_cutoff_comp_hour_total",     :limit => 8,  :default => 0
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.integer  "lock_version",                   :limit => 8,  :default => 0
    t.string   "created_user",                   :limit => 80
    t.string   "updated_user",                   :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                                      :default => 0
  end

  add_index "vacations", ["id"], :name => "id", :unique => true

  create_table "weekly_report_details", :force => true do |t|
    t.integer  "owner_id",         :limit => 8
    t.integer  "weekly_report_id", :limit => 8
    t.string   "title",            :limit => 100
    t.string   "content"
    t.string   "client"
    t.string   "relative_staff",   :limit => 100
    t.text     "memo"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "lock_version",     :limit => 8,   :default => 0
    t.string   "created_user",     :limit => 80
    t.string   "updated_user",     :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                         :default => 0
  end

  add_index "weekly_report_details", ["id"], :name => "id", :unique => true

  create_table "weekly_reports", :force => true do |t|
    t.integer  "owner_id",            :limit => 8
    t.integer  "user_id",             :limit => 8
    t.integer  "base_application_id", :limit => 8
    t.integer  "base_month_id",       :limit => 8
    t.date     "report_date"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "title"
    t.string   "content"
    t.string   "client"
    t.string   "relative_staff"
    t.integer  "last_flg",                          :default => 0
    t.text     "memo"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.integer  "lock_version",        :limit => 8,  :default => 0
    t.string   "created_user",        :limit => 80
    t.string   "updated_user",        :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                           :default => 0
  end

  add_index "weekly_reports", ["id"], :name => "id", :unique => true

  create_table "working_logs", :force => true do |t|
    t.integer  "owner_id",         :limit => 8
    t.integer  "daily_working_id", :limit => 8,                 :null => false
    t.integer  "user_id",          :limit => 8,                 :null => false
    t.integer  "project_id",       :limit => 8
    t.string   "working_kind",                                  :null => false
    t.integer  "working_time",     :limit => 8
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "lock_version",     :limit => 8,  :default => 0
    t.string   "created_user",     :limit => 80
    t.string   "updated_user",     :limit => 80
    t.datetime "deleted_at"
    t.integer  "deleted",                        :default => 0
  end

  add_index "working_logs", ["id"], :name => "id", :unique => true

end
