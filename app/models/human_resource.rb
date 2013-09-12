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
  
  # タグ生成の本体
  def make_tags(body)
    Tag.analyze_skill_tags(Tag.pre_proc_body(body))
  end

  def make_skill_tags!
    self.skill_tag = make_tags(skill)
    Tag.update_tags!("human_resources", id, skill_tag)
  end

  # 年齢はDBに入れる前に半角数字(String)のみにする
  def HumanResource.normalize_age(str)
    require 'zen2han'
    unless str.blank?
      Zen2Han.toHan(str).gsub(/[歳才]/, "")
    else
      str
    end
  end

  def HumanResource.to_normalize_age_all!
    HumanResource.where("age is not null").reject{|hr| hr.age.blank?}.map{|hr|
      hr.age = HumanResource.normalize_age(hr.age)
      hr.save!
    }
  end

  def jiet?
    self.jiet == 1
  end

  def nearest_station_short
    StringUtil.strip_with_full_size_space(ImportMail.extract_station_name_from(near_station).to_s)
  end
  
end
