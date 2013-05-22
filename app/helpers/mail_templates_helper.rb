# -*- encoding: utf-8 -*-

module MailTemplatesHelper

  def with_signature(content)
    content + unless current_user.mail_signature.blank?
      <<EOS

--
#{current_user.mail_signature}
EOS
    end

  end

end

