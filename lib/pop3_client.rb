# -*- encoding: utf-8 -*-
require "net/pop"
require "mail"

class MainReplyError < StandardError
end

class Pop3Client

  class_attribute :settings

  # ---------------------------------------------------------------------------
  # メールをポップする処理
  # ---------------------------------------------------------------------------
  def Pop3Client.pop_mail(&block)
    Pop3Client.pop_mail_with_settings(Pop3Client.settings, &block)
  end
  
  def Pop3Client.pop_mail_with_settings(settings, &block)
    Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE) if settings[:enable_tls] == 1
    begin
      Net::POP3.start(settings[:pop_server],
                      settings[:pop_port],
                      settings[:user_name],
                      settings[:password]){|pop|
        pop.each_mail{ |mail|
          str = mail.pop
          block.call(Mail.new(str), str)
        }
      }
    rescue
      error_str = "Pop Error.. #{$!.inspect}\n\n#{$!.backtrace.join("\n")}"
#      error_str = "Pop Error.. #{$!.backtrace.join(\n)}"
      puts error_str
      SystemLog.error('pop_mail', 'Mail pop error', error_str, 'pop_mail')
    end
  end
  
end
