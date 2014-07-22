# -*- encoding: utf-8 -*-
class ImportMailMatch < ActiveRecord::Base
  include AutoTypeName

  belongs_to :biz_offer_mail, :class_name => "ImportMail", :foreign_key => "biz_offer_mail_id"
  belongs_to :bp_member_mail, :class_name => "ImportMail", :foreign_key => "bp_member_mail_id"

end
