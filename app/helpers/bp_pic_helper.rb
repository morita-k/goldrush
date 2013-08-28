# -*- encoding: utf-8 -*-
module BpPicHelper

  def search_value(code)
    session[:bp_pic_search] && session[:bp_pic_search][code]
  end

  def working_status_links_list(bp_pic)
  	[working_status_link_retired(getShortType("working_status","retired"), bp_pic, bp_pic.substitute_bp_pic_id),
     working_status_link_changed(getShortType("working_status","changed"), bp_pic, bp_pic.change_to_bp_pic_id)]
  end

  def working_status_links_show(bp_pic)
    if bp_pic.working?
      [working_status_update_link(bp_pic.id, "retired"), working_status_update_link(bp_pic.id, "changed")]
    else
      [working_status_link_retired(bp_pic.substitute_bp_pic_id.blank? ? "後任者登録" : "後任者", bp_pic, bp_pic.substitute_bp_pic_id),
        working_status_link_changed(bp_pic.change_to_bp_pic_id.blank? ? "転職先登録" : "転職先", bp_pic, bp_pic.change_to_bp_pic_id)]
    end
  end

  private
  def working_status_link_retired(name, bp_pic, new_bp_pic_id)
    if new_bp_pic_id.blank?
      back_to_link(name,{:controller => :bp_pic, :action => :new, :retired_bp_pic_id => bp_pic.id, :business_partner_id => bp_pic.business_partner.id})
    else
      back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_bp_pic_id})
    end
  end

  private
  def working_status_link_changed(name, bp_pic, new_bp_pic_id)
    if new_bp_pic_id.blank?
      back_to_link(name,{:controller => :business_partner, :action => :new, :former_bp_pic_id => bp_pic.id})
    else
      back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_bp_pic_id})
    end
  end

  private
  def working_status_update_link(id, status)
    link_to(getLongType("working_status",status), {:controller => :bp_pic, :action => :update_working_status, :id => id, :working_status => status}, :confirm => "勤務ステータスを「#{getLongType("working_status",status)}」に変更します。よろしいですか?")
  end

end
