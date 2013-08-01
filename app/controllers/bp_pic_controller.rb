# -*- encoding: utf-8 -*-
class BpPicController < ApplicationController

  def set_conditions
    session[:bp_pic_search] = {
      :sales_code => params[:sales_code],
      :business_partner_name => params[:business_partner_name],
      :bp_pic_name => params[:bp_pic_name],
      :tel => params[:tel],
      :email => params[:email],
      :bp_pic_group_id => params[:bp_pic_group_id],
      :nondelivery_score => params[:nondelivery_score]
    }
  end

  def make_conditions
    param = []
    incl = [:business_partner]
    sql = "business_partners.deleted = 0 and bp_pics.deleted = 0"
    order_by = ""
    
    if !(x = session[:bp_pic_search][:sales_code]).blank?
      sql += " and (business_partner_code = ? or sales_code = ?)"
      param << x << x
    end
    
    if !(x = session[:bp_pic_search][:business_partner_name]).blank?
      sql += " and (business_partner_name like ? or business_partner_name_kana like ?)"
      param << "%#{x}%" << "%#{x}%"
    end
    
    if !(x = session[:bp_pic_search][:bp_pic_name]).blank?
      sql += " and (bp_pic_name like ? or bp_pic_name_kana like ? or bp_pic_short_name like ?)"
      param << "%#{x}%" << "%#{x}%" << "%#{x}%"
    end
    
    if !(x = session[:bp_pic_search][:tel]).blank?
      x = x.gsub("-","")
      sql += " and (tel_direct like ? or tel_mobile like ?)"
      param << "%#{x}%" << "%#{x}%"
    end
    
    if !(x = session[:bp_pic_search][:email]).blank?
      sql += " and (email1 like ? or email2 like ?)"
      param << "%#{x}%" << "%#{x}%"
    end
    
    # 不達スコア
    if !(x = session[:bp_pic_search][:nondelivery_score]).blank?
      sql += " and nondelivery_score >= ?"
      param << x
    end
    
    # 取引先グループ
    if !(x = session[:bp_pic_search][:bp_pic_group_id]).blank?
      incl << :bp_pic_group_detail
      sql += " and bp_pic_group_details.deleted = 0"
      
      if x != 'all'
        sql += " and bp_pic_group_details.bp_pic_group_id = ?"
        param << x
      end
    end
    
    if params[:id]
      sql += " and business_partner_id = ?"
      param << params[:id]
      @business_partner = BusinessPartner.find(params[:id])
    end
    
    return [param.unshift(sql), incl]
  end

  def list
    session[:bp_pic_search] ||= {}
    incl = []
    if params[:search_button]
      set_conditions
    elsif params[:clear_button]
      session[:bp_pic_search] = {}
    end

    # 検索条件を処理
    cond, incl = make_conditions
    
    @bp_pics = BpPic.includes(incl).where(cond).order("bp_pics.updated_at desc").page(params[:page]).per(current_user.per_page)
    
    if params[:popup] && params[:callback].blank?
      flash[:warning] = 'ポップアップのパラメータが不正です'
    end
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

#  def list
#    if params[:id].blank?
#      condition = ["deleted = 0"]
#    else
#      condition = ["deleted = 0 and business_partner_id = ?", params[:id]]
#      @business_partner = BusinessPartner.find(params[:id])
#    end
#    @bp_pic_pages, @bp_pics = paginate :bp_pics, :conditions => condition, :per_page => current_user.per_page
#  end

  def show
    @bp_pic = BpPic.find(params[:id])
    @remarks = Remark.find(:all, :conditions => ["deleted = 0 and remark_key = ? and remark_target_id = ?", 'bp_pics', params[:id]])
  end

  def new
    @bp_pic = BpPic.new
    business_partner = BusinessPartner.find(params[:business_partner_id])
    @bp_pic.business_partner = business_partner
    
  end

  def create
    @bp_pic = BpPic.new(params[:bp_pic])
    set_user_column @bp_pic
    @bp_pic.save!
    
    if params[:import_mail_id]
      ActiveRecord::Base.transaction do 
        @import_mail = ImportMail.find(params[:import_mail_id])
        @import_mail.bp_pic_id = @bp_pic.id
        @import_mail.save!
      end
    end
    
    flash[:notice] = 'BpPic was successfully created.'
    redirect_to(back_to || {:action => 'list'})
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @bp_pic = BpPic.find(params[:id])
  end

  def update
    @bp_pic = BpPic.find(params[:id], :conditions =>["deleted = 0"])
    @bp_pic.attributes = params[:bp_pic]
    @bp_pic.bp_pic_name = params[:bp_pic][:bp_pic_name].gsub(/　/," ")
    set_user_column @bp_pic
    @bp_pic.save!
    flash[:notice] = 'BpPic was successfully updated.'
    redirect_to(back_to || {:action => 'show', :id => @bp_pic})
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end
  
  def change_star
    bp_pic = BpPic.find(params[:id])
    if bp_pic.starred == 1
      bp_pic.starred = 0
    else
      bp_pic.starred = 1
    end
      set_user_column bp_pic
      bp_pic.save!
    render :text => bp_pic.starred
  end

  def destroy
    @bp_pic = BpPic.find(params[:id], :conditions =>["deleted = 0"])
    @bp_pic.deleted = 9
    @bp_pic.deleted_at = Time.now
    set_user_column @bp_pic
    @bp_pic.save!
    
    redirect_to(back_to || {:action => 'list'})
  end
  
  def add_bp_pic_into_selected_group
    selected_group = BpPicGroup.find(params[:group_id])
    bp_pic_id_list = params[:ids]
    
    if bp_pic_id_list && !selected_group.nil?
      
      bp_pic_id_list.each do |id|
        target = BpPic.find(id)
        target.into_group(selected_group.id)
      end
      
      group_str = selected_group.bp_pic_group_name =~ /グループ$/ ? "" : "グループ"
      respond_to do |format|
        flash[:notice] = "#{bp_pic_id_list.length}人の取引先担当者が「#{selected_group.bp_pic_group_name}」#{group_str}に追加されました。"
        format.html {redirect_to back_to}
      end
    elsif selected_group.nil?
      # グループが選択されていなければエラー
      # View側でチェックしてるので、現状到達不可処理
      respond_to do |format|
        flash[:warning] = '追加先グループが選択されていません。'        
        format.html {redirect_to back_to}
      end
    else
      # IDのリストが取得できなければエラー
      # View側でチェックしてるので、現状到達不可処理
      respond_to do |format|
        flash[:warning] = '取引先担当者が選択されていません。'
        format.html {redirect_to back_to}
      end
    end
  end
  
private
  def valid_of_business_partner_id
    if params[:business_partner_id].blank?
      raise ValidationAbort.new("Invalid paramater.[business_partner_id is not null]")
    end
  end
  
  def space_trim(bp_name)
    bp_name_list = bp_name.split(/[\s"　"]/)
    trimed_bp_name = ""
    bp_name_list.each do |bp_name_element|
      trimed_bp_name << bp_name_element
    end
    trimed_bp_name
  end

end
