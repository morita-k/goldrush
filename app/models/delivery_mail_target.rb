class DeliveryMailTarget < ActiveRecord::Base
  belongs_to :delivery_mail
  belongs_to :bp_pic
  
  attr_accessible :bp_pic_id, :delivery_mail_id, :id, :owner_id

  def get_reply_import_mail
    ImportMail.where(:in_reply_to => message_id).first if message_id
  end
end
