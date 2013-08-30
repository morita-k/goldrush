# -*- encoding: utf-8 -*-
module DeliveryMailsHelper
  
  def row_style(delivery_mail)
    if    delivery_mail.canceled?
      return 'canceled'
    elsif delivery_mail.unsend?
      return 'unsend'
    elsif delivery_mail.delivery_errors.count > 0
      return 'warn'
    else
      return 'send'
    end
  end
  
  def group?
    return !params[:bp_pic_group_id].blank?
  end

  def mail_to(delivery_mail)
    if delivery_mail.group?
      #グループメールの場合
      if bp_pic_group = delivery_mail.bp_pic_group
        return content_tag(:div, bp_pic_group.bp_pic_group_name, {:style=>"overflow: hidden;height:1.5em;word-wrap: break-word;word-break: break-all;", :title=>bp_pic_group.bp_pic_group_name})
      end
    else
      #即席メールの場合
      targets =[]
      delivery_mail.delivery_mail_targets.each do |target|
        next if !delivery_mail.unsend? && target.message_id.blank?
        targets.push(target.bp_pic.business_partner_name + " " + target.bp_pic.bp_pic_short_name)
      end
      return content_tag(:div, targets.join(", "), {:style=>"overflow: hidden;height:1.5em;word-wrap: break-word;word-break: break-all;", :title=>targets.join("\n")})
    end
    return ""
  end

end
