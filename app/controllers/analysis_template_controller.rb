# -*- encoding: utf-8 -*-
class AnalysisTemplateController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    if params[:mode] && params[:import_mail_id]
      order_by = []
      if import_mail = ImportMail.find(:first, :conditions => ["id = ?", params[:import_mail_id]])
        order_by << "bp_pic_id = #{import_mail.bp_pic_id} desc" if !import_mail.bp_pic_id.blank?
        order_by << "business_partner_id = #{import_mail.business_partner_id} desc" if !import_mail.business_partner_id.blank?
      end
      order_by << "id desc"
      @analysis_templates = AnalysisTemplate.find(:all, :conditions => "deleted = 0", :order => order_by.join(","))
    else
      @analysis_template_pages, @analysis_templates = paginate :analysis_templates, :conditions => "deleted = 0", :per_page => current_user.per_page
    end
  end

  def show
    @analysis_template = AnalysisTemplate.find(params[:id])
    @analysis_template_items = @analysis_template.analysis_template_items
  end

  def new
    @analysis_template = AnalysisTemplate.new
    @analysis_template.analysis_template_type = params[:mode]
    unless params[:import_mail_id].blank?
      import_mail = ImportMail.find(params[:import_mail_id])
      @analysis_template.business_partner = import_mail.business_partner
      @analysis_template.bp_pic = import_mail.bp_pic
    end
    
    if params[:mode] == "biz_offer"
      @business_column_names = get_column_names("business")
      @biz_offer_column_names = get_column_names("biz_offer")
    elsif params[:mode] == "bp_member"
      @human_resource_column_names = get_column_names("human_resource")
      @bp_member_column_names = get_column_names("bp_member")
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @analysis_template = AnalysisTemplate.new(params[:analysis_template])
      @analysis_template.analysis_template_type = params[:mode]
      set_user_column @analysis_template
      @analysis_template.save!
      
      if params[:mode] == "biz_offer"
        create_analysis_template_item("business")
        create_analysis_template_item("biz_offer")
      elsif params[:mode] == "bp_member"
        create_analysis_template_item("human_resource")
        create_analysis_template_item("bp_member")
      end
      
    end # transaction
    
    flash[:notice] = 'AnalysisTemplate was successfully created.'
    redirect_to(params[:back_to] || {:action => 'list'})
  rescue ActiveRecord::RecordInvalid
    if params[:mode] == "biz_offer"
      @business_column_names = get_column_names("business")
      @biz_offer_column_names = get_column_names("biz_offer")
    elsif params[:mode] == "bp_member"
      @human_resource_column_names = get_column_names("human_resource")
      @bp_member_column_names = get_column_names("bp_member")
    end
    render :action => 'new'
  end

  def edit
    @analysis_template = AnalysisTemplate.find(params[:id])
  end

  def update
    @analysis_template = AnalysisTemplate.find(params[:id], :conditions =>["deleted = 0"])
    @analysis_template.attributes = params[:analysis_template]
    set_user_column @analysis_template
    @analysis_template.save!
    flash[:notice] = 'AnalysisTemplate was successfully updated.'

    redirect_to(params[:back_to] || {:action => :show, :id => @analysis_template})
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @analysis_template = AnalysisTemplate.find(params[:id], :conditions =>["deleted = 0"])
    @analysis_template.deleted = 9
    @analysis_template.deleted_at = Time.now
    set_user_column @analysis_template
    @analysis_template.save!
    
    redirect_to(back_to || {:action => 'list'})
  end

  def popup_list
     @analysis_template_pages, @analysis_templates = paginate :analysis_templates, :conditions => "deleted = 0", :per_page => current_user.per_page
     render :layout => 'popup'
  end
  
private
  
  def get_column_names(target_table_name)
    column_names = Array.new
    target_column_names = AnalysisTemplateItem.get_target_column_names(target_table_name)
    pluralized_target_table_name = target_table_name.pluralize
    # 名称とるために複数形にする
    target_column_names.each do |target_column_name|
      column_long_name = getLongName(pluralized_target_table_name, target_column_name)
      column_names << [target_column_name, column_long_name]
    end
    return column_names
  end
  
  def create_analysis_template_item(target_table_name)
    target_column_names = AnalysisTemplateItem.get_target_column_names(target_table_name)
    target_column_names.each do |target_column_name|
      if !params["analysis_template_item_#{target_table_name}_#{target_column_name}"]['pattern'].blank?
        # パターンが入力されてたら保存対象
        analysis_template_item = AnalysisTemplateItem.new(params["analysis_template_item_#{target_table_name}_#{target_column_name}"])
        analysis_template_item.analysis_template_id = @analysis_template.id
        analysis_template_item.target_table_name = target_table_name.pluralize
        analysis_template_item.target_column_name = target_column_name
        set_user_column analysis_template_item
        analysis_template_item.save!
      end
    end
  end
end
