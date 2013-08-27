#require 'tlsmail'
namespace :app do
  def logger
    Rails.logger
  end
  
  desc "Mail pop to files. if DEL=1 then remove server mail."
  task :dumpmails => :environment do
    settings = ActionMailer::Base.smtp_settings
    Net::POP3.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    Net::POP3.start(settings[:pop_server],
                    settings[:pop_port],
                    settings[:user_name],
                    settings[:password]){|pop|
      idx = 0
      pop.each_mail{ |mail|
        tm = TMail::Mail.parse mail.pop
        open("mail#{Time.now.strftime('%Y%m%d%H%M%S')}#{idx}.txt","w"){|file|
          file << tm
        }
        idx += 1
      }
      # GMAIL doesn't using reset command.
      pop.reset unless ENV['DEL'] == '1'
    }
  end

end
