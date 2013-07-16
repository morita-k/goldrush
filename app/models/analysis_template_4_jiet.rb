# -*- encoding: utf-8 -*-

class AnalysisTemplate::AnalysisTemplate4JIET

  def self.jiet_mail_parser(body)
    jiet_mail = {}
    
    separate_jiet_mail_body(body).each {|item|
      item.split(/\n/).
    }
    
  end

  def self.update_business_partner()
  end

  def self.update_bp_pic()
  end
  
  def self.create_bp_and_bp_pic_4_jiet(mail)
    bp = BusinessPartner.new
    bp.attributes = {
      business_partner_name: mail["business_partner_name"],
      business_partner_short_name: mail["business_partner_name"],
      business_partner_name_kana: mail["business_partner_name"],
      sales_status_type: "見込み",
      basic_contract_status_type: "none",
      nda_status_type: "none",
      url: mail["url"],
      import_mail_id: mail["import_mail_id"]
    }.reject!{|k, v| v.blank?}
    bp.save!
    
    pic = BpPic.new
    pic.attributes = {
      business_partner_id: bp.id,
      bp_pic_name: "ご担当者",
      bp_pic_short_name: "ご担当者",
      bp_pic_name_kana: "ご担当者",
      email1: "unknown@#{domain_name(mail["url"])}"
    }.reject!{|k, v| v.blank?}
    pic.save!
    
  end
  
  #== private methods ==#
  def domain_name(url)
    d = url.gsub(/.*?:\/\//, "")
    d = "i.applicative.jp" if d.blank?
  end
  
  def separate_jiet_mail_body(body)
  	  # todo: sysconfigから取得出来るようにする
  	  separator = "-------------------------------------------------------------------------"
  	  body.split(Regexp.new(separator))
  end
  
  private :domain_name, :separate_jiet_mail_body
  
end
