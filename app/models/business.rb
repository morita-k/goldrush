# -*- encoding: utf-8 -*-
class Business < ActiveRecord::Base
  include AutoTypeName

  validates_presence_of :business_status_type, :issue_datetime, :business_title

  belongs_to :eubp, :class_name => 'BusinessPartner'
  belongs_to :eubp_pic, :class_name => 'BpPic'
  has_many :biz_offers, :conditions => ["biz_offers.deleted = 0"]

  def make_skill_tags!
    require 'string_util'
    words = StringUtil.detect_words([skill_must, skill_want].join(" "))
    Tag.update_tags!("businesses", id, words.join(","))
    self.skill_tag = words.join(",")
  end

end
