require 'test_helper'

class AttachmentFileTest < ActiveSupport::TestCase
   class Readable
     def read
       "aaaaaaaaaaaaaa"
     end
   end
   
   test "the truth" do
     im = ImportMail.new
     im.received_at = Time.now
     im.mail_subject = "aaa"
     im.mail_body = "aaa"
     im.mail_from = "aaa@aaa.jp"
     im.mail_sender_name = "aaaa"
     im.mail_to = "aaa@aaa.jp"
     #im.message_source = "aaa"
     im.save!
     upfile = ActionDispatch::Http::UploadedFile.new(:tempfile => Readable.new)
     a = AttachmentFile.new
     a.create_by_import(upfile, im.id, "aaaa.xls")
   end
end
