# -*- encoding: utf-8 -*-
require 'string_util'

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

      outflow_mail.owner_id       = import_mail.owner_id
      outflow_mail.import_mail_id = import_mail.id
      outflow_mail.email          = address
      outflow_mail.email_text     = text

      outflow_mail.check_status

      outflow_mail.save!
    end

    import_mail.outflow_mail_flg = 1
    import_mail.save!
  end

  def self.update_outflow_mails(import_mail)
    import_mail.outflow_mails.each do |outflow_mail|
      if outflow_mail.check_duplication_domain
        outflow_mail.outflow_mail_status_type = "unwanted"
      end
      outflow_mail.save!
    end
  end

  def check_status
    if check_duplication_domain
      self.outflow_mail_status_type = "unwanted"
    elsif active_url = OutflowMail.search_active_url(self.email)
      self.outflow_mail_status_type = "non_correspondence"
      self.url = active_url
    else
      self.outflow_mail_status_type = "bad"
    end
  end

  def create_bp_and_pic(outflow_mail_form)
    form_bp = outflow_mail_form[:business_partner_attributes]
    bp = BusinessPartner.new(form_bp)
    bp.owner_id = self.owner_id
    bp.business_partner_short_name = form_bp[:business_partner_name]
    bp.business_partner_name_kana  = form_bp[:business_partner_name]
    bp.sales_status_type           = "prospect"
    bp.basic_contract_first_party_status_type  = "non_correspondence"
    bp.basic_contract_second_party_status_type = "non_correspondence"
    bp.url                         = self.url
    bp.save!

    form_pic = outflow_mail_form[:bp_pic_attributes]
    pic = BpPic.new(form_pic)
    pic.owner_id = self.owner_id
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
      OutflowMail.common_url_table($1).map{|domain| OutflowMail.check_active_url(domain)}.each do |result|
        if ["200","301"].include?(result.first)
          return "http://" + result.second
        end
      end
    end
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

  def check_duplication_domain
    unless SysConfig.email_prodmode?
      mail_address = StringUtil.to_test_address(self.email)
      at = "_at_"
    else
      mail_address = self.email
      at = "@"
    end
    new_domain_like = "%" + at + mail_address.split(at).second
    exist_pic_mail_domain = BpPic.where("owner_id = ? and deleted = 0 and email1 like ?", self.owner_id, new_domain_like).first
    exist_outflow_mail_domain = OutflowMail.where("owner_id = ? and deleted = 0 and import_mail_id != ? and email like ? and outflow_mail_status_type != 'unwanted'", self.owner_id, self.import_mail_id, new_domain_like).first
    
    exist_pic_mail_domain || exist_outflow_mail_domain
  end

  def update_bp_pic_from_outflow(email)
    pic = self.bp_pic
    pic.email1 = email
    pic.save!
  end

end
