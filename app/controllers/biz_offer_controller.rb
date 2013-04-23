# -*- encoding: utf-8 -*-
class BizOfferController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @biz_offer_pages, @biz_offers = paginate :biz_offers, :conditions =>["deleted = 0"], :per_page => current_user.per_page
  end

  def show
    @biz_offer = BizOffer.find(params[:id])
    @business = @biz_offer.business
    @approach_pages, @approaches = paginate :approaches, :conditions =>["deleted = 0 and biz_offer_id = ?", @biz_offer.id], :per_page => current_user.per_page
    @remarks = Remark.find(:all, :conditions => ["deleted = 0 and remark_key = ? and remark_target_id = ?", 'biz_offers', @business.id])
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
    
    # メール取り込みからの遷移
    if params[:import_mail_id]# && params[:template_id]
      import_mail = ImportMail.find(params[:import_mail_id])
      @biz_offer.import_mail = import_mail
      @biz_offer.business_partner_id = import_mail.business_partner_id
      @biz_offer.bp_pic_id = import_mail.bp_pic_id

      if !params[:template_id].blank?
        if params[:from].blank? || params[:end].blank?
          AnalysisTemplate.analyze(params[:template_id], import_mail, [@biz_offer, @business])
        else
          AnalysisTemplate.analyze_content(
            params[:template_id],
            import_mail.mail_body[params[:from].to_i .. params[:end].to_i],
            [@biz_offer, @business]
          )
        end
      end
    end
  end

  def create
    @calendar = true
    @biz_offer = BizOffer.new(params[:biz_offer])
    if @biz_offer.business_id.blank?
      new_flg = true
    end
    ActiveRecord::Base.transaction do
      if new_flg
        @business = Business.new(params[:business])
      else
        @business = Business.find(params[:business_id], :conditions =>["deleted = 0"])
        @business.attributes = params[:business]
      end
      
      if date = DateTimeUtil.str_to_date(params[:business][:issue_datetime])
        @business.issue_datetime = Time.local(date.year, date.month, date.day, params[:issue_datetime_hour].to_i, params[:issue_datetime_minute].to_i)
      end
      
      @business.business_status_type = 'offered'
      set_user_column @business
      @business.save!
      @biz_offer.business_id = @business.id

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
    flash[:notice] = 'BizOffer was successfully created.'
    if new_flg
      redirect_to back_to || {:action => 'list'}
    else
      redirect_to :action => 'show', :id => @biz_offer
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
      AnalysisTemplate.analyze(params[:template_id], import_mail, [@biz_offer, @business])
    end
  end

  def update
    @calendar = true
    BizOffer.transaction do
      @business = Business.find(params[:business_id], :conditions =>["deleted = 0"])
      @biz_offer = BizOffer.find(params[:id], :conditions =>["deleted = 0"])
      @business.attributes = params[:business]
      
      if date = DateTimeUtil.str_to_date(params[:business][:issue_datetime])
        @business.issue_datetime = Time.local(date.year, date.month, date.day, params[:issue_datetime_hour].to_i, params[:issue_datetime_minute].to_i)
      end
      
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
    redirect_to back_to || {:action => 'show', :id => @biz_offer}
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
