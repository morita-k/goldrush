# -*- encoding: utf-8 -*-
require 'auto_type_name'

class DeliveryMail < ActiveRecord::Base
  include AutoTypeName

  attr_accessor :planned_setting_at_time, :planned_setting_at_date

  has_many :delivery_mail_targets, :conditions => "delivery_mail_targets.deleted = 0"
  attr_accessible :bp_pic_group_id, :content, :id, :mail_bcc, :mail_cc, :mail_from, :mail_from_name, :mail_send_status_type, :mail_status_type, :owner_id, :planned_setting_at, :send_end_at, :subject, :lock_version, :planned_setting_at_time, :planned_setting_at_date

  after_initialize :default_values

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
  
  def perse_planned_setting_at(time_zone)
    unless planned_setting_at_time.blank? || planned_setting_at_date.blank?
      org = Time.zone
      Time.zone = time_zone
      self.planned_setting_at = Time.zone.parse(planned_setting_at_date.to_s + " " + planned_setting_at_time + ":00:00")
      Time.zone = org
    end
  end

  def setup_planned_setting_at(zone_now)
    self.planned_setting_at = zone_now
    self.planned_setting_at_date = planned_setting_at.in_time_zone(zone_now.time_zone).strftime("%Y/%m/%d")
    self.planned_setting_at_time = planned_setting_at.in_time_zone(zone_now.time_zone).hour
  end

  # Broadcast Mails
  def DeliveryMail.send_mails
    fetch_key = Time.now.to_s + " " + rand().to_s
      
    DeliveryMail.
      where("mail_status_type=? and mail_send_status_type=? and planned_setting_at<=?",
             'unsend', 'ready', Time.now).
      update_all(:mail_send_status_type => 'running', :created_user => fetch_key)
    
    begin
      DeliveryMail.where(:created_user => fetch_key).each {|mail|
        attachment_files = AttachmentFile.attachment_files("delivery_mails", mail.id)
        mail.delivery_mail_targets.each {|target|
          email = target.bp_pic.email1
          title = tags_replacemet(mail.subject)
          body = tags_replacement(mail.content)
          
          MyMailer.send_del_mail(
            email,
            mail.mail_cc,
            mail.mail_bcc,
            "#{mail.mail_from_name} <#{mail.mail_from}>",
            title,
            body,
            attachment_files
          ).deliver
        }
      }
    rescue => e
      error_str = "Delivery Mail Send Error: " + e.message + "\n" + e.backtrace.join("\n")
      SystemLog.error('delivery mail', 'mail send error',  error_str, 'delivery mail')
    end
    DeliveryMail.
      where(:created_user => fetch_key).
      update_all(:mail_status_type => 'send',:mail_send_status_type => 'finished',:send_end_at => Time.now)
      
  end
  
  # === Private === 
  def tags_replacement(tag)
    tag.
    gsub("%%bp_pic_name%%", target.bp_pic.bp_pic_short_name).
    gsub("%%business_partner_name%%", target.bp_pic.business_partner.business_partner_name)
  end
  private :tags_replacement

  # Private Mailer
  class MyMailer < ActionMailer::Base
    def send_del_mail(destination, cc, bcc, from, subject, body, attachment_files)
      attachment_files.each do |af|
        attachments[af.file_name] = af.read_file
      end
      mail(
        to: destination,
        cc: cc,
        bcc: bcc,
        from: from, 
        subject: subject,
        body: body
      )
    end
  end
end
