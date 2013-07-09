class MailTemplate < ActiveRecord::Base
  attr_accessible :content, :mail_bcc, :mail_cc, :mail_from, :mail_from_name, :mail_template_category, :mail_template_name, :subject, :lock_version, :created_user, :updated_user, :deleted_at, :deleted

  validates_presence_of     :content, :subject, :mail_template_category, :mail_template_name

end
