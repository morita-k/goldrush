# -*- encoding: utf-8 -*-
module BpPicGroupsHelper
  
  def link_del_from_group(text, bp_pic_group_detail)
    back_to_link '削除', {  :controller => :bp_pic_group_details,
                            :action => :destroy,
                            :id => bp_pic_group_detail.id,
                            :authenticity_token => form_authenticity_token  },
                          :method => :delete,
                          :confirm => "メールグループから削除します。\nよろしいですか？"
  end
  
  def url_for_bp_pic_list(called_by_delivery_mail_create)
    if called_by_delivery_mail_create
      return url_for(:controller => :delivery_mails, :action => :add_details)
    else
      return url_for(:controller => :bp_pic_group_details, :action => :destroy_selection)
    end
  end
  
  def suspended_color(detail)
    suspended_colors[detail.suspended]
  end
  
  def suspended_colors
    {1 => "silver", 0 => "white"}
  end

  def send_buttons
    res = []
    if @delivery_mail
      res << hidden_field_tag('delivery_mail_id', @delivery_mail.id)
      res << hidden_field_tag('bp_pic_group_id', @bp_pic_group.id)
      res << submit_tag("選択した担当者へメール送信", :confirm => "以上の内容で送信予約しますか？\n※予約日時が過去の場合、すぐに送信されます。")
      res << hidden_field_tag(:back_to, request_url)
    else
      res << submit_tag("選択した担当者を削除", :confirm => "選択した担当者をリストから削除します。\nよろしいですか？")
      res << hidden_field_tag('back_to', request_url)
    end
    raw res.join("\n")
  end
  
end
