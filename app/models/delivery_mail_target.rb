class DeliveryMailTarget < ActiveRecord::Base
  belongs_to :delivery_mail
  belongs_to :bp_pic
  has_many :reply_mails, :class_name => 'ImportMail', :foreign_key => 'in_reply_to', :primary_key => 'message_id', :order => "import_mails.id"
  
  attr_accessible :bp_pic_id, :delivery_mail_id, :id, :owner_id

  def get_reply_import_mail
    @import_mail = ImportMail.where(:owner_id => self.owner_id, :in_reply_to => self.message_id).first if self.message_id
  end

  def get_import_mail_id
    @import_mail.nil? ? nil : @import_mail.id
  end
end
