# -*- encoding: utf-8 -*-
module PhotosHelper

  def get_photo_thumbnail(photo)
    str = "<center>".html_safe
    str += image_tag(url_for(:action => 'get_image', :filepath => photo.thumbnail_path))
    str += "<br/>".html_safe
    str += button_to '新規', url_for_business_partner(photo.id), :onclick => "disp_wide(\"" + url_for_photo_preview_popup(photo.id) + "\");"
    str += "　　　"
    str += button_to '更新', url_for_bp_pic(photo.id), :onclick => "disp_wide(\"" + url_for_photo_preview_popup(photo.id) + "\");"
    str += "　　　"
    str += button_to '削除', url_for_delete_photo(photo.id), :confirm => '削除しますか?'
    str += "<br/>".html_safe
    str += photo.photo_sender
    str += "<br/>".html_safe
    str += _timetoddmmhhmm(photo.created_at)
    str += "</center>".html_safe
  end

  def get_photo_thumbnail_link(photo)
    str = "<center>".html_safe
    str += link_to_function(image_tag(url_for(:controller => 'photos', :action => 'get_image', :filepath => photo.thumbnail_path)), "disp_wide('".html_safe + url_for_photo_preview_popup(photo.id) + "');".html_safe)
    str += "<br/>".html_safe
    str += button_to '解除', {:controller => :bp_pic, :action => :update_photo_unlink, :photo_id => photo.id}
    str += "</center>".html_safe
  end
end
