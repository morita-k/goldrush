# -*- encoding: utf-8 -*-
class BpMemberController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def set_conditions
    session[:bp_member_search] = {
      :hr_name => params[:hr_name],
      :skill_tag => params[:skill_tag],
      :payment_from => params[:payment_from],
      :payment_to => params[:payment_to],
      :age_from => params[:age_from],
      :age_to => params[:age_to],
      :business_partner_id => params[:bp_id],
      :business_partner_name => params[:business_partner_name],
      :bp_pic_id => params[:pic_id],
      :bp_pic_name => params[:bp_pic_name],
      :human_resource_status_type => params[:human_resource_status_type],
      # :employment_type => params[:employment_type],
      :jiet => params[:jiet]
      }
  end

  def make_conditions
    param = []
    include = [:human_resource, :business_partner, :bp_pic]
## TODO 所属と添付ファイルがparent_idでひもづいているのでincludeではなくjoinで結合
#    join = "LEFT OUTER JOIN attachment_files ON attachment_files.parent_table_name = 'bp_member' AND attachment_files.parent_id = bp_members.id"
    sql = "bp_members.deleted = 0"
    order_by = "bp_members.updated_at desc"
    bp_condition = " and (bp_members.business_partner_id = business_partners.id) and (human_resource_id = human_resources.id)"

    if !(hr_name = session[:bp_member_search][:hr_name]).blank?
      sql += " and human_resources.human_resource_name like ? or human_resources.initial like ?"
      param << "%#{hr_name}%" << "%#{hr_name}"
    end

    unless session[:bp_member_search][:skill_tag].blank?
      pids = Tag.make_conditions_for_tag(current_user.owner_id, session[:bp_member_search][:skill_tag], "human_resources")
      unless pids.empty?
        sql += " and human_resources.id in (?) "
        param << pids
      end
    end

    if !(skill_tag = session[:bp_member_search][:skill_tag]).blank?
      sql += " and human_resources.skill_tag like ?"
      param << "%#{skill_tag}%"
    end

    if !(payment_from = session[:bp_member_search][:payment_from]).blank?
      sql += " and bp_members.payment_min >= ?"
      param << (payment_from.to_i * 10000)
    end

    if !(payment_to = session[:bp_member_search][:payment_to]).blank?
      sql += " and bp_members.payment_min <= ?"
      param << (payment_to.to_i * 10000)
    end

    if !(age_from = session[:bp_member_search][:age_from]).blank?
      sql += " and human_resources.age >= ?"
      param << age_from
    end

    if !(age_to = session[:bp_member_search][:age_to]).blank?
      sql += " and human_resources.age <= ?"
      param << age_to
    end

    if !(business_partner_name = session[:bp_member_search][:business_partner_name]).blank?
      sql += (bp_condition + " and (business_partner_name like ? or business_partner_name_kana like ?)")
      param << "%#{business_partner_name}%" << "%#{business_partner_name}%"
    end

    if !(bp_pic_name = session[:bp_member_search][:bp_pic_name]).blank?
      sql += (bp_condition + " and (bp_pic_name like ? or bp_pic_name_kana like ? or bp_pic_short_name like ?)")
      param << "%#{bp_pic_name}%" << "%#{bp_pic_name}%" << "%#{bp_pic_name}%"
    end

    if !(human_resource_status_type = session[:bp_member_search][:human_resource_status_type]).blank?
      sql += " and human_resources.human_resource_status_type = ?"
      param << human_resource_status_type
    end

    # if !(employment_type = session[:bp_member_search][:employment_type]).blank?
    #   sql += " and bp_members.employment_type = ?"
    #   param << employment_type
    # end

    # JIET_FLG
    if !(x = session[:bp_member_search][:jiet]).blank?
      case x
      when "1"
        sql += " and human_resources.jiet = ?"
        param << 0
      when "2"
        sql += " and human_resources.jiet = ?"
        param << 1
      else
      end
    end

    return {:conditions => param.unshift(sql), :include => include, :order => order_by, :per => current_user.per_page}
  end


  def list
    session[:bp_member_search] ||= {}
    if request.post?
      if params[:search_button]
        set_conditions
      elsif params[:clear_button]
        session[:bp_member_search] = {}
      end
    end
    cond = make_conditions
    @bp_member_pages, @bp_members = paginate(:bp_members, cond)
  end

  def show
    @bp_member = BpMember.find(params[:id])
    @human_resource = @bp_member.human_resource
    @attachment_files = AttachmentFile.get_attachment_files('bp_members', @bp_member.id)
    @remarks = Remark.get_all('bp_members', params[:id])
  end

  def new
    @calendar = true
    @bp_member = BpMember.new
    if params[:human_resource_id]
      @human_resource = HumanResource.find(params[:human_resource_id])
    else
      @human_resource = HumanResource.new
    end
    # メール取り込みからの遷移
    if params[:import_mail_id] && params[:template_id]
      @bp_member.import_mail_id = params[:import_mail_id]
      import_mail = ImportMail.find(params[:import_mail_id])
      @bp_member.business_partner_id = import_mail.business_partner_id
      @bp_member.bp_pic_id = import_mail.bp_pic_id

      if params[:from].blank? || params[:end].blank?
        AnalysisTemplate.analyze(current_user.owner_id, params[:template_id], import_mail, [@bp_member, @human_resource])
      else
        AnalysisTemplate.analyze_content(
          current_user.owner_id,
          params[:template_id],
          import_mail.mail_body[params[:from].to_i .. params[:end].to_i],
          [@bp_member, @human_resource]
        )
      end
      @bp_member.convert!
    end
  end

  def create
    @calendar = true
    @bp_member = create_model(:bp_members, params[:bp_member])
    ActiveRecord::Base.transaction do
      unless @human_resource = @bp_member.human_resource
        @human_resource = create_model(:human_resources)
      end
      @human_resource.attributes = params[:human_resource]
      @human_resource.initial = initial_trim(params[:human_resource][:initial])
      set_user_column @human_resource
      @human_resource.save!
      @bp_member.human_resource = @human_resource

      # タグを更新
      @human_resource.make_skill_tags!
      @human_resource.save!

      set_user_column @bp_member
      @bp_member.save!

      if !@bp_member.import_mail_id.blank?
        import_mail = ImportMail.find(@bp_member.import_mail_id)
        import_mail.registed = 1
        import_mail.bp_member_flg = 1
        set_user_column import_mail
        import_mail.save!
      end
    end
    flash_notice = 'BpMember was successfully created.'

    if popup?
      # ポップアップウィンドウの場合、ポップアップ状態のまま通常の画面遷移
      flash[:notice] = flash_notice
      redirect_to back_to || {:action => 'list', :popup => 1}
    else
      # ポップアップウィンドウでなければ通常の画面遷移
      flash[:notice] = flash_notice
      redirect_to back_to || {:action => 'list'}
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @calendar = true
    @bp_member = BpMember.find(params[:id])
    @human_resource = @bp_member.human_resource
# メール取り込みからの遷移
    if params[:import_mail_id] && params[:template_id]
      import_mail = ImportMail.find(params[:import_mail_id])
      AnalysisTemplate.analyze(current_user.owner_id, params[:template_id], import_mail, [@bp_member, @human_resource])
    end
  end

  def update
    @calendar = true
    @human_resource = HumanResource.find(params[:human_resource_id], :conditions =>["deleted = 0"])
    @bp_member = BpMember.find(params[:id], :conditions =>["deleted = 0"])
    @human_resource.attributes = params[:human_resource]
    @human_resource.initial = initial_trim(params[:human_resource][:initial])
    @bp_member.attributes = params[:bp_member]
    ActiveRecord::Base.transaction do
      # タグを更新
      @human_resource.make_skill_tags!
      set_user_column @human_resource
      set_user_column @bp_member
      @human_resource.save!
      @bp_member.save!
    end
    flash[:notice] = 'BpMember was successfully updated.'
    redirect_to back_to || {:action => 'show', :id => @bp_member}
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @bp_member = BpMember.find(params[:id], :conditions =>["deleted = 0"])
    @bp_member.deleted = 9
    @bp_member.deleted_at = Time.now
    set_user_column @bp_member
    @bp_member.save!

    redirect_to :action => 'list'
  end

  def initial_trim(initial)
    upcased_initial_list = initial.scan(/[(a-z)(A-Z)]/)
    upcased_initial = ""
    upcased_initial_list.each do |upcased_initial_element|
      upcased_initial << upcased_initial_element.upcase
    end
    upcased_initial
  end

end
