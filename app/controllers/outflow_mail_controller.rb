# -*- encoding: utf-8 -*-
class OutflowMailController < ApplicationController

  def set_conditions
    session[:outflow_mail_search] = {
      outflow_mail_status: params[:outflow_mail_status]
    }
  end

  def make_conditons
    status = session[:outflow_mail_search][:outflow_mail_status]
    "outflow_mails.deleted = 0" + (status.blank? ? "" : " and outflow_mail_status_type = '#{status}'")
  end

  def index
    list
    render 'list'
  end

  def list
    session[:outflow_mail_search] ||= {}
    if params[:search_button]
      set_conditions
    elsif params[:clear_button]
      session[:outflow_mail_search] = {}
    end

    cond = make_conditons

    @outflow_mails = OutflowMail.where(cond)
  end

  def quick_input
    if params[:outflow_mail_id].nil?
      @outflow_mail = OutflowMail.where(outflow_mail_status_type: "non_correspondence", deleted: 0).first
    else
      @outflow_mail = OutflowMail.where(id: params[:outflow_mail_id], deleted: 0).first
    end

    render layout: 'blank'
  end

  def next_address
    outflow_mail_ids = OutflowMail.where(outflow_mail_status_type: "non_correspondence", deleted: 0).map(&:id)
    # idが"要素が一意かつ昇順に整列された配列"であることを利用してnext_idを算出
    next_id = outflow_mail_ids.reject{|id| id <= params[:outflow_mail_id].to_i}.first

    redirect_to action: 'quick_input', popup: params[:popup], outflow_mail_id: next_id, only_path: false, protocol: "http://"
  end

  def create_quick_input
    outflow_mail = OutflowMail.find(params[:outflow_mail_id].to_i)
    
    case params[:status_update_button]
    when "作成"
      begin
        bp_name = params[:outflow_mail][:business_partner_attributes][:business_partner_name]

        if outflow_mail.business_partner_id.nil? && BusinessPartner.where(business_partner_name: bp_name, deleted: 0).first.nil?
          outflow_mail.create_bp_and_pic(params[:outflow_mail])
          flash[:notice] = "Business Partner and BP Pic was successfully created."
        else
          flash[:err] = "既に取引先及び取引先担当者が登録されています。"
        end
      rescue
        flash[:err] = "作成に失敗しました。"
      end
    when "不要"
      unless outflow_mail.business_partner_id.nil?
        outflow_mail.unnecessary_mail!
        flash[:notice] = "ステータスを不要に設定しました。"
      else
        flash[:err] = "既に取引先及び取引先担当者が登録されています。"
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

end