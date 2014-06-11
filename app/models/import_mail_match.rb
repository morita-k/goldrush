# -*- encoding: utf-8 -*-
class ImportMailMatch < ActiveRecord::Base

  belongs_to :biz_offer_mail, :class => "ImportMail", :foreign_key => "biz_offer_mail_id"
  belongs_to :bp_member_mail, :class => "ImportMail", :foreign_key => "bp_member_mail_id"

end
