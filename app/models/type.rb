# -*- encoding: utf-8 -*-
class Type < ActiveRecord::Base

  validates_presence_of :long_name
  validates_numericality_of :display_order1, :only_integer => true

  def self.get_config_list(type_section)
    Type.where('deleted = 0 and type_section = ?', type_section).order(:id)
  end
end
