# -*- encoding: utf-8 -*-
module BpPicHelper

  def search_value(code)
    session[:bp_pic_search] && session[:bp_pic_search][code]
  end

  def working_status_retired_link(bp_pic)
  	build_working_status_link(bp_pic.substitute_bp_pic_id.blnak? ? "後任者登録" : "後任者", bp_pic.id, bp_pic.substitute_bp_pic_id)
  end

  def working_status_changed_link(bp_pic)
  	build_working_status_link(bp_pic.change_to_bp_pic_id.blank? ? "転職先登録" : "転職先", bp_pic.id, bp_pic.change_to_bp_pic_id)
  end

  def working_status_retired_link_short(bp_pic)
  	build_working_status_link(getShortType("working_status","retired"), bp_pic.id, bp_pic.substitute_bp_pic_id)
  end

  def working_status_changed_link_short(bp_pic)
  	build_working_status_link(getShortType("working_status","changed"), bp_pic.id, bp_pic.change_to_bp_pic_id)
  end

  def build_working_status_link(name, old_id, new_id)
    back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_id.blank? ? old_id : new_id})
  end

end
