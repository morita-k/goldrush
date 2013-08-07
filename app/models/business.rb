# -*- encoding: utf-8 -*-
#require 'business_flow'
class Business < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize

  validates_presence_of :business_status_type, :issue_datetime, :business_title

  belongs_to :eubp, :class_name => 'BusinessPartner'
  belongs_to :eubp_pic, :class_name => 'BpPic'
  has_many :biz_offers, :conditions => ["biz_offers.deleted = 0"]

  before_save :derive_business_partner

  def derive_business_partner
    if eubp_pic
      if eubp_id.blank? || eubp_id != eubp_pic.business_partner_id
        self.eubp_id = eubp_pic.business_partner_id
      end
    end
  end

  # タグ生成の本体
  def make_tags(body)
    Tag.analyze_skill_tags(Tag.pre_proc_body(body))
  end

  def make_skill_tags!
    self.skill_tag = make_tags([skill_must, skill_want].join(" "))
    Tag.update_tags!("businesses", id, skill_tag)
  end

  def after_initialize 
    init_actions([
      [:open, ->(x){:approached}, :approach],
      [:open, :other_failure, :choice_other],
      [:open, :lost_failure, :lost],
      [:open, :natural_lost, :pass_away],
      [:approached, :open, :reject_approach],
      [:approached, :working, :get_job],
      [:approached, :other_failure, :choice_other],
      [:approached, :lost_failure, :lost],
      [:approached, :natural_lost, :pass_away],
      [:working, :finished, :finish],
      [:other_failure, :open, :revert],
      [:lost_failure, :open, :revert],
      [:natural_lost, :open, :revert],
    ])
  end
end
