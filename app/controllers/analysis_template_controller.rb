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
      @business_column_names = get_column_names("businesses")
      @biz_offer_column_names = get_column_names("biz_offers")
    elsif params[:mode] == "bp_member"
      @human_resource_column_names = get_column_names("human_resources")
      @bp_member_column_names = get_column_names("bp_members")
    end
  end

  def create
    ActiveRecord::Base.transaction do
      @analysis_template = AnalysisTemplate.new(params[:analysis_template])
      @analysis_template.analysis_template_type = params[:mode]
      set_user_column @analysis_template
      @analysis_template.save!
      items = get_items(params[:mode], params)
      items.each do |item|
        item.analysis_template_id = @analysis_template.id
        item.save!
      end
    end # transaction
    
    flash[:notice] = 'AnalysisTemplate was successfully created.'
    redirect_to(params[:back_to] || {:action => 'list'})
  rescue ActiveRecord::RecordInvalid
    if params[:mode] == "biz_offer"
      @business_column_names = get_column_names("businesses")
      @biz_offer_column_names = get_column_names("biz_offers")
    elsif params[:mode] == "bp_member"
      @human_resource_column_names = get_column_names("human_resources")
      @bp_member_column_names = get_column_names("bp_members")
    end
    @item_value_map = get_item_value_map(get_items(params[:mode], params))
    render :action => 'new', :back_to => back_to
  end

  def edit
    @analysis_template = AnalysisTemplate.find(params[:id])
    @mode = @analysis_template.analysis_template_type

    if @mode == "biz_offer"
      @business_column_names = get_column_names("businesses")
      @biz_offer_column_names = get_column_names("biz_offers")
    elsif @mode == "bp_member"
      @human_resource_column_names = get_column_names("human_resources")
      @bp_member_column_names = get_column_names("bp_members")
    end
    @item_value_map = get_item_value_map(@analysis_template.analysis_template_items)
  end

  def update
    ActiveRecord::Base.transaction do
      @analysis_template = AnalysisTemplate.find(params[:id], :conditions =>["deleted = 0"])
      @mode = @analysis_template.analysis_template_type
      @analysis_template.attributes = params[:analysis_template]
      set_user_column @analysis_template
      @analysis_template.save!

      # delete -> insert items
      delete_analysis_template_item(@analysis_template.id)
      items = get_items(@mode, params)
      items.each do |item|
        item.analysis_template_id = @analysis_template.id
        item.save!
      end
    end # transaction

    flash[:notice] = 'AnalysisTemplate was successfully updated.'

    redirect_to(params[:back_to] || {:action => :show, :id => @analysis_template})
  rescue ActiveRecord::RecordInvalid
    if @mode == "biz_offer"
      @business_column_names = get_column_names("businesses")
      @biz_offer_column_names = get_column_names("biz_offers")
    elsif @mode == "bp_member"
      @human_resource_column_names = get_column_names("human_resources")
      @bp_member_column_names = get_column_names("bp_members")
    end
    @item_value_map = get_item_value_map(get_items(@mode, params))

    render :action => 'edit', :id => @analysis_template.id, :back_to => back_to
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
    target_column_names.each do |target_column_name|
      column_long_name = getLongName(target_table_name, target_column_name)
      column_names << [target_column_name, column_long_name]
    end
    return column_names
  end

  def get_item_value_map(analysis_template_items)
    item_value_map = {}
    
    analysis_template_items.each do |item|
      item_value_map[item.target_table_name + '.' + item.target_column_name] = item
    end
    item_value_map
  end

  def get_items(mode, _params)
    items = if mode == "biz_offer"
        create_analysis_template_item("businesses", _params).concat(
            create_analysis_template_item("biz_offers", _params))
    elsif mode == "bp_member"
        create_analysis_template_item("human_resources", _params).concat(
            create_analysis_template_item("bp_members", _params))
    end
  end
  
  def create_analysis_template_item(target_table_name, _params)
    target_column_names = AnalysisTemplateItem.get_target_column_names(target_table_name)
    
    target_column_names.collect do |target_column_name|

      if !_params["analysis_template_item_#{target_table_name}_#{target_column_name}_pattern"].blank?
        # パターンが入力されてたら保存対象
        analysis_template_item = AnalysisTemplateItem.new #(_params["analysis_template_item_#{target_table_name}_#{target_column_name}"])
        
#        analysis_template_item.analysis_template_id = analysis_template_id
        analysis_template_item.analysis_template_item_name =
            _params["analysis_template_item_#{target_table_name}_#{target_column_name}_analysis_template_item_name"]
        analysis_template_item.pattern =
            _params["analysis_template_item_#{target_table_name}_#{target_column_name}_pattern"]
        analysis_template_item.ignore_flg =
            _params["analysis_template_item_#{target_table_name}_#{target_column_name}_ignore_flg"].blank? ? 0 : 1
        analysis_template_item.target_table_name = target_table_name
        analysis_template_item.target_column_name = target_column_name

        set_user_column analysis_template_item
#        analysis_template_item.save!
        analysis_template_item
      end

    end.compact
  end

  def delete_analysis_template_item(analysis_template_id)
    AnalysisTemplateItem.delete_all(:analysis_template_id => analysis_template_id)
  end
end
