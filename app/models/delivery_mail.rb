# -*- encoding: utf-8 -*-
require 'auto_type_name'
require 'date_time_util'

class DeliveryMail < ActiveRecord::Base
  include AutoTypeName

  attr_accessor :planned_setting_at_hour, :planned_setting_at_minute, :planned_setting_at_date

  has_many :delivery_mail_targets, :conditions => "delivery_mail_targets.deleted = 0"
  has_many :delivery_errors, :conditions => "delivery_errors.deleted = 0"
  has_many :import_mails, :conditions => "import_mails.deleted = 0"
  has_many :delivery_mail_matches, :conditions => "delivery_mail_matches.deleted = 0"
  has_many :delivery_mail_targets, :conditions => "delivery_mail_targets.deleted = 0"

  belongs_to :bp_pic_group
  belongs_to :delivery_user, :class_name => "User", :foreign_key => :delivery_user_id, :conditions => "users.deleted = 0"
  attr_accessible :bp_pic_group_id, :content, :id, :mail_bcc, :mail_cc, :mail_from, :mail_from_name, :mail_send_status_type, :mail_status_type, :owner_id, :planned_setting_at, :send_end_at, :subject, :lock_version, :planned_setting_at_hour, :planned_setting_at_minute, :planned_setting_at_date, :delivery_mail_type, :biz_offer_id, :bp_member_id, :formated_mail_from, :age, :payment, :import_mail_match_id, :matching_way_type, :tag_text, :auto_matching_last_id, :delivery_user_id

  validates_presence_of :subject, :content, :mail_from_name, :mail_from, :planned_setting_at

  after_initialize :default_values

  before_save :normalize_cc_bcc!, :set_default!

  def get_delivery_mail_targets(limit=20)
    DeliveryMailTarget.joins("left outer join import_mails on import_mails.in_reply_to = delivery_mail_targets.message_id").where("delivery_mail_targets.delivery_mail_id = ? and delivery_mail_targets.deleted = 0", self.id).order("import_mails.in_reply_to desc, delivery_mail_targets.delivery_mail_id").limit(limit)
  end

  def instant?
    self.delivery_mail_type == "instant"
  end

  def group?
    self.delivery_mail_type == "group"
  end

  def filtered_matches_in
    [] if self.payment.blank? || self.age.blank?
    if self.biz_offer_mail?
      w = "delivery_mail_matches.owner_id = ? and delivery_mail_matches.delivery_mail_id = ? and delivery_mail_matches.deleted = 0 and payment <= ? and age <= ?"
    else
      w = "delivery_mail_matches.owner_id = ? and delivery_mail_matches.delivery_mail_id = ? and delivery_mail_matches.deleted = 0 and payment >= ? and age >= ?"
    end
    DeliveryMailMatch.joins(:import_mail).where(w, self.owner_id, self.id, self.payment, self.age)
  end

  def filtered_matches
    filtered_matches_in.order("received_at desc").limit(20).map{|x| x.import_mail}
  end

  def filtered_matches_count
    filtered_matches_in.count
  end

  def biz_offer_mail?
    self.bp_pic_group && self.bp_pic_group.matching_way_type == 'biz_offer'
  end

  def bp_member_mail?
    self.bp_pic_group && self.bp_pic_group.matching_way_type == 'bp_member'
  end

  def normalize_cc_bcc!
    self.mail_cc = mail_cc.to_s.split(/[ ,;]/).join(",")
    self.mail_bcc = mail_bcc.to_s.split(/[ ,;]/).join(",")
  end

  def set_default!
    self.matching_way_type ||= 'other'
  end

  def formated_mail_from
    "\"#{mail_from_name}\" <#{mail_from}>"
  end

  def formated_mail_from=(str)
    str =~ /\"(.*)\" <(.*)>/
    self.mail_from_name = $1
    self.mail_from = $2
  end

  def unsend?
    ['editing','unsend'].include?(mail_status_type)
  end

  def canceled?
    ['canceled'].include?(mail_status_type)
  end

  def default_values
    self.mail_status_type ||= 'editing'
    self.mail_send_status_type ||= 'ready'
  end

  def planned_setting_at_time
    if planned_setting_at_hour && planned_setting_at_minute
      if !planned_setting_at_hour.blank? && !planned_setting_at_minute.blank?
        return [planned_setting_at_hour, planned_setting_at_minute, "00"].join(":")
      end
    end
    return ""
  end

  def perse_planned_setting_at(user)
    unless planned_setting_at_time.blank? || planned_setting_at_date.blank?
      self.planned_setting_at = user.zone_parse(planned_setting_at_date.to_s + " " + planned_setting_at_time)
    end
  end

  def setup_planned_setting_at(zone_now)
    self.planned_setting_at = zone_now
    date, hour, minute = DateTimeUtil.split_date_hour_minute(zone_now)
    self.planned_setting_at_date = date
    self.planned_setting_at_hour = hour
    self.planned_setting_at_minute = minute
  end

  def attachment_files
    AttachmentFile.get_attachment_files("delivery_mails", id)
  end

  def DeliveryMail.send_test_mail(mail_sender, mail)
    opt = {:bp_pic_name => "ご担当者", :business_partner_name => "株式会社テストメール"}
    attachment_files = mail.attachment_files
    NoticeMailer.send_mail(
      mail_sender,
      mail.mail_from,
      nil,
      nil,
      "\"#{mail.mail_from_name}\" <#{mail.mail_from}>",
      DeliveryMail.tags_replacement(mail.subject, opt),
      DeliveryMail.tags_replacement(mail.content, opt),
      attachment_files
    )
  end

  def DeliveryMail.send_contact_mail(mail_sender, mail, bp_pic)
    opt = {:bp_pic_name => bp_pic.bp_pic_short_name, :business_partner_name => bp_pic.business_partner.business_partner_name}
    attachment_files = mail.attachment_files
    NoticeMailer.send_mail(
      mail_sender,
      bp_pic.email1,
      mail.mail_cc,
      mail.mail_bcc,
      "\"#{mail.mail_from_name}\" <#{mail.mail_from}>",
      DeliveryMail.tags_replacement(mail.subject, opt),
      DeliveryMail.tags_replacement(mail.content, opt),
      attachment_files
    )
  end

  def DeliveryMail.send_mail_to_each_targets(mail_sender, mail)
    mail.delivery_mail_targets.each do |target|
      begin
        next if target.bp_pic.nondelivery?

        opt = { :bp_pic_name => target.bp_pic.bp_pic_short_name,
                :business_partner_name => target.bp_pic.business_partner.business_partner_name }

        mail_content = mail.content + <<EOS


GR-BIZ-ID:#{mail.id ** 2}-#{target.id ** 2}
EOS

        NoticeMailer.send_mail(
          mail_sender,
          target.bp_pic.email1,
          mail.mail_cc,
          mail.mail_bcc,
          "\"#{mail.mail_from_name}\" <#{mail.mail_from}>",
          DeliveryMail.tags_replacement(mail.subject, opt),
          DeliveryMail.tags_replacement(mail_content, opt),
          mail.attachment_files,
          target.in_reply_to
        ) do |sending_mail|
          target.message_id = sending_mail.header['Message-ID'].to_s
          target.save!
        end
      rescue => e
        DeliveryError.send_error(mail.owner_id, mail.id, target.bp_pic, e).save!

        error_str = "Delivery Mail Send Error: " + e.message + "\n" + e.backtrace.join("\n")
        SystemLog.error('delivery mail', 'mail send error',  error_str, 'delivery mail')
      end
    end
  end

  # Broadcast Mails
  def DeliveryMail.send_mails
    now = Time.now
    fetch_key = now.to_s + " " + rand().to_s

    DeliveryMail
      .where("mail_status_type=? and mail_send_status_type=? and planned_setting_at<=?", 'unsend', 'ready', now)
      .update_all(["mail_send_status_type='running', created_user=?, lock_version=lock_version+1, updated_at=?", fetch_key, now])

    DeliveryMail.where(:created_user => fetch_key).each do |mail|
      self.send_mail_to_each_targets(mail.delivery_user, mail)
    end

    DeliveryMail
      .where(:created_user => fetch_key)
      .update_all(["mail_status_type='send', mail_send_status_type='finished', send_end_at=?, lock_version=lock_version+1, updated_at=?", now, now])
  end

  # === Private ===
  def DeliveryMail.tags_replacement(tag, option)
    option.inject(tag){|str, k| str.gsub("%%#{k[0].to_s}%%", k[1])}
  end

  def get_informations
    self.subject = get_information(self.subject)
    self.content = get_information(self.content)
    self
  end

  def get_information(target_content)
    biz_offer = BizOffer.find(self.biz_offer_id) if self.biz_offer_id
    bp_member = BpMember.find(self.bp_member_id) if self.bp_member_id

    replace_word_list = {}
    (target_content.scan(/%.*?%/) - ["%%"]).each do |replace_word|
      replace_words = replace_word.delete("%").split(".")

      unless replace_words.nil?
        target_word = ""
        case replace_words[0]
          when 'biz_offers'
            if biz_offer
              if replace_words[1].end_with?("_type")
                target_word = biz_offer[replace_words[1]].nil? ? "" : biz_offer.type_name(replace_words[1])
              elsif replace_words[1].end_with?("_flg")
                target_word = biz_offer[replace_words[1]].nil? ? "" : get_flg(biz_offer[replace_words[1]])
              elsif replace_words[1] == 'payment_max'
                target_word = biz_offer[replace_words[1]].nil? ? "" : biz_offer.payment_max_view
              else
                target_word = biz_offer[replace_words[1]].nil? ? "" : biz_offer[replace_words[1]]
              end
            end
          when 'businesses'
            if biz_offer
              if replace_words[1].end_with?("_type")
                target_word = biz_offer.business[replace_words[1]].nil? ? "" : biz_offer.business.type_name(replace_words[1])
              elsif replace_words[1].end_with?("_flg")
                target_word = biz_offer.business[replace_words[1]].nil? ? "" : get_flg(biz_offer.business[replace_words[1]])
              else
                target_word = biz_offer.business[replace_words[1]].nil? ? "" : biz_offer.business[replace_words[1]]
              end
            end
          when 'bp_members'
            if bp_member
              if replace_words[1] == 'payment_min'
                target_word = bp_member[replace_words[1]].nil? ? "" : bp_member.payment_min_view
              elsif replace_words[1] == 'employment_type'
              target_word = bp_member[replace_words[1]].nil? ? "" : get_employment_type(bp_member)
              elsif replace_words[1].end_with?("_type")
                target_word = bp_member[replace_words[1]].nil? ? "" : bp_member.type_name(replace_words[1])
              elsif replace_words[1].end_with?("_flg")
                target_word = bp_member[replace_words[1]].nil? ? "" : get_flg(bp_member[replace_words[1]])
              else
                target_word = bp_member[replace_words[1]].nil? ? "" : bp_member[replace_words[1]]
              end
            end
          when 'human_resources'
            if bp_member
              if replace_words[1].end_with?("_type")

                target_word = bp_member.human_resource[replace_words[1]].nil? ? "" : bp_member.human_resource.type_name(replace_words[1])
              elsif replace_words[1].end_with?("_flg")
                target_word = bp_member.human_resource[replace_words[1]].nil? ? "" : get_flg(bp_member.human_resource[replace_words[1]])
              else
                target_word = bp_member.human_resource[replace_words[1]].nil? ? "" : bp_member.human_resource[replace_words[1]]
              end
            end
          else
        end
        replace_word_list.store(replace_word, target_word)
      end
    end

    replace_word_list.inject(target_content){|str, k| str.gsub(k[0].to_s, k[1].to_s)}
  end

  def get_flg(target_flg)
    target_flg == 1 ? "有" : "無"
  end

  def get_employment_type(bp_member)
    if bp_member.business_partner.self_flg == 1
      "弊社所属 " + bp_member.employment_type_name
    elsif bp_member.employment_type_name == '正社員'
      "BP一社下 " + bp_member.employment_type_name
    else
      "弊社ビジネスパートナー " + bp_member.employment_type_name
    end
  end

  def pre_body
    subject + "\n" + content
  end

  def tag_analyze!(body = Tag.pre_proc_body(pre_body))
    analyzed_tag_text = Tag.analyze_skill_tags(owner_id, body)
    self.tag_text = analyzed_tag_text
    self.save!
    Tag.update_tags!(owner_id, "delivery_mails", id, analyzed_tag_text)
  end

  def add_signature(mail_sender)
    if signature = mail_sender.mail_signature.presence
      self.content += "\n\n#{signature}"
    end
  end
end
