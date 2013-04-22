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
end
