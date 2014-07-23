# -*- encoding: utf-8 -*-
require 'type_util'
module AutoTypeName
  include TypeUtil

  alias old_method_missing method_missing if respond_to? :method_missing

  def type_name(attr_name, name_type = :long)
    case name_type
    when :long  then getLongType attr_name,  self.send(attr_name.to_s)
    when :short then getShortType attr_name, self.send(attr_name.to_s)
    when :other then getOtherType attr_name, self.send(attr_name.to_s)
    end
  end

  def method_missing(method_symbol, *parameters)
    if method_symbol.to_s.match /(.*)_type_long_name$/
      type_name "#{$1}_type"
    elsif method_symbol.to_s.match /(.*)_type_short_name$/
      type_name "#{$1}_type", :short
    elsif method_symbol.to_s.match /(.*)_type_other_name$/
      type_name "#{$1}_type", :other
    elsif method_symbol.to_s.match /(.*)_type_name$/
      type_name "#{$1}_type"
    elsif respond_to? :old_method_missing
      old_method_missing method_symbol, *parameters
    else
      super
    end
  end

end

