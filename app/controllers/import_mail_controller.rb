# -*- encoding: utf-8 -*-
require 'railroad_util'

class ImportMailController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#  verify :method => :post, :only => [ :destroy, :create, :update ],
#         :redirect_to => { :action => :list }
         
  def set_conditions
    session[:import_mail_search] = {
      :biz_offer_flg => params[:biz_offer_flg],
      :bp_member_flg => params[:bp_member_flg],
      :unwanted => params[:unwanted],
      :registed => params[:registed],
      :tag => params[:tag]
    }
  end

  def combine_tags?(tags)
    tags && tags.split(",").size > 1
  end

  def make_conditions_for_tag(tags)
    joins = []
    sqls = []
    sql_params = []
   tags.split(",").each do |tag|
      sqls << "tag_details.tag_text = ?"
      sql_params << tag.strip.downcase
    end
    if combine_tags?(tags)
      my_sql = "select parent_id, count(parent_id) as cnt from tag_details where (#{sqls.join(' or ')}) group by parent_id having count(parent_id) > ?"
      sql_params << (sqls.size - 1)
      parent_ids = TagDetail.find_by_sql(sql_params.unshift(my_sql)).map{|x| x.parent_id}
      sql = " and import_mails.id in (?)"
      sql_params << parent_ids
      return [" and import_mails.id in (?)", [parent_ids], []]
    else
      return [" and (#{sqls.first})", sql_params, [:tag_details]]
      #こんな感じ
      #ImportMail.joins(:tag_details).where(:id => 240,"tag_details.tag_text" => "java")
    end
  end

  def make_conditions
    sql_params = []
    incl = []
    joins = []
    sql = "import_mails.deleted = 0"
    # TODO デフォルトで不要フラグ立ってないもの？
    order_by = ""

    if params[:id]
      sql += " and business_partner_id = ?"
      sql_params << params[:id]
    end

    if !(self_flg = session[:import_mail_search][:biz_offer_flg]).blank?
      sql += " and biz_offer_flg = 1"
    end

    if !(eu_flg = session[:import_mail_search][:bp_member_flg]).blank?
      sql += " and bp_member_flg = 1"
    end

    if !(upper_flg = session[:import_mail_search][:unwanted]).blank?
      sql += " and unwanted = 1"
    end

    if !(down_flg = session[:import_mail_search][:registed]).blank?
      sql += " and registed = 1"
    end
    

    unless session[:import_mail_search][:tag].blank?
      s, p, j = make_conditions_for_tag(session[:import_mail_search][:tag])
      sql += s
      sql_params += p
      joins += j
    end

    return [sql_params.unshift(sql), incl, joins]
  end

  def list
    session[:import_mail_search] ||= {}
    if request.post?
      if params[:search_button]
        set_conditions
      elsif params[:clear_button]
        session[:import_mail_search] = {}
      end
    end
    cond, incl, joins = make_conditions
    
    @import_mails = ImportMail.includes(incl)
                              .joins(joins)
                              .where(cond)
                              .page(params[:page])
                              .per(current_user.per_page)
                              .order("id desc")
=begin    
    @mail_registered_to = {}
    @import_mails.each do |mail|
      bpm = BpMember.where(:import_mail_id => mail.id).first
      bof = BizOffer.where(:import_mail_id => mail.id).first
      @mail_registered_to[mail.id] = Object.new
      @mail_registered_to[mail.id].define_method(:bp_member, lambda{bpm})
    end
=end    
    
    
  end

  def set_order
    session[:import_mail_order] = {
      :order => params[:order]
      }
  end

  def list_by_from
    session[:import_mail_order] ||= {}
    if request.post?
      set_order
    end
    if !(x = session[:import_mail_order][:order]).blank?
      case x
        when "count"
          order = "count(*) desc"
        when "fifty"
          order = "mail_from"
        when "time"
          order = "max(received_at) desc"
      else
        order = "count(*) desc"
      end
    else
      order = "count(*) desc"
    end
    @import_mail_pages, @import_mails = paginate :import_mails, :select => "*, count(*) count, max(business_partner_id) bizp_id, max(bp_pic_id) bpic_id, max(received_at) recv_at",
                                                                :conditions => "deleted = 0", :group => "mail_from",
                                                                :order => order,
                                                                :per_page => current_user.per_page
  end

  def show
    @import_mail = ImportMail.find(params[:id])
    @biz_offers = BizOffer.find(:all, :conditions => ["deleted = 0 and import_mail_id = ?", params[:id]])
    @bp_members = BpMember.find(:all, :conditions => ["deleted = 0 and import_mail_id = ?", params[:id]])
    @attachment_files = AttachmentFile.find(:all, :conditions => ["deleted = 0 and parent_table_name = 'import_mails' and parent_id = ?", @import_mail.id])
  end

  def new
    @import_mail = ImportMail.new
  end

  def create
    @import_mail = ImportMail.new(params[:import_mail])
    set_user_column @import_mail
    @import_mail.save!
    flash[:notice] = 'ImportMail was successfully created.'
    redirect_to :action => 'list'
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @import_mail = ImportMail.find(params[:id])
  end

  def update
    @import_mail = ImportMail.find(params[:id], :conditions =>["deleted = 0"])
    @import_mail.attributes = params[:import_mail]
    set_user_column @import_mail
    @import_mail.save!
    flash[:notice] = 'ImportMail was successfully updated.'
    redirect_to :action => 'show', :id => @import_mail
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @import_mail = ImportMail.find(params[:id], :conditions =>["deleted = 0"])
    @import_mail.deleted = 9
    @import_mail.deleted_at = Time.now
    set_user_column @import_mail
    @import_mail.save!
    
    redirect_to :action => 'list'
  end
  
  
  # Ajaxでのflg処理
  def change_flg
  puts">>>>>>>>>>>>>>>>>>>> flg changing now !!!"
  puts">>>>>>>>>>>>>>>>>>>> import_mail_id : #{params[:import_mail_id]}"
    target_mail = ImportMail.find(params[:import_mail_id])
  puts">>>>>>>>>>>>>>>>>>>> type : #{params[:type]}"
    if params[:type] == "biz_offer"
      if target_mail.biz_offer_flg == 0
        target_mail.biz_offer_flg = 1
        target_mail.unwanted = 0
      else
        target_mail.biz_offer_flg = 0
      end
    elsif params[:type] == "bp_member"
      if target_mail.bp_member_flg == 0
        target_mail.bp_member_flg = 1
        target_mail.unwanted = 0
      else
        target_mail.bp_member_flg = 0
      end
    elsif params[:type] == "unwanted"
      if target_mail.unwanted == 0
        target_mail.biz_offer_flg = 0
        target_mail.bp_member_flg = 0
        target_mail.unwanted = 1
      else
        target_mail.unwanted = 0
      end
    end
    set_user_column target_mail
    target_mail.save!
    render :json => { biz_offer: target_mail.biz_offer_flg,
                      bp_member: target_mail.bp_member_flg,
                      unwanted: target_mail.unwanted }
    # render :text => target_mail.biz_offer_flg.to_s + ',' + target_mail.bp_member_flg.to_s + ',' + target_mail.unwanted.to_s
  end
  
  def analysis_test
    max = ( params[:max] ? params[:max] : 50 )
    mails = ImportMail.find(:all, :limit => max)
    
    text = "";
    
    mails.each do |mail|
      body = mail.preprocbody
      
      nearest_st = mail.detect_nearest_station
      nearest_st_short = ImportMail.extract_station_name(nearest_st) if nearest_st
      
      text += "#{mail.id} [#{nearest_st}] => #{nearest_st_short.to_s}<br/>"
      
    end
    
    render :text => text
  end
  
end
