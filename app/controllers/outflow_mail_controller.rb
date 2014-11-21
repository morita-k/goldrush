# -*- encoding: utf-8 -*-
class OutflowMailController < ApplicationController

  def set_conditions
    session[:outflow_mail_search] = {
      outflow_mail_status: params[:outflow_mail_status]
    }
  end

  def make_conditons(import_mail)
    status = session[:outflow_mail_search][:outflow_mail_status]
    conditions = "outflow_mails.deleted = 0"
    conditions += " and import_mail_id = '#{import_mail.id}'"
    conditions += status.blank? ? "" : " and outflow_mail_status_type = '#{status}'"
  end

  def index
    list
    render 'list'
  end

  def list
    @import_mail = ImportMail.find(params[:import_mail_id])
    session[:outflow_mail_search] ||= {}
    if params[:search_button]
      set_conditions
    elsif params[:clear_button]
      session[:outflow_mail_search] = {}
    elsif params[:analyze_button]
      update_outflow_mails(@import_mail)
      return
    end

    cond = make_conditons(@import_mail)

    @outflow_mails = find_login_owner(:outflow_mails).where(cond)
  end

  def quick_input
    import_mail_id = params[:import_mail_id]
    if params[:outflow_mail_id].nil?
      @outflow_mail = find_login_owner(:outflow_mails).where(outflow_mail_status_type: "non_correspondence", import_mail_id: import_mail_id, deleted: 0).first
    else
      @outflow_mail = OutflowMail.where(id: params[:outflow_mail_id], import_mail_id: import_mail_id, deleted: 0).first
    end

    render layout: 'blank'
  end

  def next_address
    import_mail_id = params[:import_mail_id]
    outflow_mail_ids = find_login_owner(:outflow_mails).where(outflow_mail_status_type: "non_correspondence", import_mail_id: import_mail_id, deleted: 0).map(&:id)
    # idが"要素が一意かつ昇順に整列された配列"であることを利用してnext_idを算出
    next_id = outflow_mail_ids.reject{|id| id <= params[:outflow_mail_id].to_i}.first

    redirect_to action: 'quick_input', popup: params[:popup], outflow_mail_id: next_id, import_mail_id: import_mail_id, only_path: false, protocol: "http://"
  end

  def create_quick_input
    outflow_mail = OutflowMail.find(params[:outflow_mail_id].to_i)
    
    case params[:status_update_button]
    when "作成"
      begin
        bp_name = params[:outflow_mail][:business_partner_attributes][:business_partner_name]

        if outflow_mail.business_partner_id.nil? && find_login_owner(:business_partners).where(business_partner_name: bp_name, deleted: 0).first.nil?
          outflow_mail.create_bp_and_pic(params[:outflow_mail])
          flash[:notice] = "Business Partner and BP Pic was successfully created."
        else
          flash[:err] = "既に取引先及び取引先担当者が登録されています。"
        end
      rescue
        flash[:err] = "作成に失敗しました。"
      end
    when "不要"
      if outflow_mail.business_partner_id.nil?
        outflow_mail.unnecessary_mail!
        flash[:notice] = "ステータスを「不要」に設定しました。"
      else
        flash[:err] = "取引先及び取引先担当者が登録されている為「不要」に出来ません。"
      end
    end

    redirect_to( params[:back_to] || {controller: 'outflow_mail', action: 'index'})
  end

  # 混在コンテンツによるブロック回避の為、Formのみiframeで呼ぶ
  def quick_input_form
    @outflow_mail = OutflowMail.find(params[:outflow_mail_id])

    if @outflow_mail.business_partner_id.nil?
      @outflow_mail.build_business_partner
      @outflow_mail.build_bp_pic
    end

    render layout: 'blank'
  end

  def analyze_outflow_mail
    outflow_mail_list_raw = params[:outflow_mail_list][0]
    outflow_mail_list_raw.gsub!(/(\r\n|\r|\n)/, ',')

    unless outflow_mail_list_raw.nil? || outflow_mail_list_raw.size == 0
      outflow_mail_list = outflow_mail_list_raw.split(',').map{|x| x.strip}

      outflow_mail_list.each do |outflow_mail|
        unless outflow_mail =~ (/^[a-zA-Z0-9_¥.¥-]+@[A-Za-z0-9_¥.¥-]+\.[A-Za-z0-9_¥.¥-]+$/)
          flash[:err] = "不正なメールアドレスが含まれております。 " + outflow_mail
          return redirect_to :controller => 'outflow_mail', :action => 'new'#, :params => {:outflow_mail_list_raw => outflow_mail_list_raw}
        end
      end

      now = Time.now
      import_mail = create_model(:import_mails) 
      import_mail.mail_from = 'outflow_mail@applicative.jp'
      import_mail.mail_sender_name = '流出メール解析'
      import_mail.received_at = now
      import_mail.mail_cc = outflow_mail_list_raw
      mail_name = '流出メール解析' + " [#{now.strftime("%Y/%m/%d/ %H:%M:%S")}] "
      import_mail.mail_subject = mail_name + '解析中'
      import_mail.outflow_mail_flg = '1'
      import_mail.matching_way_type = 'other'
      import_mail.foreign_type = 'unknown'
      import_mail.sex_type = 'other'

      import_mail.save!

      Thread.start do

        OutflowMail.create_outflow_mails(import_mail)

        import_mail.mail_subject = mail_name + '完了'

        import_mail.save!
      end

      flash[:notice] = "流出メールの解析を実行中です。"
    end

    return redirect_to :controller => 'outflow_mail', :action => 'new'
  end

  def new
      @outflow_mail_list_raw = params[:outflow_mail_list_raw]

      @import_mails = find_login_owner(:import_mails).includes([]).joins([])
                        .where("outflow_mail_flg = 1")
                        .order("id desc")
                        .page(params[:page])
                        .per(current_user.per_page)
  end

private

  def update_outflow_mails(import_mail)
#    mail_name = import_mail.mail_subject + " [#{Time.now.strftime("%Y/%m/%d/ %H:%M:%S")}] "
#    import_mail.mail_subject = mail_name + '再解析中'

#    import_mail.save!

#    Thread.start do
      OutflowMail.update_outflow_mails(import_mail)
#      import_mail.mail_subject = mail_name + '完了'
#      import_mail.save!
#    end

#    flash[:notice] = "流出メールの解析を実行中です。"
    flash[:notice] = "流出メールの再解析を実行中しました。"
    return redirect_to :controller => 'outflow_mail', :action => 'list', :import_mail_id => import_mail
  end
end
