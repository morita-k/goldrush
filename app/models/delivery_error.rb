class DeliveryError < ActiveRecord::Base
  belongs_to :delivery_mail
  belongs_to :bp_pic
  
  def DeliveryError.build(delivery_mail_id, bp_pic, error_type, error_text)
    error = DeliveryError.new()
    error.delivery_mail_id = delivery_mail_id
    error.business_partner_id = bp_pic.business_partner_id
    error.bp_pic_id = bp_pic.id
    error.email = bp_pic.email1
    error.mail_error_type = error_type
    error.mail_error_text = error_text
    return error
  end
  
  def DeliveryError.send_error(delivery_mail_id, bp_pic, exception)
    error_type = :send_error
    error_text = ([exception.class.to_s, exception.message] + exception.backtrace).join("\n")
    
    return self.build(delivery_mail_id, bp_pic, error_type, error_text)
  end
  
end
