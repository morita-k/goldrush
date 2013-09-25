# -*- encoding: utf-8 -*-

class ImportMailController < ApplicationController

  def index
    if list
      render :action => 'list'
    end
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
      :proper_flg => params[:proper_flg],
      :tag => params[:tag],
      :starred => params[:starred],
      :payment_from => params[:payment_from],
      :payment_to => params[:payment_to],
      :age_from => params[:age_from],
      :age_to => params[:age_to],
    }
  end

  def make_conditions_for_tag(tags)
    Tag.make_conditions_for_tag(tags, "import_mails")
  end

  def make_conditions
    sql_params = []
    incl = []
    joins = []
    sql = "import_mails.deleted = 0"

    if params[:id]
      sql += " and business_partner_id = ?"
      sql_params << params[:id]
    end

    if !(session[:import_mail_search][:biz_offer_flg]).blank?
      sql += " and biz_offer_flg = 1"
    end

    if !(session[:import_mail_search][:bp_member_flg]).blank?
      sql += " and bp_member_flg = 1"
    end

    if !(session[:import_mail_search][:unwanted]).blank?
      sql += " and unwanted = 1"
    end

    if !(session[:import_mail_search][:registed]).blank?
      sql += " and registed = 1"
    end
    
    if !(session[:import_mail_search][:proper_flg]).blank?
      sql += " and proper_flg = 1"
    end
    
    unless session[:import_mail_search][:tag].blank?
      pids = make_conditions_for_tag(session[:import_mail_search][:tag])
      unless pids.empty?
        sql += " and import_mails.id in (?) "
        sql_params += [pids]
      end
    end
    
    unless (payment_from = session[:import_mail_search][:payment_from]).blank?
      sql += " and payment_text >= ? "
      sql_params << payment_from
    end

    unless (payment_to = session[:import_mail_search][:payment_to]).blank?
      sql += " and payment_text <= ? "
      sql_params << payment_to
    end

    unless (age_from = session[:import_mail_search][:age_from]).blank?
      sql += " and age_text >= ? "
      sql_params << age_from
    end

    unless (age_to = session[:import_mail_search][:age_to]).blank?
      sql += " and age_text <= ? "
      sql_params << age_to
    end

    if !(session[:import_mail_search][:starred]).blank?
      sql += " and starred > 0"
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
        redirect_to
        return false
      end
    end
    cond, incl, joins = make_conditions

    limit_count = 1000 + params[:page].to_i * current_user.per_page

    @import_mails = ImportMail.includes(incl).joins(joins)
                                             .where(cond)
                                             .order("id desc")
                                             .limit(limit_count)
                                             .page(params[:page])
                                             .per(current_user.per_page)
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
    delta = []
    mails.each do |mail|
      body = mail.preprocbody
      nearest_st = mail.detect_nearest_station
      before = Time.now
      nearest_st_short = ImportMail.extract_station_name_from(nearest_st) if nearest_st
      after = Time.now
      d = ((after - before) * 1000).floor 
      delta.push d
      text += "[ #{sprintf('%05d',d)} ms ] #{mail.id} [#{nearest_st}] => #{nearest_st_short.to_s}<br/>"
      
    end
    avg = delta.inject(0.0){ |avg, num| avg += num.to_f / delta.size }
    text = "平均 #{sprintf('%3d',avg.floor)} ms <br/><br/>" + text
    render :text => text
  end
  
end
