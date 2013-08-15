# -*- encoding: utf-8 -*-
class DeliveryMailsController < ApplicationController
  # GET /delivery_mails
  # GET /delivery_mails.json
  def index
    @bp_pic_group = BpPicGroup.find(params[:id])
    @delivery_mails = DeliveryMail.where("bp_pic_group_id = ?", @bp_pic_group).order("id desc").page().per(50)
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @delivery_mails }
    end
  end

  # GET /delivery_mails/1
  # GET /delivery_mails/1.json
  def show
    @delivery_mail = DeliveryMail.find(params[:id])
    @attachment_files = AttachmentFile.attachment_files("delivery_mails", @delivery_mail.id)
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  def copynew
    @src_mail_id = params[:id]
    src_mail = DeliveryMail.find(@src_mail_id)
    src_mail.setup_planned_setting_at(current_user.zone_at(src_mail.planned_setting_at))
    @attachment_files = AttachmentFile.attachment_files("delivery_mails", src_mail.id)
    @delivery_mail = DeliveryMail.new
    @delivery_mail.attributes = src_mail.attributes.reject{|x| ["created_at", "updated_at", "created_user", "updated_user", "deleted_at", "deleted"].include?(x)}

    new_proc

    respond_to do |format|
      format.html { render action: "new" }
    end
  end

  # GET /delivery_mails/new
  # GET /delivery_mails/new.json
  def new
    @delivery_mail = DeliveryMail.new
    @delivery_mail.bp_pic_group_id = params[:id]
    @delivery_mail.content = <<EOS
%%business_partner_name%%
%%bp_pic_name%%　様
EOS
    unless current_user.mail_signature.blank?
    @delivery_mail.content += <<EOS


-- 
#{current_user.mail_signature}
EOS
    end

    new_proc

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  # GET /delivery_mails/1/edit
  def edit
    @delivery_mail = DeliveryMail.find(params[:id])
    @delivery_mail.setup_planned_setting_at(current_user.zone_at(@delivery_mail.planned_setting_at))
    @attachment_files =  @delivery_mail.attachment_files
    respond_to do |format|
      format.html # edit.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  # POST /delivery_mails
  # POST /delivery_mails.json
  def create
    unless params[:bp_pic_id].blank?
      return contact_mail_create(params[:bp_pic_id])
    end
    @delivery_mail = DeliveryMail.new(params[:delivery_mail])
    @delivery_mail.perse_planned_setting_at(current_user) # zone
    respond_to do |format|
      begin
        set_user_column(@delivery_mail)
         
        ActiveRecord::Base.transaction do
          @delivery_mail.save!
          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)
          # 添付ファイルのコピー
          copy_upload_files(params[:src_mail_id], @delivery_mail.id)
        end
        
        if params[:testmail]
          DeliveryMail.send_test_mail(@delivery_mail)
          format.html {
            redirect_to({
              :controller => 'delivery_mails',
              :action => 'edit',
              :id => @delivery_mail,
              :back_to => back_to
            },
            notice: 'Delivery mail was successfully created.')
          }
        end
        format.html {
          redirect_to url_for(
            :controller => 'bp_pic_groups',
            :action => 'show',
            :id => @delivery_mail.bp_pic_group_id,
            :delivery_mail_id => @delivery_mail.id,
            :back_to => back_to
          ),
          notice: 'Delivery mail was successfully created.'
        }
        format.json { render json: @delivery_mail, status: :created, location: @delivery_mail }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @delivery_mail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /delivery_mails/1
  # PUT /delivery_mails/1.json
  def update
    @delivery_mail = DeliveryMail.find(params[:id])
    @delivery_mail.mail_status_type = 'editing'

    respond_to do |format|
      begin
        @delivery_mail.attributes = params[:delivery_mail]
        @delivery_mail.perse_planned_setting_at(current_user) # zone
        set_user_column(@delivery_mail)
        ActiveRecord::Base.transaction do
          @delivery_mail.save!
          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)
       end

        if params[:testmail]
          DeliveryMail.send_test_mail(@delivery_mail)
          format.html {
            redirect_to({
              :controller => 'delivery_mails',
              :action => 'edit',
              :id => @delivery_mail,
              :back_to => back_to
            },
            notice: 'Delivery mail was successfully created.')
          }
        end
        format.html { 
          redirect_to url_for(
            :controller => 'bp_pic_groups',
            :action => 'show',
            :id => @delivery_mail.bp_pic_group_id,
            :delivery_mail_id => @delivery_mail.id,
            :back_to => back_to
          ),
        notice: 'Delivery mail was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @delivery_mail.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /delivery_mails/add_details
  # POST /delivery_mails/add_details.json
  def add_details
    if params[:bp_pic_ids].blank?
      redirect_to back_to, notice: 'メール対象者が0人でなので、登録できません。'
      return
    end
    delivery_mail = DeliveryMail.find(params[:delivery_mail_id])
    ActiveRecord::Base.transaction do
      delivery_mail.mail_status_type = 'unsend'
      set_user_column delivery_mail
      delivery_mail.save!
      params[:bp_pic_ids].each do |bp_pic_id|
        next if DeliveryMailTarget.where(:delivery_mail_id => delivery_mail.id, :bp_pic_id => bp_pic_id.to_i, :deleted => 0).first
        delivery_mail_target = DeliveryMailTarget.new
        delivery_mail_target.delivery_mail_id = delivery_mail.id
        delivery_mail_target.bp_pic_id = bp_pic_id.to_i
        set_user_column(delivery_mail_target)
        delivery_mail_target.save!
      end
    end
    
    if delivery_mail.planned_setting_at < Time.now.to_s
      DeliveryMail.send_mails
      
      error_count = DeliveryError.where(:delivery_mail_id => delivery_mail.id).size
      if error_count > 0
        flash.now[:warn] = "送信に失敗した宛先が存在します。<br>送信に失敗した宛先は配信メール詳細画面から確認できます。"
      end
    end
      
    respond_to do |format|
      format.html { redirect_to url_for(:action => :index, :id => params[:bp_pic_group_id]), notice: 'Delivery mail targets were successfully created.' }
#        format.json { render json: @delivery_mail_target, status: :created, location: @delivery_mail_target }
    end
  end
   
  # PUT /delivery_mails/cancel/1
  # PUT /delivery_mails/cancel/1.json
  def cancel
    @delevery_mail = DeliveryMail.find(params[:id])
    @delevery_mail.mail_status_type = 'canceled'
    set_user_column @delevery_mail
    @delevery_mail.save!
    
    respond_to do |format|
      format.html { redirect_to back_to, notice: 'Delivery mail was successfully canceled.'  }
    end
  end


  # DELETE /delivery_mails/1
  # DELETE /delivery_mails/1.json
  def destroy
  #  @delivery_mail = DeliveryMail.find(params[:id])
  #  @delivery_mail.destroy

    respond_to do |format|
      format.html { redirect_to delivery_mails_url }
      format.json { head :no_content }
    end
  end

  def contact_mail_new
    @bp_pic = BpPic.find(params[:id])
    @delivery_mail = DeliveryMail.new
    #@delivery_mail.bp_pic_group_id = params[:id]
    unless sales_pic = @bp_pic.sales_pic
      raise ValidationAbort.new("Contact mail method is wants sales_pic id.")
    end
    @delivery_mail.content = ""
    if t = sales_pic.contact_mail_template
      @delivery_mail.mail_cc = t.mail_cc
      @delivery_mail.mail_bcc = t.mail_bcc
      @delivery_mail.subject = t.subject
      @delivery_mail.content = t.content
    end
    unless sales_pic.mail_signature.blank?
      @delivery_mail.content += <<EOS

-- 
#{sales_pic.mail_signature}
EOS
    end
    @delivery_mail.mail_bcc = @delivery_mail.mail_bcc.to_s.split(",").push(sales_pic.email).join(",")
    @delivery_mail.mail_from = sales_pic.email
    @delivery_mail.mail_from_name =sales_pic.employee.employee_name
    @delivery_mail.setup_planned_setting_at(sales_pic.zone_now)

    respond_to do |format|
      format.html { render action: "new" }
    end
  rescue ValidationAbort => e
    respond_to do |format|
      format.html {
        flash[:warning] = '営業担当が設定されていません。'
        redirect_to(back_to)
      }
    end
  end

  def contact_mail_create(bp_pic_id)
    @bp_pic = BpPic.find(bp_pic_id)
    @delivery_mail = DeliveryMail.new(params[:delivery_mail])
    @delivery_mail.setup_planned_setting_at(@bp_pic.sales_pic.zone_now)
    respond_to do |format|
      begin
        set_user_column(@delivery_mail)
         
        ActiveRecord::Base.transaction do
          @delivery_mail.save!
          @bp_pic.contact_mail_flg = 1
          set_user_column @bp_pic
          @bp_pic.save!
          # 添付ファイルの保存
          store_upload_files(@delivery_mail.id)
          # メール送信
          DeliveryMail.send_contact_mail(@delivery_mail, @bp_pic)
        end
        
        format.html {
          redirect_to(back_to , notice: 'Delivery mail was successfully created.')
        }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
      end
    end
  end

private
  def new_proc
    @delivery_mail.mail_from = current_user.email
    @delivery_mail.mail_from_name = current_user.employee.employee_name

    @delivery_mail.setup_planned_setting_at(current_user.zone_now)
  end

  def store_upload_files(parent_id)
    [1,2,3,4,5].each do |i|
      unless (upfile = params['attachment' + i.to_s]).blank?
        af = AttachmentFile.new
        af.create_and_store!(upfile, parent_id, upfile.original_filename, "delivery_mails", current_user.login)
      end
    end
  end
  
  def copy_upload_files(src_mail_id, parent_id)
    unless params[:src_mail_id].blank?
       AttachmentFile.attachment_files("delivery_mails", params[:src_mail_id]).each do |src|
         af = AttachmentFile.new
         af.parent_table_name = src.parent_table_name
         af.parent_id = parent_id
         af.file_name = src.file_name
         af.extention = src.extention
         af.file_path = src.file_path
         set_user_column af
         af.save!
       end
    end
  end
end
