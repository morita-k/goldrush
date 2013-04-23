# -*- encoding: utf-8 -*-
class DeliveryMailsController < ApplicationController
  # GET /delivery_mails
  # GET /delivery_mails.json
  def index
    @delivery_mails = DeliveryMail.where("bp_pic_group_id = ?", params[:id]).page().per(50)

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

  # GET /delivery_mails/new
  # GET /delivery_mails/new.json
  def new
    @delivery_mail = DeliveryMail.new
    @delivery_mail.bp_pic_group_id = params[:id]

    @delivery_mail.mail_from = SysConfig.get_value("delivery_mails", "mail_from")
    @delivery_mail.mail_from_name = SysConfig.get_value("delivery_mails", "mail_from_name")

    @delivery_mail.setup_planned_setting_at

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  # GET /delivery_mails/1/edit
  def edit
    @delivery_mail = DeliveryMail.find(params[:id])
    @delivery_mail.setup_planned_setting_at
    respond_to do |format|
      format.html # edit.html.erb
      format.json { render json: @delivery_mail }
    end
  end

  # POST /delivery_mails
  # POST /delivery_mails.json
  def create
    @delivery_mail = DeliveryMail.new(params[:delivery_mail])
    @delivery_mail.bp_pic_group_id = params[:bp_pic_group_id]
    @delivery_mail.mail_from_name = params[:mail_from_name]
    @delivery_mail.mail_from = params[:mail_from]
    
    respond_to do |format|
      begin
        set_user_column(@delivery_mail)
         
        ActiveRecord::Base.transaction do
          @delivery_mail.save!
          # 添付ファイルの保存
          store_upload_file(@delivery_mail.id)
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
        set_user_column(@delivery_mail)
        ActiveRecord::Base.transaction do
          @delivery_mail.update_attributes!(params[:delivery_mail])
          # 添付ファイルの保存
          store_upload_file(@delivery_mail.id)
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
    end
      
    respond_to do |format|
      format.html { redirect_to url_for(:action => 'show', :id => delivery_mail), notice: 'Delivery mail targets were successfully created.' }
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
private
  def store_upload_file(parent_id)
    [1,2,3,4,5].each do |i|
      unless (upfile = params['attachment' + i.to_s]).blank?
        af = AttachmentFile.new
        af.create_and_store!(upfile, parent_id, upfile.original_filename, "delivery_mails")
      end
    end
  end
end
