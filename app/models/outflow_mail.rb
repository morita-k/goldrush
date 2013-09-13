# -*- encoding: utf-8 -*-
class OutflowMail < ActiveRecord::Base
  include AutoTypeName

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

  def create_bp_and_pic(bp_name, info_email, establishment_year, employee_number, share_capital)
    unless bp = BusinessPartner.where(business_partner_name: bp_name, deleted: 0).first
      bp = BusinessPartner.new

      bp.business_partner_name       = bp_name
      bp.business_partner_short_name = bp_name
      bp.business_partner_name_kana  = bp_name
      bp.sales_status_type           = "prospect"
      bp.basic_contract_status_type  = "non_correspondence"
      bp.nda_status_type             = "non_correspondence"
      bp.url                         = self.url
      bp.establishment_year          = establishment_year
      bp.employee_number             = employee_number
      bp.share_capital               = share_capital

      bp.save!
    end

    self.outflow_mail_status_type = "good"
    self.business_partner_id      = bp.id
    self.bp_pic_id                = self.create_bp_pic_from_outflow(bp.id, info_email).id

    self.save!
  end

  # 不要ボタン用ステータス変更メソッド
  def unnecessary_mail!
    self.outflow_mail_status_type = "bad"
    self.save!
  end

private #===============================================

  def self.create_unknown_address(id)
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
    url.nil? ? nil : "http://" + url.second　# trueの時、本当は[]を返したい.......
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
    exist_pic_domain = BpPic.where(deleted: 0).map{|pic| pic.email1.split("@").second}.select{|dom| dom == new_domain}.first
    exist_outflow_domain = OutflowMail.where(deleted: 0).map{|outflow| outflow.email.split("@").second}.select{|dom| dom == new_domain}.first
    
    exist_pic_domain || exist_outflow_domain
  end

  def create_bp_pic_from_outflow(bp_id, email)
    pic = BpPic.new

    pic.business_partner_id = bp_id
    pic.bp_pic_name         = "ご担当者"
    pic.bp_pic_short_name   = "ご担当者"
    pic.bp_pic_kana         = "ご担当者"
    pic.email1              = email.blank? ? create_unknown_address(bp_id) : email
    pic.email2              = self.email
    pic.workign_status      = "working"

    pic.save!
    pic
  end

end
