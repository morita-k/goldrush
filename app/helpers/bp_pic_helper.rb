# -*- encoding: utf-8 -*-
module BpPicHelper

  def search_value(code)
    session[:bp_pic_search] && session[:bp_pic_search][code]
  end

  def working_status_type_links_list(bp_pic)
    [working_status_type_link_retired(around_b_if(bp_pic.substitute_bp_pic_id, getLongType("working_status_type","retired")), bp_pic, bp_pic.substitute_bp_pic_id),
    working_status_type_link_changed(around_b_if(bp_pic.change_to_bp_pic_id, getLongType("working_status_type","changed")), bp_pic, bp_pic.change_to_bp_pic_id)]
  end

  def working_status_type_links_show(bp_pic)
    if bp_pic.working?
      [working_status_type_update_link(bp_pic.id, "retired")]
    else
      [working_status_type_link_retired(bp_pic.substitute_bp_pic_id.blank? ? "後任者登録" : "後任者", bp_pic, bp_pic.substitute_bp_pic_id),
        working_status_type_link_changed(bp_pic.change_to_bp_pic_id.blank? ? "転職先登録" : "転職先", bp_pic, bp_pic.change_to_bp_pic_id)]
    end
  end

  def bp_pic_form_title
    current_business_partner = @business_partner || @bp_pic.business_partner
    if @bp_pic.new_record?
      if current_business_partner
        "#{current_business_partner.business_partner_short_name} #{params[:retired_bp_pic_id] && '後任'}担当新規作成"
      else
        "担当新規作成"
      end
    else
      "#{@bp_pic.bp_pic_name} (#{current_business_partner.business_partner_short_name})編集"
    end
  end

private
  def working_status_type_link_retired(name, bp_pic, new_bp_pic_id)
    if new_bp_pic_id.blank?
      back_to_link(name,{:controller => :bp_pic, :action => :new, :retired_bp_pic_id => bp_pic.id, :business_partner_id => bp_pic.business_partner.id}, :title => '後任者登録をする', :class => "btn btn-default btn-xs")
    else
      back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_bp_pic_id}, :title => '後任者をみる', :class => "btn btn-default btn-xs")
    end
  end

  def working_status_type_link_changed(name, bp_pic, new_bp_pic_id)
    if new_bp_pic_id.blank?
      back_to_link(name,{:controller => :business_partner, :action => :new, :former_bp_pic_id => bp_pic.id}, :title => '転職先の登録をする', :class => "btn btn-default btn-xs")
    else
      back_to_link(name,{:controller => :bp_pic, :action => :show, :id => new_bp_pic_id}, :title => '転職先をみる', :class => "btn btn-default btn-xs")
    end
  end

  def working_status_type_update_link(id, status)
    back_to_link(getLongType("working_status_type",status), {:controller => :bp_pic, :action => :update_working_status_type, :id => id, :working_status_type => status}, :confirm => "勤務ステータスを「#{getLongType("working_status_type",status)}」に変更します。よろしいですか?", :class => "btn btn-default btn-xs")
  end

  def set_bp_pic_url_param
    url_param = params[:callback].blank? ? {} : {:callback => params[:callback]}
    url_param[:photo_id] = params[:photo_id]

    url_param
  end
end
