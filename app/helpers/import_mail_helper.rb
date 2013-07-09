# -*- encoding: utf-8 -*-
module ImportMailHelper
  # 各メールのフラグを変更するリンクタグを生成する
  def build_flag_link(text, mode, style_flag, import_mail)
    # 対象のリンク生成モードで、メールに紐付くレコードがある場合、"true"になる
    registered = is_registerd?(import_mail, mode)
    
    # spanタグにつけるIDを生成する
    span_id = "#{mode}_icon_#{import_mail.id}"
    
    # フラグの値を取得する
    flagged_up = (import_mail.send(style_flag) == 1)
    
    # onclickイベントを生成する
    onclick = "return changeFlg(#{import_mail.id}, '#{mode}');"
    
    # 各タグを生成する
    div = content_tag(:div, :id => span_id, :class => flag_style_class(registered, flagged_up) ){ text }
    link = content_tag(:a, :href => "#", :onclick => onclick){ div }
    
    # 紐づくレコードがある場合、リンクにしない
    # メールの解析をしたら、案件、人材を手動で振り分ける事はない想定
    # 解析テンプレートがない場合のみ
    if( registered )
      return raw( div )
    else
      return raw( link )
    end
  end
  
  def flag_style_class(registered, flagged_up)
    clazz = "flag"
    if    registered
      clazz += " registered"
    elsif flagged_up
      clazz += " flagged_up"
    end
    return clazz
  end
  
  def is_registerd?(import_mail, reg_to)
    case reg_to
    when :biz_offer
      return import_mail.biz_offers.exists?
    when :bp_member
      return import_mail.bp_members.exists?
    end
    # それ以外は常にfalse
    return false
  end
  
  # オブジェクトが指定したIDの取り込みメールに紐付いているかを調べる
  # object         : 検査対象オブジェクト
  # import_mail_id : 対象の取り込みメールID
  def has_related_import_mail(object, import_mail_id)
    result = false
    if object.has_method(:import_mail_id)
      result = object.import_mail_id == import_mail_id
    end
    return result;
  end
  
  # 以下、リンク生成ヘルパー
  
  # 
  def link_to_import_api(text)
    back_to_link text, {:controller => :api, :action => :import_mail_pop3}, :confirm => "POP3にてメールを取り込みます。よろしいですか？"
  end
  
  def link_to_analyze_tags_api(text)
    back_to_link text, {:controller => :api, :action => :analyze_tags}, :confirm => "取り込みメールのタグを再計算します。よろしいですか？"
  end
  
  def link_to_detail(import_mail, back_to_url)
    link_to h(import_mail.mail_subject), :action => :show, :id => import_mail, :back_to => back_to_url
  end
  
  def link_to_bp_detail(import_mail)
    link_to import_mail.mail_sender_name, :controller => :business_partner, :action => :show, :id => import_mail.business_partner_id
  end
  
  def link_to_biz_create(text, import_mail)
    link_to text, url_for(:controller => 'analysis_template', :action => 'list', :popup => 1, :mode => 'biz_offer', :import_mail_id => import_mail), :class => :analysis_mail_link
  end
  
  def link_to_hresource_create(text, import_mail)
    link_to text, url_for(:controller => 'analysis_template', :action => 'list', :popup => 1, :mode => 'bp_member', :import_mail_id => import_mail), :class => :analysis_mail_link
  end
  
  def link_to_bp_create(text, import_mail)
    link_to text, url_for(:controller => 'business_partner', :action => 'new', :popup => 1, :import_mail_id => import_mail), :class => :analysis_mail_link
  end
  
  def link_to_bp_pic_create(text, import_mail)
    link_to text, url_for(:controller => :bp_pic, :action => :new, :popup => 1, :import_mail_id => import_mail, :business_partner_id => import_mail.business_partner_id), :class => :analysis_mail_link
  end
  
  def format_tags(tag_text, words)
    tag_text.to_s.split(",").map do |x|
      if Tag.good_tags.include?(x.downcase)
        "<span class='label label-inverse tag'>#{x}</span>"
      elsif Tag.bad_tags.include?(x.downcase)
        nil
      else
        "<span class='label tag'>#{x}</span>"
      end
    end.compact.join(" ")
  end

  def format_only_major_tags(tag_text, words)
    tag_text.to_s.split(",").map do |x|
      if Tag.good_tags.include?(x.downcase)
        "<span class='label label-inverse tag'>#{x}</span>"
      else
        nil
      end
    end.compact.join(" ")
  end
end
