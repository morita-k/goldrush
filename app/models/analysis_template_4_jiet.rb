# -*- encoding: utf-8 -*-

class AnalysisTemplate4JIET < AnalysisTemplate
  
  def separate_jiet_mail_body(body)
      # todo: sysconfigから取得出来るようにする
      separator = /-----*/
      body.split(Regexp.new(separator))
  end
  
  # def self.jiet_mail_parser(body)
  def jiet_mail_parser(item)
    jiet_mail_item = {}
    
    item.split("\n").group_by_indent.reject{|s| s == ""}.flat_map{|s|
      s.scan(/(.*?)[\s　]*?：[\s　]*?(.*)/)
    }.each{|arr|
      jiet_mail_item[arr[0]] = arr[1]
    }
    
    jiet_mail_item
  end
  
  def AnalysisTemplate4JIET.create_business_and_biz_offer(mail, business_partner_id, bp_pic_id)
    business = Business.new
    business.attributes = {
      business_status_type: "offerd",
      issue_datetime: mail["received_time"],
      term_type: "unknown",
      business_title: mail["business_title"],
      business_point: mail["business_point"],
      place: mail["place"],
      period: mail["period"],
      skill_title: mail["skill_title"],
      skill_must: mail["skill_must"],
      career_years: mail["career_years"],
      agelimit: mail["agelimit"],
      nationality_limit: mail["nationality_limit"],
      link: mail["link"],
      memo: mail["memo"]
    }.reject!{|k, v| v.blank?}
    
    business.save!
    
    biz_offer = BizOffer.new
    biz_offer.attributes = {
      business_id: business.id,
      business_partner_id: business_partner_id,
      bp_pic_id: bp_pic_id,
      biz_offer_status_type: "open",
      biz_offered_at: mail["received_time"],
      payment_text: mail["payment_text"],
      sales_route_limit: mail["sales_route_limit"]
    }.reject!{|k, v| v.blank?}
    
    biz_offer.save!
    
  end
  
  def self.create_human_resource_and_bp_member(mail, business_partner_id, bp_pic_id)
    hr = HumanResource.new
    hr.attirbutes = {
      initial: "XX",
      age: mail["age"],
      sex_type: mails["sex_type"],
      nationality: mails["nationality"],
      near_station: mail["near_station"],
      experience: mail["experience"],
      skill_title: mail["skill_title"],
      skill: mail["skill"],
      communication_type: "unknown",
      human_resource_status_type: "sales"
      link: mail["link"],
      memo: mail["memo"]
    }.reject!{|k, v| v.blank?}
    
    hr.save!
    
    bp_member = BpMember.new
    bp_member.attributes = {
      human_resource_id: human_resource_id,
      business_partner_id: business_partner_id,
      bp_pic_id: bp_pic_id,
      employment_type: mail["employment_type"],
      can_start_date: mail["can_start_date"],
      payment_memo: mail["payment_memo"],
      moemo: mail["memo"]
    }
  end
  
  def self.create_bp_and_bp_pic(mail)
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
  
  def delimiter_with_comma(*str)
    str.reject{|s| s == ""}.join(", ")
  end
  
  def delimiter_with_new_line(*str)
    str.reject{|s| s == ""}.join("\n")
  end
  
  def group_by_indent(list)
  end
  
  private :domain_name, :delimiter_with_comma, :delimiter_with_new_line
  
end

=begin
BUSINESS_TAG = [
  "会社名",
  "URL",
  "案件概要",
  "作業形態",
  "作業地域",
  "作業場所",
  "ＯＳ",
  "ＤＢ",
  "言語",
  "ハードウェア",
  "ネットワーク",
  "ツール",
  "フレームワーク",
  "参入時期",
  "年齢範囲",
  "予算",
  "社員区分",
  "国籍",
  "業種",
  "職務",
  "経験年数",
  "コメント",
  "リンク"
]

HUMAN_TAG = [
  "会社名",
  "URL",
  "人財概要",
  "性別（年齢）",
  "社員区分",
  "作業希望形態",
  "希望作業場所",
  "ＯＳ",
  "ＤＢ",
  "言語",
  "ハードウェア",
  "ネットワーク",
  "ツール",
  "フレームワーク",
  "稼動可能日",
  "国籍",
  "単価",
  "業種",
  "職務",
  "経験年数",
  "最寄り駅",
  "コメント",
  "リンク"
]
=end