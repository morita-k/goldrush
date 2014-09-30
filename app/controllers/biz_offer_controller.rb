# -*- encoding: utf-8 -*-
class BizOfferController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

   def set_conditions
    session[:biz_offer_search] = {
      :business_partner_name => params[:business_partner_name],
      :bp_pic_name => params[:bp_pic_name],
      :skill_tag => params[:skill_tag],
      :payment_from => params[:payment_from],
      :payment_to => params[:payment_to],
      :business_status_type => params[:business_status_type],
      :biz_offer_status_type => params[:biz_offer_status_type],
      :jiet => params[:jiet]
      }
  end

  def make_conditions
    param = []
    include = [:business, :business_partner, :bp_pic]

    sql = "biz_offers.deleted = 0"
    order_by = "biz_offers.updated_at desc"
    bp_condition = " and (biz_offers.business_partner_id = business_partners.id) and (business_id = businesses.id)"

    if !(business_partner_name = session[:biz_offer_search][:business_partner_name]).blank?
      sql += (bp_condition + " and (business_partner_name like ? or business_partner_name_kana like ?)")
      param << "%#{business_partner_name}%" << "%#{business_partner_name}%"
    end

    if !(bp_pic_name = session[:biz_offer_search][:bp_pic_name]).blank?
      sql += (bp_condition + " and (bp_pic_name like ? or bp_pic_name_kana like ?)")
      param << "%#{bp_pic_name}%" << "%#{bp_pic_name}%"
    end

    unless session[:biz_offer_search][:skill_tag].blank?
      pids = Tag.make_conditions_for_tag(current_user.owner_id, session[:biz_offer_search][:skill_tag], "businesses")
      unless pids.empty?
        sql += " and businesses.id in (?) "
        param << pids
     end
    end

    if !(payment_from = session[:biz_offer_search][:payment_from]).blank?
      sql += " and payment_max >= ?"
      param << (payment_from.to_i * 10000)
    end

    if !(payment_to = session[:biz_offer_search][:payment_to]).blank?
      sql += " and payment_max <= ?"
      param << (payment_to.to_i * 10000)
    end

    if !(business_status_type = session[:biz_offer_search][:business_status_type]).blank?
      sql += " and businesses.business_status_type = ?"
      param << business_status_type
    end

    if !(biz_offer_status_type = session[:biz_offer_search][:biz_offer_status_type]).blank?
      sql += " and biz_offer_status_type = ?"
      param << biz_offer_status_type
    end

    # JIET_FLG
    if !(x = session[:biz_offer_search][:jiet]).blank?
      case x
      when "1"
        sql += " and bp_pics.jiet = ?"
        param << 0
      when "2"
        sql += " and bp_pics.jiet = ?"
        param << 1
      else
      end
    end

    return {:conditions => param.unshift(sql), :include => include, :order => order_by, :per => current_user.per_page}
  end

  def list
    session[:biz_offer_search] ||= {}
    if request.post?
      if params[:search_button]
        set_conditions
      elsif params[:clear_button]
        session[:biz_offer_search] = {}
      end
    end

    conditions = make_conditions
    @biz_offer_pages, @biz_offers = paginate :biz_offers, conditions
  end

  def show
    @biz_offer = BizOffer.find(params[:id])
    @business = @biz_offer.business
    @approach_pages, @approaches = paginate :approaches, :conditions =>["deleted = 0 and biz_offer_id = ?", @biz_offer.id], :per => current_user.per_page
    @remarks = Remark.get_all('business', @business.id)
  end

  def new
    @calendar = true
    now = Time.now

    @biz_offer = BizOffer.new
    @biz_offer.biz_offered_at = Date.parse(now.strftime("%Y/%m/%d"))
    @biz_offered_at_hour = now.hour
    @biz_offered_at_min = (now.min / 10) * 10

    if params[:business_id]
      # 照会を案件に追加する場合（案件は存在している）
      @business = Business.find(params[:business_id])
      @issue_datetime_hour = @business.issue_datetime.hour
      @issue_datetime_min = (@business.issue_datetime.min / 10) * 10
    else
      @business = Business.new
      @business.issue_datetime = Date.parse(now.strftime("%Y/%m/%d"))
      @issue_datetime_hour = now.hour
      @issue_datetime_min = (now.min / 10) * 10
    end
    params[:business_id] = @business.id

    # メール取り込みからの遷移
    if params[:import_mail_id]# && params[:template_id]
      import_mail = ImportMail.find(params[:import_mail_id])
      @biz_offer.import_mail = import_mail
      @biz_offer.business_partner_id = import_mail.business_partner_id
      @biz_offer.bp_pic_id = import_mail.bp_pic_id

      if !params[:template_id].blank?
        if params[:from].blank? || params[:end].blank?
          AnalysisTemplate.analyze(current_user.owner_id, params[:template_id], import_mail, [@biz_offer, @business])
        else
          AnalysisTemplate.analyze_content(
            current_user.owner_id,
            params[:template_id],
            import_mail.mail_body[params[:from].to_i .. params[:end].to_i],
            [@biz_offer, @business]
          )
        end
        @biz_offer.convert!
      end
    end
  end

  def create
    @calendar = true
    @biz_offer = create_model(:biz_offers, params[:biz_offer])
    if @biz_offer.business_id.blank?
      new_flg = true
    end
    ActiveRecord::Base.transaction do
      unless @business = @biz_offer.business
        @business = create_model(:businesses)
      end
      @business.attributes = params[:business]

      if date = DateTimeUtil.str_to_date(params[:business][:issue_datetime])
        @business.issue_datetime = Time.local(date.year, date.month, date.day, params[:issue_datetime_hour].to_i, params[:issue_datetime_minute].to_i)
      end

      @business.business_status_type = 'offered'
      set_user_column @business
      @business.save!
      @biz_offer.business = @business

      @business.make_skill_tags!
      @business.save!

      if date = DateTimeUtil.str_to_date(params[:biz_offer][:biz_offered_at])
        @biz_offer.biz_offered_at = Time.local(date.year, date.month, date.day, params[:biz_offered_at_hour].to_i, params[:biz_offered_at_minute].to_i)
      end

      @biz_offer.biz_offer_status_type = 'open'
      set_user_column @biz_offer
      @biz_offer.save!

      if !@biz_offer.import_mail_id.blank?
        import_mail = ImportMail.find(@biz_offer.import_mail_id)
        import_mail.registed = 1
        import_mail.biz_offer_flg = 1
        set_user_column import_mail
        import_mail.save!
      end
    end

    flash_notice = 'BizOffer was successfully created.'

    if popup?
      # ポップアップウィンドウの場合、ポップアップ状態のまま通常の画面遷移
      flash[:notice] = flash_notice
      redirect_to back_to || {:action => 'list', :popup => 1}
    else
      # ポップアップウィンドウでなければ通常の画面遷移
      flash[:notice] = flash_notice
      if new_flg
        redirect_to back_to || {:action => 'list'}
      else
        redirect_to :action => 'show', :id => @biz_offer
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @calendar = true

    @biz_offer = BizOffer.find(params[:id])
    @biz_offer.biz_offered_at = Date.parse(@biz_offer.biz_offered_at.strftime("%Y/%m/%d"))
    @biz_offered_at_hour = @biz_offer.biz_offered_at.hour
    @biz_offered_at_min = (@biz_offer.biz_offered_at.min / 10) * 10

    @business = @biz_offer.business
    @business.issue_datetime = Date.parse(@business.issue_datetime.strftime("%Y/%m/%d"))
    @issue_datetime_hour = @business.issue_datetime.hour
    @issue_datetime_min = (@business.issue_datetime.min / 10) * 10

    # メール取り込みからの遷移
    if params[:import_mail_id] && params[:template_id]
      import_mail = ImportMail.find(params[:import_mail_id])
      AnalysisTemplate.analyze(current_user.owner_id, params[:template_id], import_mail, [@biz_offer, @business])
    end
  end

  def update
    @calendar = true
    ActiveRecord::Base.transaction do
      @business = Business.find(params[:business_id], :conditions =>["deleted = 0"])
      @biz_offer = BizOffer.find(params[:id], :conditions =>["deleted = 0"])
      @business.attributes = params[:business]

      if date = DateTimeUtil.str_to_date(params[:business][:issue_datetime])
        @business.issue_datetime = Time.local(date.year, date.month, date.day, params[:issue_datetime_hour].to_i, params[:issue_datetime_minute].to_i)
      end

      @business.make_skill_tags!
      set_user_column @business
      @business.save!

      @biz_offer.attributes = params[:biz_offer]

      if date = DateTimeUtil.str_to_date(params[:biz_offer][:biz_offered_at])
        @biz_offer.biz_offered_at = Time.local(date.year, date.month, date.day, params[:biz_offered_at_hour].to_i, params[:biz_offered_at_minute].to_i)
      end

      set_user_column @biz_offer
      @biz_offer.save!
    end
    flash[:notice] = 'BizOffer was successfully updated.'
    redirect_to(back_to || {:action => 'show', :id => @biz_offer})
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @biz_offer = BizOffer.find(params[:id], :conditions =>["deleted = 0"])
    @biz_offer.deleted = 9
    @biz_offer.deleted_at = Time.now
    set_user_column @biz_offer
    @biz_offer.save!

    redirect_to :action => 'list'
  end
end
