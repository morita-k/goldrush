# -*- encoding: utf-8 -*-

module MailTemplatesHelper
  def with_signature(content)
    if current_user.mail_signature.blank?
      content
    else
      content + <<EOS

--
#{current_user.mail_signature}
EOS
    end
  end
end

