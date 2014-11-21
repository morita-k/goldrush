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

  def list
    unless init_session(:import_mail_search)
      return false
    end
    cond, incl, joins, orderby = make_conditions(session[:import_mail_search])

    @import_mails = find_login_owner(:import_mails)
                        .includes(incl)
                        .joins(joins)
                        .where(cond)
                        .order(orderby)
                        .page(params[:page])
                        .per(current_user.per_page)
  end

  def matching
    unless init_session(:import_mail_match)
      return false
    end

    param = session[:import_mail_match].dup
    param.delete(:bp_member_flg)
    param.delete(:proper_flg)
    param[:biz_offer_flg] = 1
    cond, incl, joins = make_conditions(param)
    @biz_mails = find_login_owner(:import_mails)
                      .includes(incl)
                      .joins(joins)
                      .where(cond)
                      .order("payment desc")
                      .page(params[:page])
                      .per(current_user.per_page)
    param = session[:import_mail_match].dup
    param.delete(:biz_offer_flg)
    param[:bp_member_flg] = 1
    cond, incl, joins = make_conditions(param)
    @hr_mails = find_login_owner(:import_mails)
                    .includes(incl)
                    .joins(joins)
                    .where(cond)
                    .order("payment")
                    .page(params[:page])
                    .per(current_user.per_page)
  end

  def set_order
    session[:import_mail_order] = {
      :order => params[:order]
      }
  end

  def show
    @import_mail = ImportMail.find(params[:id])
    @biz_offers = find_login_owner(:biz_offers).where(["deleted = 0 and import_mail_id = ?", params[:id]])
    @bp_members = find_login_owner(:bp_members).where(["deleted = 0 and import_mail_id = ?", params[:id]])
    @attachment_files = AttachmentFile.get_attachment_files('import_mails', @import_mail.id)
  end

  def detail
    @colspan=params[:colspan] || 4
    @import_mail = ImportMail.find(params[:id])
    render :layout => false
  end

  def new
    @import_mail = ImportMail.new
  end

  def create
    @import_mail = create_model(:import_mails, params[:import_mail])
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
    target_mail = ImportMail.find(params[:import_mail_id])
    if params[:type] == "biz_offer"
      if target_mail.biz_offer_mail?
        target_mail.biz_offer_flg = 0
      else
        target_mail.biz_offer_flg = 1
        target_mail.unwanted = 0
      end
    elsif params[:type] == "bp_member"
      if target_mail.bp_member_mail?
        target_mail.bp_member_flg = 0
      else
        target_mail.bp_member_flg = 1
        target_mail.unwanted = 0
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

  def change_plural
    im = ImportMail.find(params[:id])
    im.plural_flg = params[:flg].to_i
    set_user_column im
    im.save!

    render :text => "OK", :layout => false

  end

  def analysis_test
    max = ( params[:max] ? params[:max] : 50 )
    mails = find_login_owner(:import_mails).limit(max)

    text = "";
    delta = []
    mails.each do |mail|
      nearest_st = mail.detect_nearest_station
      before = Time.now
      nearest_st_short = ImportMail.extract_station_name_from(nearest_st) if nearest_st
      after = Time.now
      d = ((after - before) * 1000).floor
      delta.push d
      text += "[ #{sprintf('%05d',d)} ms ] #{mail.id} [#{nearest_st}] => #{nearest_st_short.to_s}<br/>"

    end
    avg = delta.inject(0.0){ |sum, num| sum += num.to_f / delta.size }
    text = "平均 #{sprintf('%3d',avg.floor)} ms <br/><br/>" + text
    render :text => text
  end

private

  def order_conditions(ord)
    {
      "payment" => "payment, id desc",
      "payment desc" => "payment desc, id desc",
      "age" => "age, id desc",
      "age desc" => "age desc, id desc",
      "id" => "id desc",
    }[ord] || "id desc"
  end

  def set_conditions
    {
      :biz_offer_flg => params[:biz_offer_flg],
      :bp_member_flg => params[:bp_member_flg],
      :unwanted => params[:unwanted],
      :registed => params[:registed],
      :proper_flg => params[:proper_flg],
      :tag => params[:tag],
      :starred => params[:starred],
      :outflow_mail_flg => params[:outflow_mail_flg],
      :interview_count_one => params[:interview_count_one],
      :payment_from => params[:payment_from],
      :payment_to => params[:payment_to],
      :age_from => params[:age_from],
      :age_to => params[:age_to],
      :free_word => params[:free_word],
      :foreign_type => params[:foreign_type],
      :sex_type => params[:sex_type],
      :days => params[:days],
      :order_by => params[:order_by],
    }
  end

  def make_conditions_for_tag(tags, min_id)
    Tag.make_conditions_for_tag(current_user.owner_id, tags, "import_mails", min_id)
  end

  def make_conditions(cond_param, incl = [])
    sql_params = []
    joins = []
    sql = "import_mails.deleted = 0"

    if (days = cond_param[:days].to_i) > 0
      date_now = Time.now + 1.day
      date_before = Time.now - days.day
      sql += " and (received_at BETWEEN ? AND ?)"
      sql_params << date_before << date_now
    end

    if params[:id]
      sql += " and business_partner_id = ?"
      sql_params << params[:id]
    end

    if !(cond_param[:biz_offer_flg]).blank?
      sql += " and biz_offer_flg = 1"
    end

    if !(cond_param[:bp_member_flg]).blank?
      sql += " and bp_member_flg = 1"
    end

    if !(cond_param[:unwanted]).blank?
      sql += " and unwanted = 1"
    end

    if !(cond_param[:registed]).blank?
      sql += " and registed = 1"
    end

    if !(cond_param[:proper_flg]).blank?
      sql += " and proper_flg = 1"
    end

    unless cond_param[:interview_count_one].blank?
      sql += " and interview_count = 1 "
    end

    unless cond_param[:tag].blank?
      last_import_mail = ImportMail.where("received_at > ?", date_before).order("received_at").first
      pids = make_conditions_for_tag(cond_param[:tag], last_import_mail)
      unless pids.empty?
        sql += " and import_mails.id in (?) "
        sql_params += [pids]
      end
    end

    unless cond_param[:starred].blank?
      sql += " and (starred = 1 or starred = 2)"
    end

    unless cond_param[:outflow_mail_flg].blank?
      sql += " and outflow_mail_flg = 1"
    end

    unless (payment_from = cond_param[:payment_from]).blank?
      sql += " and payment >= ? "
      sql_params << payment_from
    end

    unless (payment_to = cond_param[:payment_to]).blank?
      sql += " and payment <= ? "
      sql_params << payment_to
    end

    unless (age_from = cond_param[:age_from]).blank?
      sql += " and age >= ? "
      sql_params << age_from
    end

    unless (age_to = cond_param[:age_to]).blank?
      sql += " and age <= ? "
      sql_params << age_to
    end

    unless (free_word = cond_param[:free_word]).blank?
      free_word.split.each do |word|
        sql += " and (concat(mail_subject, '-', mail_body) like ?) "
        sql_params << '%' + word + '%'
      end
    end

    unless cond_param[:foreign_type].blank?
      if cond_param[:foreign_type] == "internal"
        sql += " and case "
        sql += " when biz_offer_flg = 1 then foreign_type = 'internal' "
        sql += " when bp_member_flg = 1 then foreign_type in ('unknown', 'internal') "
        sql += " end "
      elsif cond_param[:foreign_type] == "foreign"
        sql += " and foreign_type = 'foreign' "
      end
    end

    unless cond_param[:sex_type].blank?
      sql += " and sex_type = '#{cond_param[:sex_type]}' "
    end

    orderby = order_conditions(cond_param[:order_by])

    return [sql_params.unshift(sql), incl, joins, orderby]
  end

  def init_session(key)
    session[key] ||= {:days => 5}
    if request.post?
      if params[:search_button]
        session[key] = set_conditions
      elsif params[:clear_button]
        session.delete(key)
        redirect_to
        return false
      end
    end
    return true
  end

end
