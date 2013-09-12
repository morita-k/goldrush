# -*- encoding: utf-8 -*-
class OutflowMail < ActiveRecord::Base

  def self.create_outflow_mails(import_mail)
    # nilチェックしたくない
    import_mail.mail_to ||= ""
    import_mail.mail_cc ||= ""

    OutflowMail.mail_address_parser(import_mail.mail_to + import_mail.mail_cc).each do |text, address|
      outflow_mail = OutflowMail.new

      outflow_mail.import_mail_id = import_mail.id
      outflow_mail.email          = address
      outflow_mail.email_text     = text
      # outflow_mail.url            = OutflowMail.inference_url(address)
      outflow_mail.url            = OutflowMail.search_active_url(address)
      # OutflowMail.search_active_url(address).each{|a| puts a}

      # 既存のアドレス -> "重複", WebスクレイピングしてHPが存在しない -> "不要"、その他 -> "未対応"
      # "重複"及び"不要"のメールは、会社チェック機能起動時に対象として含まない
      if BpPic.where(email2: address, deleted: 0).first
        outflow_mail.outflow_mail_status_type = "unwanted"
      elsif OutflowMail.search_active_url(address).blank?
        outflow_mail.outflow_mail_status_type = "bad"
      else
        outflow_mail.outflow_mail_status_type = "non_correspondence"
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

  def unnecessary_mail!
    self.outflow_mail_status_type = "bad"
    self.save!
  end

private #===============================================

  def self.create_unknown_address(id)
    "unknown+" + id.to_s + "@unknown.applicative.jp"
  end

  # 成功ならそのURL、失敗ならnilを返す
  # TODO: 適切なエラー処理諸々
  def self.check_active_url(url)
    require 'net/http'
    
    begin
      status = Net::HTTP.start(url, 80) {|http| http.head("/")}.code
      [status, url]
    rescue Exception
      []
    end
  end

  # アドレスから推測されるURLを叩いて、有効なURLを返す
  def self.search_active_url(email_address)
  	if email_address =~ /.*?@(.*)/
      url = OutflowMail.common_url_table($1).map{|url| OutflowMail.check_active_url(url)}.reject{|url| url.first != "200"}.first
    end
    url.nil? ? "" : url.second
  end

  # 名前とか色々くっついた、カンマ区切りのアドレス共をHashにする
  def self.mail_address_parser(email_str)
    address_hash = {}
    unless email_str.nil?
      email_str.split(",").map do |address|
        if address =~ /.*?<(.*)>/
          address_hash[address] = $1
        elsif address =~ /.*?@.*?/
          address_hash[address] = address.strip
        end
      end
    end
    address_hash
  end

  # 取引先担当者作るヘルパー
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

  def self.common_url_table(domain)
    [
      "#{domain}",
      "www.#{domain}",
      "#{domain}".gsub(".co", "")
    ]
  end

end

