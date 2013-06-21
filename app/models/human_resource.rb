# -*- encoding: utf-8 -*-
class HumanResource < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize

  has_many :bp_members, :conditions => ["bp_members.deleted = 0"]

  validates_presence_of :initial

  def after_initialize 
    init_actions([
      [:sales, :approached, :approach],
      [:sales, :unknown, :pass_away],
      [:approached, :sales, :reject_interview],
      [:approached, :waiting, :get_job],
      [:waiting, :working, :start_work],
      [:working, :sales, :exit],
      [:unknown, :sales, :check_status],
      [:unknown, :approached, :approach],
    ])
  end

  def useful_name
    human_resource_name.blank? ? initial : human_resource_name
  end
  
  def change_status_type
    
  end
  
  def make_skill_tags!
    require 'string_util'
    words = StringUtil.detect_words(skill)
    Tag.update_tags!("human_resources", id, words.join(","))
    self.skill_tag = words.join(",")
  end
end
