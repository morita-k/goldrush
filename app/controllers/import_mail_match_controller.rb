# -*- encoding: utf-8 -*-

class ImportMailMatchController < ApplicationController

  def index
    unless init_session(:import_mail_auto_match)
      return false
    end

    cond, incl, joins = make_conditions(session[:import_mail_auto_match])

    @import_mail_matches = find_login_owner(:import_mail_matches)
                              .includes(incl)
                              .joins(joins)
                              .where(cond)
                              .order("import_mail_matches.received_at desc")
                              .page(params[:page])
                              .per(current_user.per_page)
  end

  def detail
    @import_mail_match = ImportMailMatch.find(params[:id])
    render :layout => false, :partial => 'detail'
  end

  def thread_detail
    case params[:mail_type]
    when 'import_mail'   then @import_mail   = ImportMail.find(params[:mail_id])
    when 'delivery_mail' then @delivery_mail = DeliveryMail.find(params[:mail_id])
    end
    render :layout => false, :partial => 'thread_detail'
  end

  def show
    @import_mail_match = ImportMailMatch.find(params[:id], :conditions => "deleted = 0 ")
    @attachment_files  = AttachmentFile.get_attachment_files('import_mails', @import_mail_match.bp_member_mail_id)
    @remarks = Remark.get_all('import_mail_match', params[:id])

    related_import_mails = ImportMail.where("import_mail_match_id = ? and created_at > ?", params[:id], @import_mail_match.created_at)
    related_delivery_mails = DeliveryMail.where("import_mail_match_id = ? and created_at > ?", params[:id], @import_mail_match.created_at)

    related_import_mails_data = related_import_mails.map do |import_mail|
                                  {
                                    id:                import_mail.id,
                                    mail_type:         'import_mail',
                                    subject:           import_mail.mail_subject,
                                    disp_time:         import_mail.received_at,
                                    sender_name:       import_mail.mail_sender_name,
                                    bp_pic_id:         import_mail.bp_pic_id,
                                    matching_way_type: import_mail.matching_way_type
                                  }
                                end

    related_delivery_mails_data = related_delivery_mails.map do |delivery_mail|
                                    {
                                      id:                delivery_mail.id,
                                      mail_type:         'delivery_mail',
                                      subject:           delivery_mail.subject,
                                      disp_time:         delivery_mail.send_end_at || delivery_mail.planned_setting_at,
                                      sender_name:       delivery_mail.mail_from_name,
                                      matching_way_type: delivery_mail.matching_way_type
                                    }
                                  end

    @related_mails_data = (related_import_mails_data + related_delivery_mails_data).sort_by{ |mail_data| mail_data[:disp_time] }
  rescue => e
    p ">>>>>>>>>>>>> [import_mail_match] error : #{e}"
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
    redirect_to(back_to || {:action => 'index'})
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

  def change_status
    import_mail_match = ImportMailMatch.find(params[:id])
    import_mail_match.imm_status_type = params[:next_status]
    set_user_column import_mail_match
    import_mail_match.save!
    redirect_to :action => :show
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
      :title_match => params[:title_match],
      :imm_status_type_set => params[:imm_status_type_set],
      :tag => params[:tag],
      :payment_from => params[:payment_from],
      :payment_to => params[:payment_to],
      :payment_gap_from => params[:payment_gap_from],
      :payment_gap_to => params[:payment_gap_to],
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
      sql += " and (import_mail_matches.starred = 1 or import_mail_matches.starred = 2)"
    end

    if !(cond_param[:title_match]).blank?
      sql += " and (import_mail_matches.subject_tag_match_flg = 2)"
    end

    if !(cond_param[:imm_status_type_set]).blank?
      imm_status_type_list = case cond_param[:imm_status_type_set]
                             when 'all'      then []
                             when 'open'     then ['open']
                             when 'progress' then ['candidate', 'down_approach', 'upper_approach', 'interview']
                             when 'closed'   then ['self_reject', 'down_reject', 'upper_reject', 'interview_reject', 'contract']
                             when 'contract' then ['contract']
                             else                 []
                             end
      status_sql = imm_status_type_list.map do |imm_status_type|
                     "import_mail_matches.imm_status_type = '#{imm_status_type}'"
                   end.join(' or ')
      sql += " and (#{status_sql})" if status_sql.present?
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

    unless (payment_gap_from = cond_param[:payment_gap_from]).blank?
      sql += " and import_mail_matches.payment_gap >= ? "
      sql_params << payment_gap_from
    end

    unless (payment_gap_to = cond_param[:payment_gap_to]).blank?
      sql += " and import_mail_matches.payment_gap <= ? "
      sql_params << payment_gap_to
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
