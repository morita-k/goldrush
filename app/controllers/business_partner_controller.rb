# -*- encoding: utf-8 -*-
class BusinessPartnerController < ApplicationController
  def index
    list
    render :action => 'list'
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#  verify :method => :post, :only => [ :destroy, :create, :update ],
#         :redirect_to => { :action => :list }

  def set_conditions
    session[:business_partner_search] = {
      :sales_code => params[:sales_code],
      :business_partner_code => params[:business_partner_code],
      :business_partner_name_kana => params[:business_partner_name_kana],
      :self_flg => params[:self_flg],
      :eu_flg => params[:eu_flg],
      :upper_flg => params[:upper_flg],
      :down_flg => params[:down_flg]
      }
  end

  def make_conditions
    param = []
    incl = []
    sql = "business_partners.deleted = 0"
    order_by = ""

    if !(sales_code = session[:business_partner_search][:sales_code]).blank?
      sql += " and sales_code = ?"
      param << sales_code
    end

    if !(business_partner_code = session[:business_partner_search][:business_partner_code]).blank?
      sql += " and business_partner_code like ?"
      param << "%#{business_partner_code}%"
    end

    if !(business_partner_name_kana = session[:business_partner_search][:business_partner_name_kana]).blank?
      sql += " and business_partner_name_kana like ?"
      param << "%#{business_partner_name_kana}%"
    end

    if !(self_flg = session[:business_partner_search][:self_flg]).blank?
      sql += " and self_flg = 1"
    end

    if !(eu_flg = session[:business_partner_search][:eu_flg]).blank?
      sql += " and eu_flg = 1"
    end

    if !(upper_flg = session[:business_partner_search][:upper_flg]).blank?
      sql += " and upper_flg = 1"
    end

    if !(down_flg = session[:business_partner_search][:down_flg]).blank?
      sql += " and down_flg = 1"
    end

    #return {:conditions => param.unshift(sql), :include => include, :per_page => current_user.per_page}
    return [param.unshift(sql), incl]
  end

# 1 = 1 or self_flg = ? or eu_flg = ? or upper_flg = ? or down_flg = ?

  def make_popup_conditions(self_flg, eu_flg, upper_flg, down_flg)
    param = []
    sql = "deleted = 0 and (1 = 0"
    order_by = ""

    if self_flg == 1
      sql += " or self_flg = 1"
    end

    if eu_flg == 1
      sql += " or eu_flg = 1"
    end

    if upper_flg == 1
      sql += " or upper_flg = 1"
    end

    if down_flg == 1
      sql += " or down_flg = 1"
    end

    sql += ")"

    return param.unshift(sql)
  end

  def list
    session[:business_partner_search] ||= {}
    incl = []
    flg = params[:flg]
    if !flg.blank?
      if flg == 'eu'
        cond = make_popup_conditions(0,1,0,0)
      elsif flg == 'upper'
        cond = make_popup_conditions(0,0,1,0)
      elsif flg == 'down'
        cond = make_popup_conditions(0,0,0,1)
      elsif flg == 'eu_or_upper'
        cond = make_popup_conditions(0,1,1,0)
      elsif flg == 'upper_or_down'
        cond = make_popup_conditions(0,0,1,1)
      else
        # ありえないけど念のため
        cond, incl = make_conditions
      end
    else
      if request.post?
        if params[:search_button]
          set_conditions
        elsif params[:clear_button]
          session[:business_partner_search] = {}
        end
      end
      cond, incl = make_conditions
    end
    #@business_partner_pages, @business_partners = paginate(:business_partners, cond)
    @business_partners = BusinessPartner.includes(incl).where(cond).page(params[:page]).per(current_user.per_page)
  end

  def show
    @business_partner = BusinessPartner.find(params[:id])
    @bp_pics = BpPic.find(:all, :conditions => ["deleted = 0 and business_partner_id = ?", params[:id]])
    @businesses = Business.find(:all, :conditions => ["deleted = 0 and eubp_id = ?", @business_partner], :order => "id desc", :limit => 50)
    @biz_offers = BizOffer.find(:all, :conditions => ["deleted = 0 and business_partner_id = ?", @business_partner], :order => "id desc", :limit => 50)
    @bp_members = BpMember.find(:all, :conditions => ["deleted = 0 and business_partner_id = ?", @business_partner], :order => "id desc", :limit => 50)
    @remarks = Remark.find(:all, :conditions => ["deleted = 0 and remark_key = ? and remark_target_id = ?", 'business_partners', params[:id]])
  end

  def new
    @business_partner = BusinessPartner.new
    if params[:flg] == 'eu'
      @business_partner.eu_flg = 1
    elsif params[:flg] == 'upper'
      @business_partner.upper_flg = 1
    elsif params[:flg] == 'down'
      @business_partner.down_flg = 1
    elsif params[:flg] == 'eu_or_upper'
      @business_partner.eu_flg = 1
      @business_partner.upper_flg = 1
    end
    
    @bp_pic = BpPic.new
    @bp_pic.business_partner = @business_partner
    if params[:import_mail_id]
      @business_partner.import_mail_id = params[:import_mail_id]
      @bp_pic.import_mail_id = params[:import_mail_id]
    end
  end

  def create
    @bp_pic = BpPic.new(params[:bp_pic])
    mail_flg = false
    ActiveRecord::Base.transaction do
      
      if !(params[:business_partner][:id]).blank?
        # 取り込みメールからのBP・BP担当登録で、BPを登録済のものから選択した場合
        @business_partner = BusinessPartner.find(params[:business_partner][:id])
        mail_flg = true
      else
        @business_partner = BusinessPartner.new(params[:business_partner])
        @business_partner.tag_text = Tag.normalize_tag(@business_partner.tag_text).join(" ")
      end

      @business_partner.business_partner_name = space_trim(params[:business_partner][:business_partner_name])
      set_user_column @business_partner
      @business_partner.save!

      unless mail_flg
        Tag.create_tags!('business_partners', @business_partner.id, @business_partner.tag_text)
      end
      
      @bp_pic.business_partner_id = @business_partner.id
      @bp_pic.bp_pic_name = space_trim(params[:bp_pic][:bp_pic_name]).gsub(/　/," ")
      set_user_column @bp_pic
      @bp_pic.save!
      
      if !@business_partner.import_mail_id.blank?
        import_mail = ImportMail.find(@business_partner.import_mail_id)
        import_mail.business_partner_id = @business_partner.id
        import_mail.bp_pic_id = @bp_pic.id
        set_user_column import_mail
        import_mail.save!
      end
      
    end
    
    flash[:notice] = 'BusinessPartner was successfully created.'
    if mail_flg
      redirect_to :controller => :business_partner, :action => :show, :id => @business_partner.id
    else
      redirect_to(params[:back_to] || {:action => 'list'})
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @business_partner = BusinessPartner.find(params[:id])
  end

  def update
    ActiveRecord::Base.transaction do
      @business_partner = BusinessPartner.find(params[:id], :conditions =>["deleted = 0"])
      old_tags = @business_partner.tag_text
      @business_partner.attributes = params[:business_partner]
      @business_partner.tag_text = Tag.normalize_tag(@business_partner.tag_text).join(" ")
      if old_tags != @business_partner.tag_text
        Tag.update_tags!('business_partners', @business_partner.id, @business_partner.tag_text)
      end
      @business_partner.business_partner_name = space_trim(params[:business_partner][:business_partner_name])
      set_user_column @business_partner
      @business_partner.save!
    end
    flash[:notice] = 'BusinessPartner was successfully updated.'
    redirect_to :action => 'show', :id => @business_partner
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @business_partner = BusinessPartner.find(params[:id], :conditions =>["deleted = 0"])
    @business_partner.deleted = 9
    @business_partner.deleted_at = Time.now
    set_user_column @business_partner
    @business_partner.save!
    
    redirect_to :action => 'list'
  end
  
  def space_trim(bp_name)
    bp_name_list = bp_name.split(/[\s"　"]/)
    trimed_bp_name = ""
    bp_name_list.each do |bp_name_element|
      trimed_bp_name << bp_name_element
    end
    trimed_bp_name
  end
  
  def space_unify(bp_pic_name)
    bp_name_list = bp_pic_name.split(/["　"]/)
    trimed_bp_name = ""
    bp_name_list.each do |bp_name_element|
      trimed_bp_name << bp_name_element
      trimed_bp_name << /\s/
    end
    trimed_bp_name
  end

  def download_csv
    send_data BusinessPartner.export_to_csv, :filename => "bpexport_#{Time.now.strftime("%Y%m%d_%H%M%S")}.csv", :type => "text/csv"
  end

  def upload_csv
    unless file = params[:csv_upload_file]
      flash[:notice] = 'ファイルを選択してください'
      redirect_to(back_to || {:action => :list})
      return
    end
    ext = File.extname(file.original_filename.to_s).downcase
    raise ValidationAbort.new("インポートするファイルは、拡張子がcsvのファイルでなければなりません") if ext != '.csv'
    BusinessPartner.import_from_csv_data(file.read, SysConfig.email_prodmode?)
    flash[:notice] = 'インポートが完了しました'
    redirect_to(back_to || {:action => :list})
  end
  
  def change_star
    business_partner = BusinessPartner.find(params[:id])
    if business_partner.starred == 1
      business_partner.starred = 0
    else
      business_partner.starred = 1
    end
      set_user_column business_partner
      business_partner.save!
    render :text => business_partner.starred
  end
end
