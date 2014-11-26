# -*- encoding: utf-8 -*-
require 'smtp_password_encryptor'

module Auth::RegistrationsHelper
  def available_import_mail_forwarding_address
    "import_mail#{current_user.owner.owner_key}@applicative.co.jp"
  end

  def available_port_list
    [25, 465, 587]
  end

  def decrypt_smtp_password(encrypted_password)
    SmtpPasswordEncryptor.decrypt(encrypted_password)
  end

  def available_contact_mail_template_list
    MailTemplate
        .where(:owner_id => current_user.owner_id, :deleted => 0)
        .collect {|x| [ x.mail_template_name, x.id ] }
  end
end
