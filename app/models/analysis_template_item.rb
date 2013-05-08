# -*- encoding: utf-8 -*-
class AnalysisTemplateItem < ActiveRecord::Base

  belongs_to :analysis_template

  validates_presence_of :analysis_template_item_name, :pattern, :target_table_name, :target_column_name
  validates_each :pattern do |model, attr, value|
    model.errors.add(attr, 'is incorrect regex.') unless AnalysisTemplateItem.correct_regex(value)
  end
  
  def AnalysisTemplateItem.get_target_column_names(target_table_name)
    case target_table_name
      when "businesses"
        return AnalysisTemplateItem.businesses_column_names
      when "biz_offers"
        return AnalysisTemplateItem.biz_offers_column_names
      when "human_resources"
        return AnalysisTemplateItem.human_resources_column_names
      when "bp_members"
        return AnalysisTemplateItem.bp_members_column_names
    end
  end
  
  
  def AnalysisTemplateItem.businesses_column_names
    [
      "due_date",
      "term_type",
      "business_title",
      "business_point",
      "business_description",
      "member_change_flg",
      "place",
      "period",
      "phase",
      "need_count",
      "skill_must",
      "skill_want",
      "business_hours",
      "assumed_hour",
      "career_years",
      "age_limit",
      "nationality_limit",
      "sex_limit",
      "communication",
      "memo"
    ]
  end
  
  def AnalysisTemplateItem.biz_offers_column_names
    [
      "due_date",
      "reprint_flg",
      "winning_rate",
      "sales_route",
      "payment_text",
      "payment_max",
      "time_adjust_text",
      "skill_consideration_flg",
      "interview_times",
      "interview_times_memo",
      "sales_route_limit",
      "application_format",
      "memo"
    ]
  end
  
  def AnalysisTemplateItem.human_resources_column_names
    [
      "human_resource_name",
      "human_resource_short_name",
      "human_resource_name_kana",
      "initial",
      "email",
      "tel1",
      "tel2",
      "age",
      "birthday_date",
      "sex_type",
      "nationality",
      "railroad",
      "near_station",
      "max_move_time",
      "skill",
      "qualification",
      "communication_type",
      "attendance",
      "memo"
    ]
  end
  
  def AnalysisTemplateItem.bp_members_column_names
    [
      "employment_type",
      "reprint_flg",
      "can_start_date",
      "can_interview_date",
      "race_condition",
      "payment_memo",
      "payment_min",
      "time_adjust_term",
      "memo"
    ]
  end
  
  def AnalysisTemplateItem.correct_regex(pattern) 
    begin
      Regexp.new(pattern)
      true
    rescue
      false
    end
  end
  
end
