# -*- encoding: utf-8 -*-
class DeliveryMailMatch < ActiveRecord::Base

  belongs_to :import_mail
  belongs_to :delivery_mail

  def DeliveryMailMatch.matched?(delivery_mail_id, import_mail_id)
    exists?(deleted: 0, delivery_mail_id: delivery_mail_id, import_mail_id: import_mail_id)
  end

  def DeliveryMailMatch.match(delivery_mail_id, import_mail_id)
    where(deleted: 0, delivery_mail_id: delivery_mail_id, import_mail_id: import_mail_id).first
  end

end
