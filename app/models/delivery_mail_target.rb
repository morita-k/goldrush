class DeliveryMailTarget < ActiveRecord::Base
  belongs_to :delivery_mail
  belongs_to :bp_pic
  
  attr_accessible :bp_pic_id, :delivery_mail_id, :id, :owner_id

  def get_reply_import_mail
    @import_mail = ImportMail.where(:in_reply_to => self.message_id).first if self.message_id
  end

  def get_import_mail_id
    @import_mail.nil? ? nil : @import_mail.id
  end
end
