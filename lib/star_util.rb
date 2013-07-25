module StarUtil
  
  def StarUtil.attr_id(target)
   "starred_icon_#{target.class.name}_#{target.id}"
  end
  
  def StarUtil.attr_class(target)
   "starred_icon_#{target.class.name}_#{target.id}"
  end
  
  def StarUtil.attr_name(target)
    "starred_icon_name_#{target.class.name}_#{target.id}"
  end
  
  def StarUtil.attr_style(star_value)
    "color: #{SysConfig.star_color[star_value]}; text-shadow: 1px 1px 1px gainsboro;"
  end
  
end
