class DeliveryMailTarget < ActiveRecord::Base

  belongs_to :delivery_mail
  belongs_to :bp_pic

  attr_accessible :bp_pic_id, :delivery_mail_id, :id, :owner_id
  
  def delivery_error
    DeliveryError.where(:delivery_mail_id => delivery_mail_id, :bp_pic_id => bp_pic_id)
  end
  
  def error?
    !self.delivery_error.empty?
  end
end
