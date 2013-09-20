# -*- encoding: utf-8 -*-
require 'auto_type_name'
require 'date_time_util'

class DeliveryMail < ActiveRecord::Base
  include AutoTypeName

  attr_accessor :planned_setting_at_hour, :planned_setting_at_minute, :planned_setting_at_date

  has_many :delivery_mail_targets, :conditions => "delivery_mail_targets.deleted = 0"
  has_many :delivery_errors, :conditions => "delivery_errors.deleted = 0"
  has_many :import_mails, :conditions => "import_mails.deleted = 0"
  belongs_to :bp_pic_group
  attr_accessible :bp_pic_group_id, :content, :id, :mail_bcc, :mail_cc, :mail_from, :mail_from_name, :mail_send_status_type, :mail_status_type, :owner_id, :planned_setting_at, :send_end_at, :subject, :lock_version, :planned_setting_at_hour, :planned_setting_at_minute, :planned_setting_at_date, :delivery_mail_type, :biz_offer_id, :bp_member_id

  validates_presence_of :subject, :content, :mail_from_name, :mail_from, :planned_setting_at

  after_initialize :default_values
  
  before_save :normalize_cc_bcc!

  def group?
    self.delivery_mail_type == "group"
  end

  def normalize_cc_bcc!
    self.mail_cc = mail_cc.to_s.split(/[ ,;]/).join(",")
    self.mail_bcc = mail_bcc.to_s.split(/[ ,;]/).join(",")
  end

  def formated_mail_from
    "#{mail_from_name} <#{mail_from}>"
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
    AttachmentFile.attachment_files("delivery_mails", id)
  end

  def DeliveryMail.send_test_mail(mail)
    opt = {:bp_pic_name => "ご担当者", :business_partner_name => "株式会社テストメール"}
    attachment_files = mail.attachment_files
    MyMailer.send_del_mail(
      mail.mail_from,
      nil,
      nil,
      "#{mail.mail_from_name} <#{mail.mail_from}>",
      DeliveryMail.tags_replacement(mail.subject, opt),
      DeliveryMail.tags_replacement(mail.content, opt),
      attachment_files
    ).deliver
  end

  def DeliveryMail.send_contact_mail(mail, bp_pic)
    opt = {:bp_pic_name => bp_pic.bp_pic_short_name, :business_partner_name => bp_pic.business_partner.business_partner_name}
    attachment_files = mail.attachment_files
    MyMailer.send_del_mail(
      bp_pic.email1,
      mail.mail_cc,
      mail.mail_bcc,
      "#{mail.mail_from_name} <#{mail.mail_from}>",
      DeliveryMail.tags_replacement(mail.subject, opt),
      DeliveryMail.tags_replacement(mail.content, opt),
      attachment_files
    ).deliver
  end
  
  def DeliveryMail.send_mail_to_each_targets(mail)
    mail.delivery_mail_targets.each do |target|
      begin
        next if target.bp_pic.nondelivery?
        
        opt = { :bp_pic_name => target.bp_pic.bp_pic_short_name,
                :business_partner_name => target.bp_pic.business_partner.business_partner_name }
        
        current_mail = MyMailer.send_del_mail(
          target.bp_pic.email1,
          mail.mail_cc,
          mail.mail_bcc,
          "#{mail.mail_from_name} <#{mail.mail_from}>",
          DeliveryMail.tags_replacement(mail.subject, opt),
          DeliveryMail.tags_replacement(mail.content, opt),
          mail.attachment_files
        )
        
        current_mail.deliver
        target.message_id = current_mail.header['Message-ID'].to_s
        target.save!
      rescue => e
        DeliveryError.send_error(mail.id, target.bp_pic, e).save!
        
        error_str = "Delivery Mail Send Error: " + e.message + "\n" + e.backtrace.join("\n")
        SystemLog.error('delivery mail', 'mail send error',  error_str, 'delivery mail')
      end
    end
  end
  
  # Broadcast Mails
  def DeliveryMail.send_mails
    fetch_key = Time.now.to_s + " " + rand().to_s
      
    DeliveryMail.
      where("mail_status_type=? and mail_send_status_type=? and planned_setting_at<=?",
             'unsend', 'ready', Time.now).
      update_all(:mail_send_status_type => 'running', :created_user => fetch_key)
    
    DeliveryMail.where(:created_user => fetch_key).each {|mail|
      self.send_mail_to_each_targets(mail)
    }
    
    DeliveryMail.
      where(:created_user => fetch_key).
      update_all(:mail_status_type => 'send',:mail_send_status_type => 'finished',:send_end_at => Time.now)
  end
  
  # === Private === 
  def DeliveryMail.tags_replacement(tag, option)
    option.inject(tag){|str, k| str.gsub("%%#{k[0].to_s}%%", k[1])}
  end

  # Private Mailer
  class MyMailer < ActionMailer::Base
    def send_del_mail(destination, cc, bcc, from, subject, body, attachment_files)      
      headers['Message-ID'] = "#{SecureRandom.uuid}@#{ActionMailer::Base.smtp_settings[:domain]}"
      
      attachment_files.each do |file|
        attachments[file.file_name] = file.read_file
      end
      
      mail( to: destination,
            cc: cc,
            bcc: bcc,
            from: from, 
            subject: subject,
            body: body )
      
      # Return-path の設定
      return_path = SysConfig.get_value(:delivery_mails, :return_path)
      if return_path
        headers[:return_path] = return_path
      else
        logger.warn '"Return-Path"が設定されていません。'
      end
    end
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
        p replace_words
        case replace_words[0]
          when 'biz_offers'
            if biz_offer
              if replace_words[1].end_with?("_type")
                replace_word_list.store(replace_word, biz_offer[replace_words[1]].nil? ? "" : biz_offer.type_name(replace_words[1]))
              else
                replace_word_list.store(replace_word, biz_offer[replace_words[1]].nil? ? "" : biz_offer[replace_words[1]])
              end
            else
              replace_word_list.store(replace_word, "")
            end
          when 'businesses'
            if biz_offer
              if replace_words[1].end_with?("_type")
                replace_word_list.store(replace_word, biz_offer.business[replace_words[1]].nil? ? "" : biz_offer.business.type_name(replace_words[1]))
              else
                replace_word_list.store(replace_word, biz_offer.business[replace_words[1]].nil? ? "" : biz_offer.business[replace_words[1]])
              end
            else
              replace_word_list.store(replace_word, "")
            end
          when 'bp_members'
            if bp_member
              if replace_words[1].end_with?("_type")
                replace_word_list.store(replace_word, bp_member[replace_words[1]].nil? ? "" : bp_member.type_name(replace_words[1]))
              else
                replace_word_list.store(replace_word, bp_member[replace_words[1]].nil? ? "" : bp_member[replace_words[1]])
              end
            else
              replace_word_list.store(replace_word, "")
            end
          when 'human_resources'
            if bp_member
              if replace_words[1].end_with?("_type")
                replace_word_list.store(replace_word, bp_member.human_resource[replace_words[1]].nil? ? "" : bp_member.human_resource.type_name(replace_words[1]))
              else
                replace_word_list.store(replace_word, bp_member.human_resource[replace_words[1]].nil? ? "" : bp_member.human_resource[replace_words[1]])
              end
            else
              replace_word_list.store(replace_word, "")
            end
          else
        end
      end
    end

    replace_word_list.inject(target_content){|str, k| str.gsub(k[0].to_s, k[1].to_s)}
  end
end
