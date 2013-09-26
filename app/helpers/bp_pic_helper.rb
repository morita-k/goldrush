# -*- encoding: utf-8 -*-
module BpPicHelper

  def search_value(code)
    session[:bp_pic_search] && session[:bp_pic_search][code]
  end

  def working_status_links_list(bp_pic)
    [working_status_link_retired(around_b_if(bp_pic.substitute_bp_pic_id, getShortType("working_status","retired")), bp_pic, bp_pic.substitute_bp_pic_id),
     working_status_link_changed(around_b_if(bp_pic.change_to_bp_pic_id, getShortType("working_status","changed")), bp_pic, bp_pic.change_to_bp_pic_id)]
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
      back_to_link(name,{:controller => :bp_pic, :action => :new, :retired_bp_pic_id => bp_pic.id, :business_partner_id => bp_pic.business_partner.id}, :title => '後任者登録をする')
    else
      back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_bp_pic_id}, :title => '後任者をみる')
    end
  end

  def working_status_link_changed(name, bp_pic, new_bp_pic_id)
    if new_bp_pic_id.blank?
      back_to_link(name,{:controller => :business_partner, :action => :new, :former_bp_pic_id => bp_pic.id}, :title => '転職先の登録をする')
    else
      back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_bp_pic_id}, :title => '転職先をみる')
    end
  end

  def working_status_update_link(id, status)
    back_to_link(getLongType("working_status",status), {:controller => :bp_pic, :action => :update_working_status, :id => id, :working_status => status}, :confirm => "勤務ステータスを「#{getLongType("working_status",status)}」に変更します。よろしいですか?")
  end

  def set_url_param
    url_param = params[:callback].blank? ? {} : {:callback => params[:callback]}
    url_param[:photoid] = @photo_id if @photo_id

    url_param
  end
end
