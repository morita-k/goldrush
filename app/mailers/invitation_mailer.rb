# -*- encoding: utf-8 -*-

class InvitationMailer < ActionMailer::Base
  default from: Devise.mailer_sender

  # mail配信メソッド
  def send_mail(mail_sender, destination, activation_code)
    @mail_sender = mail_sender
    @email = destination
    @activation_code = activation_code
    mail(to: destination, subject: "Invitation for #{SysConfig.get_application_name}").deliver
  end
end
