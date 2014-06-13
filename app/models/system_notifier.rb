# -*- encoding: utf-8 -*-

class SystemNotifier < ActionMailer::Base
  def send_info_mail(subject, body)
    raise "system notifier destination is not found" unless destination = SysConfig.get_system_notifier_destination
    raise "system notifier from is not found" unless from = SysConfig.get_system_notifier_from
    mail( to: destination,
          from: from, 
          subject: subject,
          body: body )
  end
end
