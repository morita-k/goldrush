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
      :nondelivery_score => params[:nondelivery_score],
      :working_status => params[:working_status],
      :jiet => params[:jiet]
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
    
    # 在職者以外
    if !(x = session[:bp_pic_search][:working_status]).blank?
      sql += " and working_status <> ?"
      param << x
    end

    # JIET_FLG
    if !(x = session[:bp_pic_search][:jiet]).blank?
      case x 
      when "1"
        sql += " and jiet = ?"
        param << 0
      when "2"
        sql += " and jiet = ?"
        param << 1
      else
      end
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
    
    # order by
    if (x = session[:bp_pic_search][:working_status]).blank?
      order_by = "bp_pics.updated_at desc"
    else
      #在職者以外を検索した場合は、後任者・転職先が登録されていないものを先頭に
      order_by = "substitute_bp_pic_id, change_to_bp_pic_id"
    end

    return [param.unshift(sql), incl, order_by]
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
    cond, incl, order_by = make_conditions
    
    @bp_pics = BpPic.includes(incl).where(cond).order(order_by).page(params[:page]).per(current_user.per_page)


    if @photo_id = params[:photoid]
      @popup_mode = 1
    end

    if params[:popup] && !(params[:callback].blank? || @photo_id.nil?)
      flash[:warning] = 'ポップアップのパラメータが不正です'
    end

    return true
  end

  def index
    if list
      render :action => 'list'
    end
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
    @delivery_mails = DeliveryMail.where(:deleted => 0 , :id => @bp_pic.delivery_mail_ids).order("id desc").page(params[:page]).per(20)
    @former_bp_pic = params[:former_bp_pic_id] ? BpPic.find(params[:former_bp_pic_id]) : @bp_pic.former_bp_pic
    @photos = Photo.where(:deleted => 0, :parent_id => @bp_pic.id)
  end

  def new
    @bp_pic = BpPic.new
    business_partner = BusinessPartner.find(params[:business_partner_id])
    @bp_pic.business_partner = business_partner
  end

  def create
    ActiveRecord::Base.transaction do 
      @bp_pic = BpPic.new(params[:bp_pic])
      set_user_column @bp_pic
      @bp_pic.save!
      
      BpPic.update_retired(@bp_pic.id, params[:retired_bp_pic_id]) unless params[:retired_bp_pic_id].blank? #退職登録
      BpPic.update_changed(@bp_pic.id, params[:former_bp_pic_id]) unless params[:former_bp_pic_id].blank? #転職登録

      if params[:import_mail_id]
        @import_mail = ImportMail.find(params[:import_mail_id])
        @import_mail.bp_pic_id = @bp_pic.id
        @import_mail.save!
      end
    end #transaction
    flash[:notice] = 'BpPic was successfully created.'
    redirect_to(back_to || {:action => 'list'})
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @bp_pic = BpPic.find(params[:id])
    @former_bp_pic = params[:former_bp_pic_id] ? BpPic.find(params[:former_bp_pic_id]) : @bp_pic.former_bp_pic
  end

  def update
    ActiveRecord::Base.transaction do 
      @bp_pic = BpPic.find(params[:id], :conditions =>["deleted = 0"])
      @bp_pic.attributes = params[:bp_pic]
      @bp_pic.bp_pic_name = params[:bp_pic][:bp_pic_name].gsub(/　/," ")
      set_user_column @bp_pic
      @bp_pic.save!
      BpPic.update_changed(@bp_pic.id, params[:former_bp_pic_id]) unless params[:former_bp_pic_id].blank? #転職登録
    end #transaction
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

  def update_working_status
    @bp_pic = BpPic.find(params[:id])
    @bp_pic.working_status = params[:working_status]
    set_user_column @bp_pic
    @bp_pic.save!
    flash[:notice] = 'BpPic was successfully updated.'
    redirect_to(back_to || {:action => 'show', :id => @bp_pic})
  rescue ActiveRecord::RecordInvalid
    render :action => 'show'
  end

  def destroy
    @bp_pic = BpPic.find(params[:id], :conditions =>["deleted = 0"])
    @bp_pic.deleted = 9
    @bp_pic.deleted_at = Time.now
    set_user_column @bp_pic
    @bp_pic.save!

    # 取引先担当者に紐付くグループ詳細も削除する
    @bp_pic.out_of_group!
    
    redirect_to(back_to || {:action => 'list'})
  end
  
  def proc_bp_pic_ids
    if params[:add_group_button]
      add_bp_pic_into_selected_group
    else params[:contact_mail_new_button]
      redirect_to({:controller => 'delivery_mails', :action => 'contact_mail_new',:bp_pic_ids => params[:ids]})
    end 
  end

  def add_bp_pic_into_selected_group
    selected_group = []
    addGroup = {:groupIds => []}.merge(params[:addGroup] || {})
    p addGroup
    @addGroups = OpenStruct.new(addGroup)
    @addGroups.groupIds.delete("-1")
    @addGroups.groupIds.each do |groupId|
      selected_group.push(BpPicGroup.find(groupId))
    end

    bp_pic_id_list = params[:ids]
    
    if bp_pic_id_list && !selected_group.nil?

      selected_group.each do |groupId|
        bp_pic_id_list.each do |id|
          target = BpPic.find(id)
          target.into_group(groupId.id)
        end
      end

      respond_to do |format|
        flash[:notice] = "#{bp_pic_id_list.length}人の取引先担当者が"
        selected_group.each do |groupId|
          group_str = groupId.bp_pic_group_name =~ /グループ$/ ? "" : "グループ"
          flash[:notice] += "「#{groupId.bp_pic_group_name}」#{group_str} "
        end
        flash[:notice] += "に追加されました。"
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

  # 入力支援機能に表示する取引先データを生成する
  def quick_input
    params[:business_partner_id] ||= get_current_uniquely_bp_ids.first
    params[:page] ||= "1"

    # idがnilだった場合、@business_partnerをnilにしたいのでwhere
    @business_partner ||= BusinessPartner.where(id: params[:business_partner_id]).first

    render template: 'business_partner/quick_input', layout: 'blank'
  end
  
  # 入力支援機能の次の取引先IDを生成し、再読み込みさせる
  def next_bp
    current_bp_id = params[:business_partner_id].to_i
    page = params[:page].to_i
    current_page_bp_ids = get_current_uniquely_bp_ids
    index = current_page_bp_ids.index(current_bp_id)

    if current_bp_id.nil?
      # 支援機能起動時の処理
      next_bp_id = current_page_bp_ids.first
    else
      # 次の取引先が存在したらその取引先を、いなければ次のページの最初の取引先を返す
      if !index.nil? && next_bp = current_page_bp_ids[index.succ]
        next_bp_id = next_bp
      else
        page += 1
        next_bp_id = nil
      end
    end

    redirect_to action: 'quick_input', popup: params[:popup], page: page, back_to: params[:back_to], business_partner_id: next_bp_id, only_path: false, protocol: "http://"
  end

  # 混在コンテンツによるブロック回避の為、Formのみiframeで呼ぶ
  def quick_input_form
    @business_partner = BusinessPartner.find(params[:business_partner_id])
    render template: 'business_partner/quick_input_form', layout: 'blank'
  end

  def update_photo
    Photo.update_bp_pic(params[:id], params[:photo_id])

    flash_notice = 'Photo was successfully updated.'

    flash.now[:notice] = flash_notice
    redirect_to :controller => :photos, :action => :list
  end

  def update_photo_unlink
    Photo.update_bp_pic_unlink(params[:photo_id])

    flash_notice = 'Photo was successfully updated.'

    flash.now[:notice] = flash_notice

    redirect_to :back
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

  def get_current_uniquely_bp_ids
    session[:bp_pic_search] ||= {}
    incl = []
    if params[:search_button]
      set_conditions
    elsif params[:clear_button]
      session[:bp_pic_search] = {}
    end

    # 検索条件を処理
    cond, incl, order_by = make_conditions
    bp_pics = BpPic.includes(incl).where(cond).order(order_by).page(params[:page]).per(current_user.per_page)
    
    bp_pics.map(&:business_partner).map(&:id).uniq
  end

end
