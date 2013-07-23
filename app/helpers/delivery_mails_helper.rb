# -*- encoding: utf-8 -*-
module DeliveryMailsHelper
  
  def row_style(delivery_mail)
    if    delivery_mail.canceled?
      return 'canceled'
    elsif delivery_mail.unsend?
      return 'unsend'
    elsif delivery_mail.include_error?
      return 'warn'
    else
      return 'send'
    end
  end
  
end
