# -*- encoding: utf-8 -*-
class OutflowMail < ActiveRecord::Base
  include AutoTypeName

  validates_presence_of :import_mail_id, :email, :outflow_mail_status_type

  belongs_to :business_partner
  belongs_to :bp_pic
  belongs_to :import_mail

  accepts_nested_attributes_for :business_partner, :bp_pic

  def self.create_outflow_mails(import_mail)
    import_mail.mail_to ||= ""
    import_mail.mail_cc ||= ""

    OutflowMail.mail_address_parser(import_mail.mail_to + import_mail.mail_cc).each do |text, address|
      outflow_mail = OutflowMail.new

      outflow_mail.import_mail_id = import_mail.id
      outflow_mail.email          = address
      outflow_mail.email_text     = text

      if OutflowMail.check_duplication_domain(address)
        outflow_mail.outflow_mail_status_type = "unwanted"
      elsif active_url = OutflowMail.search_active_url(address)
        outflow_mail.outflow_mail_status_type = "non_correspondence"
        outflow_mail.url                      = active_url
      else
        outflow_mail.outflow_mail_status_type = "bad"
      end

      outflow_mail.save!
    end
  end

  def create_bp_and_pic(outflow_mail_form)
    form_bp = outflow_mail_form[:business_partner_attributes]
    bp = BusinessPartner.new(form_bp)
    bp.business_partner_short_name = form_bp[:business_partner_name]
    bp.business_partner_name_kana  = form_bp[:business_partner_name]
    bp.sales_status_type           = "prospect"
    bp.basic_contract_first_party_status_type  = "non_correspondence"
    bp.basic_contract_second_party_status_type = "non_correspondence"
    bp.url                         = self.url
    bp.save!

    form_pic = outflow_mail_form[:bp_pic_attributes]
    pic = BpPic.new(form_pic)
    pic.business_partner_id = bp.id
    pic.bp_pic_name         = "ご担当者"
    pic.bp_pic_short_name   = "ご担当者"
    pic.bp_pic_name_kana    = "ご担当者"
    pic.email1              = form_pic[:email1].blank? ? create_unknown_address(bp.id) : form_pic[:email1]
    pic.email2              = self.email
    pic.working_status_type = "working"
    pic.save!

    self.outflow_mail_status_type = "good"
    self.business_partner_id      = bp.id
    self.bp_pic_id                = pic.id
    self.save!
  end

  # 不要ボタン用ステータス変更メソッド
  def unnecessary_mail!
    self.outflow_mail_status_type = "bad"
    self.save!
  end

#private #===============================================

  def create_unknown_address(id)
    "unknown+" + id.to_s + "@unknown.applicative.jp"
  end

  def self.check_active_url(url)
    require 'net/http'
    
    begin
      status = Net::HTTP.start(url, 80) {|http| http.head("/")}.code
      [status, url]
    rescue Exception
      []
    end
  end

  # メールのドメインから予想されるURLのパターン
  # 増やすとヒット率は上がるけど、流出メール発生時の処理が重くなる
  def self.common_url_table(domain)
    [
      "#{domain}",
      "www.#{domain}",
      "#{domain}".gsub(".co", "")
    ]
  end

  # アドレスから推測されるURLを叩いて、有効なURLを返す
  def self.search_active_url(email_address)
  	if email_address =~ /.*?@(.*)/
      url = OutflowMail.common_url_table($1).map{|url|
        OutflowMail.check_active_url(url)}.select{|url|
          (url.first == "200") || (url.first == "301")}.first
    end
    url.nil? ? nil : "http://" + url.second # trueの時、本当は[]を返したい...
  end

  def self.mail_address_parser(email_str)
    address_hash = {}
    unless email_str.nil?
      email_str.split(",").map do |address|
        if address =~ /.*<(.*?)>.*?/
          address_hash[address] = $1
        elsif address =~ /.*?@.*?/
          address_hash[address] = address.strip
        end
      end
    end
    address_hash
  end

  def self.check_duplication_domain(mail_address)
    new_domain = mail_address.split("@").second
    exist_pic_mail_domain = BpPic.where(deleted: 0).map{|pic| pic.email1.split("@").second}.select{|dom| dom == new_domain}.first
    exist_outflow_mail_domain = OutflowMail.where(deleted: 0).map{|outflow| outflow.email.split("@").second}.select{|dom| dom == new_domain}.first
    
    exist_pic_mail_domain || exist_outflow_mail_domain
  end

  def update_bp_pic_from_outflow(email)
    pic = self.bp_pic
    pic.email1 = email
    pic.save!
  end

end
