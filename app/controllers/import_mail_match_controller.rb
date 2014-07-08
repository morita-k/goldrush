# -*- encoding: utf-8 -*-

class ImportMailMatchController < ApplicationController

  def index
    unless init_session(:import_mail_auto_match)
      return false
    end

    cond, incl, joins = make_conditions(session[:import_mail_auto_match])

    @import_mail_matches = ImportMailMatch.includes(incl).joins(joins).where(cond).order("import_mail_matches.received_at desc").page(params[:page]).per(current_user.per_page)
  end

  def detail
    @import_mail_match = ImportMailMatch.find(params[:id])
    render :layout => false, :partial => 'detail'
  end

  def show
    @import_mail_match = ImportMailMatch.find(params[:id], :conditions => "deleted = 0 ")
  rescue
    flash[:err] = "対象のマッチングデータが見つかりません。削除された可能性があります。"
    redirect_to params[:back_to]
  end

  def destroy
    import_mail_match = ImportMailMatch.find(params[:id])
    destroy_in(import_mail_match)

    #_redirect_or_back_to :action => :index
    render :text => <<EOS
(function(){
  $('#tr_head_#{params[:id]}').css("display", "none");
  $('#tr_head2_#{params[:id]}').css("display", "none");
  $('#tr_detail_#{params[:id]}').css("display", "none");
})();
EOS
  end

  def destroy_by_show
    import_mail_match = ImportMailMatch.find(params[:id])
    destroy_in(import_mail_match)

    flash[:err] = "マッチングデータを削除しました。"
    redirect_to(back_to || {:action => 'list'})
  end

  def destroy_mail
    target_id = params[:id].to_i
    ActiveRecord::Base.transaction do
      ImportMailMatch.where("biz_offer_mail_id = ? or bp_member_mail_id = ?", target_id, target_id).each do |x|
        destroy_in(x)
      end
    end
    _redirect_or_back_to :action => :index
  end

private

  def destroy_in(imm)
    imm.deleted = 9
    imm.deleted_at = Time.now
    set_user_column imm
    imm.save!
  end

  def set_conditions
    {
      :proper_flg => params[:proper_flg],
      :starred => params[:starred],
      :tag => params[:tag],
      :payment_from => params[:payment_from],
      :payment_to => params[:payment_to],
      :age_from => params[:age_from],
      :age_to => params[:age_to],
      :free_word => params[:free_word],
      :score_from => params[:score_from],
      :days => params[:days],
    }
  end

  def make_conditions(cond_param)
    biz_alias = 'import_mails'
    bpm_alias = 'bp_member_mails_import_mail_matches'
    sql_params = []
    incl = [:biz_offer_mail, :bp_member_mail]
    joins = []
    sql = "import_mail_matches.deleted = 0 and #{biz_alias}.deleted = 0 and #{bpm_alias}.deleted = 0"

    if (days = cond_param[:days].to_i) > 0
      date_now = Time.now + 1.day
      date_before = Time.now - days.day
      sql += " and (import_mail_matches.received_at BETWEEN ? AND ?)"
      sql_params << date_before << date_now
    end

    if !(cond_param[:proper_flg]).blank?
      sql += " and #{bpm_alias}.proper_flg = 1"
    end

    if !(cond_param[:starred]).blank?
      sql += " and import_mail_matches.starred = 1"
    end

    unless (tag = cond_param[:tag]).blank?
      tag.split(",").each do |t|
        sql += " and import_mail_matches.tag_text like ?"
        sql_params << "%#{t}%"
      end
    end

    unless (payment_from = cond_param[:payment_from]).blank?
      sql += " and #{biz_alias}.payment >= ? "
      sql += " and #{bpm_alias}.payment >= ? "
      sql_params << payment_from
      sql_params << payment_from
    end

    unless (payment_to = cond_param[:payment_to]).blank?
      sql += " and #{biz_alias}.payment <= ? "
      sql += " and #{bpm_alias}.payment <= ? "
      sql_params << payment_to
      sql_params << payment_to
    end

    unless (age_from = cond_param[:age_from]).blank?
      sql += " and #{biz_alias}.age >= ? "
      sql += " and #{bpm_alias}.age >= ? "
      sql_params << age_from
      sql_params << age_from
    end

    unless (age_to = cond_param[:age_to]).blank?
      sql += " and #{biz_alias}.age <= ? "
      sql += " and #{bpm_alias}.age <= ? "
      sql_params << age_to
      sql_params << age_to
    end

    unless (free_word = cond_param[:free_word]).blank?
      free_word.split.each do |word|
        sql += " and (concat(#{biz_alias}.mail_subject, '-', #{biz_alias}.mail_body) like ?) "
        sql += " and (concat(#{bpm_alias}.mail_subject, '-', #{bpm_alias}.mail_body) like ?) "
        sql_params << '%' + word + '%'
        sql_params << '%' + word + '%'
      end
    end

    unless (score_from = cond_param[:score_from]).blank?
      sql += " and mail_match_score >= ? "
      sql_params << score_from
    end

    return [sql_params.unshift(sql), incl, joins]
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
