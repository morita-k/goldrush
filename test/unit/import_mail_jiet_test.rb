# -*- encoding:utf-8 -*-
require 'test_helper'

class ImportMailJIETTest < ActiveSupport::TestCase
  
  setup do
    @file_name_offer = "test_jiet_offer.txt"
    @file_name_human = "test_jiet_human.txt"
  end
  
  test "import jiet-offer mail" do
    file = File.open(@file_name_offer){|f| f.read}
    # file = File.open("/home/Aoino/work/project/goldrush/test_jiet_offer.txt"){|f| f.read}
    
    assert_difference(["Business.count", "BizOffer.count"], 2) do
      ImportMail.import_mail(Mail.new(file), file.to_s)
    end
    
  end
  
  test "import jiet-human mail" do
    file = File.open(@file_name_human){|f| f.read}
    
    assert_difference(["HumanResource.count", "BpMember.count"], 2) do
      ImportMail.import_mail(Mail.new(file), file.to_s)
    end
  end
  
  test "business_patner and bp_pic count" do
    # メールの会社名に含まれる空白の削除が出来ているかの確認も兼ねてる
    
    file_offer = File.open(@file_name_offer){|f| f.read}
    file_human = File.open(@file_name_human){|f| f.read}
  
    assert_difference(["BusinessPartner.count", "BpPic.count"]) do
      ImportMail.import_mail(Mail.new(file_offer), file_offer.to_s)
    end
    
    assert_difference(["BusinessPartner.count", "BpPic.count"]) do
      ImportMail.import_mail(Mail.new(file_human), file_human.to_s)
    end
  end
  
  
  
end