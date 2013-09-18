# -*- encoding: utf-8 -*-
class OutflowMailController < ApplicationController

  def set_conditions
    session[:outflow_mail_search] = {
      non_correspondence: params[:non_correspondence],
      bad: params[:bad],
      good: params[:good],
      unwanted: params[:unwanted]
    }
  end

  def make_conditons
    sql = "outflow_mails.deleted = 0"

    if !(session[:outflow_mail_search][:non_correspondence]).blank?
      sql += " and outflow_mail_status_type = 'non_correspondence'"
    end

    if !(session[:outflow_mail_search][:bad]).blank?
      sql += " and outflow_mail_status_type = 'bad'"
    end

    if !(session[:outflow_mail_search][:good]).blank?
      sql += " and outflow_mail_status_type = 'good'"
    end

    if !(session[:outflow_mail_search][:unwanted]).blank?
      sql += " and outflow_mail_status_type = 'unwanted'"
    end

    sql
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

    @outflow_mails = OutflowMail.where(cond, "")
  end

  def quick_input
    # params[:outflow_mail_id] ||= OutflowMail.where(deleted: 0).first.id
    params[:page] ||= "1"

    if params[:outflow_mail_id].nil?
      @outflow_mail = OutflowMail.where(outflow_mail_status_type: "non_correspondence", deleted: 0).first
    else
      @outflow_mail = OutflowMail.where(id: params[:outflow_mail_id], deleted: 0).first
    end

    @target_data = {:emptyFlag => true, :targetName => ''}
    if @outflow_mail.nil?
      @target_data[:emptyFlag] = true
    else
      @target_data[:emptyFlag] = false
      @target_data[:targetName] = :outflow_mail
    end

    render template: 'business_partner/quick_input', layout: 'blank'
  end

  def next_address
    current_outflow_mail_id = params[:outflow_mail_id].to_i
    
    outflow_mail_ids = OutflowMail.where(outflow_mail_status_type: "non_correspondence", deleted: 0).map(&:id)
    current_index = outflow_mail_ids.index(current_outflow_mail_id)

    next_id = outflow_mail_ids[current_index.succ]

    # pagenate機能をつける時の為に、params[:page]の引き回し処理は持たせておく
    redirect_to action: 'quick_input', page: params[:page], popup: params[:popup], outflow_mail_id: next_id
  end

  def update_quick_input
    begin
      outflow_mail = OutflowMail.find(params[:outflow_mail_id].to_i)
      form_params = OutflowMail::FormParameters.new(params[:outflow_mail_form])

      if BusinessPartner.where(business_partner_name: form_params.business_partner_name, deleted: 0).first
        outflow_mail.update_bp_and_pic(form_params.business_partner_name, form_params.email, "", "", "")
        flash[:notice] = "successful update!"
      else
        outflow_mail.create_bp_and_pic(form_params.business_partner_name, form_params.email, "", "", "")
        flash[:notice] = "successful create!"
      end
    # rescue
    #   flash[:err] = "error"
    end

    redirect_to( params[:back_to] || {controller: 'outflow_mail', action: 'index'})
  end

  # 混在コンテンツによるブロック回避の為、Formのみhttpsでiframe内から呼ぶ
  def quick_input_form
  end

private #=========================

  def get_outflow_mail_id(id)
    unless id.nil?

    else
      OutflowMail.where(deleted: 0).first.id
    end
  end

end