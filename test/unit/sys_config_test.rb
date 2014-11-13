# -*- encoding:utf-8 -*-
require 'test_helper'

class SysConfigTest < ActiveSupport::TestCase
  fixtures :sys_configs

  setup do
    SysConfig.load_cache
  end

  test "キャッシュがクリアされていること" do
    assert_nil SysConfig.purge_cache
  end

  test "get_config(), get_value()はDBから直接取得していること" do
    SysConfig.purge_cache
    assert_not_nil SysConfig.get_config("seq", "sales_code", 1)
    assert_not_nil SysConfig.get_value("seq", "sales_code", 1)
  end

  test "get_configuration()はキャッシュから取得していること" do
    SysConfig.class_variable_get(:@@cache).reject!{|s| s.config_section == 'seq'}
    assert_nil SysConfig.get_configuration("seq", "sales_code", 1)
  end

  test "seq_sales_codeがowner毎に取得できていること" do
    assert_not_nil SysConfig.get_seq('sales_code', 1)
    assert_not_nil SysConfig.get_seq('sales_code', 2)
  end

  test "seq_sales_codeが存在しない場合、新規に作成できること" do
    assert_not_nil SysConfig.get_seq('sales_code', 3)
  end

  test "per_page_countが取得できていること" do
    assert_not_equal(SysConfig.get_per_page_count, 0)
  end

  test "email_prodmode?が取得できていること" do
    assert_not_nil SysConfig.email_prodmode?
  end

  test "indent_patternが取得できていること" do
    assert_not_empty SysConfig.get_indent_pattern
  end

  test "jiet_analysis_target_addressが取得できていること" do
    assert_not_empty SysConfig.get_jiet_analysis_target_address
  end

  test "delivery_mails_return_pathが取得できていること" do
    assert_not_empty SysConfig.get_delivery_mails_return_path
  end

  test "outflow_criterionが取得できていること" do
    assert_not_empty SysConfig.get_outflow_criterion
  end

  test "api_loginが取得できていること" do
    api_login = SysConfig.get_api_login
    assert_not_empty api_login.value1
    assert_not_empty api_login.value2
  end

  test "system_notifier_destinationが取得できていること" do
    assert_not_empty SysConfig.get_system_notifier_destination
  end

  test "system_notifier_fromが取得できていること" do
    assert_not_empty SysConfig.get_system_notifier_from
  end

  test "system_notifier_url_prefixが取得できていること" do
    assert_not_empty SysConfig.get_system_notifier_url_prefix
  end

  test "smtp_secret_keyが取得できていること" do
    assert_not_empty SysConfig.get_smtp_secret_key
  end

  test "application_nameが取得できていること" do
    assert_not_empty SysConfig.get_application_name
  end

  test "contact_addressが取得できていること" do
    assert_not_empty SysConfig.get_contact_address
  end
end
