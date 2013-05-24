# -*- encoding: utf-8 -*-
require 'test_helper'

class BusinessPartnerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  import_data = "Name,Given Name,Additional Name,Family Name,Yomi Name,Given Name Yomi,Additional Name Yomi,Family Name Yomi,Name Prefix,Name Suffix,Initials,Nickname,Short Name,Maiden Name,Birthday,Gender,Location,Billing Information,Directory Server,Mileage,Occupation,Hobby,Sensitivity,Priority,Subject,Notes,Group Membership,E-mail 1 - Type,E-mail 1 - Value,E-mail 2 - Type,E-mail 2 - Value,Phone 1 - Type,Phone 1 - Value,Phone 2 - Type,Phone 2 - Value,Phone 3 - Type,Phone 3 - Value,Address 1 - Type,Address 1 - Formatted,Address 1 - Street,Address 1 - City,Address 1 - PO Box,Address 1 - Region,Address 1 - Postal Code,Address 1 - Country,Address 1 - Extended Address,Organization 1 - Type,Organization 1 - Name,Organization 1 - Yomi Name,Organization 1 - Title,Organization 1 - Department,Organization 1 - Symbol,Organization 1 - Location,Organization 1 - Job Description,Website 1 - Type,Website 1 - Value\n佐藤 一郎,一郎,,佐藤,,,,,,,,,,,,,,,,,,,,,,,* My Contacts ::: SES ::: 大林,* Work,first_john_doe@tttest.co.jp,,,Work,12345678901,Work Fax,98765432101,,,Work,111-4561東京都そのへん123 東ビル11F,そのへん123 東ビル11F,,,東京都,111-4561,,,,株式会社ヒガシシステム,,営業部,,,,,,http://test1.com\n加藤 次郎,次郎,,加藤,,,,,,,,,,,,,,,,,,,,,,,* My Contacts ::: SES,* Work,second_john_doe@tttest.co.jp,,,Work,12345678902,Work Fax,98765432102,,,Work,222-4562 神奈川県どこか456 神ビル22F,どこか456 神ビル22F,,,神奈川県,222-4562,,,,株式会社カナガワデザイン,,広報部,,,,,,http://test2.com\n伊藤 三郎,三郎,,伊藤,,,,,,,,,,,,,,,,,,,,,,,* My Contacts ::: 中林,* Work,third_john_doe@tttest.co.jp,,,Work,12345678903,Work Fax,98765432103,,,Work,333-4563 埼玉県しゅうへん789 山ビル33F,しゅうへん789 山ビル33F,,,埼玉県,333-4563,,,,株式会社ボールコミュニケーションズ,,管理部,,,,,,http://test3.com\n後藤 四郎,四郎,,後藤,,,,,,,,,,,,,,,,,,,,,,,* My Contacts,* Work,fourth_john_doe@tttest.co.jp,,,Work,12345678904,Work Fax,98765432104,,,Work,444-4564 群馬県おくふかく012 森ビル44F,おくふかく012 森ビル44F,,,群馬県,444-4564,,,,株式会社フォレストパートナー,,開発部,,,,,,http://test4.com"
  
  test "import_csv" do
    # インポート前の確認
    assert_equal(1, BpPic.find(1).business_partner_id, "BpPicの事前データがおかしい")
    assert_equal(1, Project.find(1).business_partner_id, "Projectの事前データがおかしい")
    assert_equal(1, AnalysisTemplate.find(1).business_partner_id, "AnalysisTemplateの事前データがおかしい")
    assert_equal(1, BizOffer.find(1).business_partner_id, "BizOfferの事前データがおかしい")
    assert_equal(1, BpMember.find(1).business_partner_id, "BpMemberの事前データがおかしい")
    assert_equal(1, ImportMail.find(1).business_partner_id, "ImportMailの事前データがおかしい")
    assert_equal(1, Business.find(1).eubp_id, "Businessの事前データがおかしい")
    # assert_equal(1, ContactHistory.find(1).business_partner_id, "ContactHistoryの事前データがおかしい")
    # assert_equal(1, Interview.find(1).interview_bp_id, "Interviewの事前データがおかしい")
    # assert_equal(1, DeliveryError.find(1).business_partner_id, "ImportMailの事前データがおかしい")
   
    BusinessPartnerGoogleImporter.import_google_csv_data(import_data, "testuser", true)

    # 名寄せが発生
    assert_equal(2, BpPic.find(1).business_partner_id, "BpPicが名寄せ出来ていない")
    assert_equal(2, Project.find(1).business_partner_id, "Projectが名寄せ出来ていない")
    assert_equal(2, AnalysisTemplate.find(1).business_partner_id, "AnalysisTemplateが名寄せ出来ていない")
    assert_equal(2, BizOffer.find(1).business_partner_id, "BizOfferが名寄せ出来ていない")
    assert_equal(2, BpMember.find(1).business_partner_id, "BpMemberが名寄せ出来ていない")
    assert_equal(2, ImportMail.find(1).business_partner_id, "ImportMailが名寄せ出来ていない")
    assert_equal(2, Business.find(1).eubp_id, "Businessが名寄せ出来ていない") 
    # assert_equal(2, ContactHistory.find(1).business_partner_id, "ContactHistoryが名寄せ出来ていない")
    # assert_equal(2, Interview.find(1).interview_bp_id, "Interviewが名寄せ出来ていない")
    # assert_equal(2, DeliveryError.find(1).business_partner_id, "DeliveryErrorが名寄せ出来ていない")
    
    # 名寄せが発生しない場合
    bp = BusinessPartner.where(:business_partner_name => "株式会社カナガワデザイン", :deleted => 0).first
    assert_equal("株式会社カナガワデザイン", bp.business_partner_short_name, "short_name")
    assert_equal("株式会社カナガワデザイン", bp.business_partner_name_kana, "name_kana")
    assert_equal("http://test2.com", bp.url, "url")
    assert_equal("222-4562", bp.zip, "zip")
    assert_equal("神奈川県", bp.address1, "address1")
    assert_equal("どこか456 神ビル22F", bp.address2, "address2")
    assert_equal("12345678902", bp.tel, "tel")
    assert_equal("98765432102", bp.fax, "fax")
    
    # BusinessPartnerを更新、BpPicを新規作成
    bp = BusinessPartner.where(:business_partner_name => "株式会社ボールコミュニケーションズ", :deleted => 0).first
    assert_equal("株式会社ボールコミュニケーションズ", bp.business_partner_short_name, "short_name")
    assert_equal("株式会社ボールコミュニケーションズ", bp.business_partner_name_kana, "name_kana")
    assert_equal("http://test3.com", bp.url, "")
    assert_equal("333-4563", bp.zip, "")
    assert_equal("埼玉県", bp.address1, "")
    assert_equal("しゅうへん789 山ビル33F", bp.address2, "")
    assert_equal("12345678903", bp.tel, "")
    assert_equal("98765432103", bp.fax, "")
    assert_not_nil(BpPic.where(:email1 => "third_john_doe@tttest.co.jp".first, :deleted => 0), "BpPicの新規作成が出来ていない")
    
    # BusinessPartnerとBpPicを新規作成
    assert_not_nil(BusinessPartner.where(:business_partner_name => "株式会社フォレストパートナー", :deleted => 0).first, 
      "BusinessPartnerの新規作成が出来ていない")
    assert_not_nil(BpPic.where(:email1 => "fourth_john_doe@tttest.co.jp", :deleted => 0).first, "BpPicの新規作成が出来ていない")
  end
  
  # 営業担当の変更
  test "sales_pic" do
    BusinessPartnerGoogleImporter.import_google_csv_data(import_data, "testuser", true)
    pic_satou = BpPic.where(:email1 => "first_john_doe@tttest.co.jp", :deleted => 0).first
    pic_katou = BpPic.where(:email1 => "second_john_doe@tttest.co.jp", :deleted => 0).first
    pic_itou = BpPic.where(:email1 => "third_john_doe@tttest.co.jp", :deleted => 0).first
    pic_gotou = BpPic.where(:email1 => "fourth_john_doe@tttest.co.jp", :deleted => 0).first
    assert_equal(12, pic_satou.sales_pic_id, "「小林」から「大林」に変更されていない") 
    assert_equal(15, pic_katou.sales_pic_id, "「林」が変更されている") 
    assert_equal(13, pic_itou.sales_pic_id, "「中林」が追加されていない") 
    assert_nil(pic_gotou.sales_pic_id, "何かしらの不具合")
  end
  
  # 上流・下流フラグ管理
  test "SES_flag" do
    BusinessPartnerGoogleImporter.import_google_csv_data(import_data, "testuser", true)
    
    bp = BusinessPartner.where(:business_partner_name => "株式会社ヒガシシステム", :deleted => 0).first
    assert_equal(1, bp.upper_flg, "上流フラグが立っていない")
    assert_equal(1, bp.down_flg, "下流フラグが立っていない")
    
    bp = BusinessPartner.where(:business_partner_name => "株式会社カナガワデザイン", :deleted => 0).first
    assert_equal(1, bp.upper_flg, "上流フラグが上書きされていない")
    assert_equal(1, bp.down_flg, "下流フラグが上書きされていない")
    
    bp = BusinessPartner.where(:business_partner_name => "株式会社ボールコミュニケーションズ", :deleted => 0).first
    assert_equal(1, bp.upper_flg, "上流フラグが上書きされている")
    assert_equal(1, bp.down_flg, "下流フラグが上書きされている")
    
    bp = BusinessPartner.where(:business_partner_name => "株式会社フォレストパートナー", :deleted => 0).first
    assert_equal(0, bp.upper_flg, "上流フラグが上書きされている")
    assert_equal(0, bp.down_flg, "下流フラグが上書きされている")
  end
  
  # メールアドレスがエスケープ出来ているか
  test "prodmode_on" do
    BusinessPartnerGoogleImporter.import_google_csv_data(import_data, "testuser")
    assert(BpPic.where(:email1 => "test+fourth_john_doe_tttest.co.jp@i.applicative.jp", :deleted => 0), 
      "エスケープされていない")
  end
  
  # メールアドレスがエスケープされていないか
  test "prodmode_off" do
     BusinessPartnerGoogleImporter.import_google_csv_data(import_data, "testuser", true)
     assert(BpPic.where(:email1 => "fourth_john_doe@tttest.co.jp", :deleted => 0), "エスケープされていない")
  end
  
  # test "unsaported_format_data" do
  # end
  
end
