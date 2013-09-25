# -*- encoding: utf-8 -*-
class BpPicGroupsController < ApplicationController
  # GET /bp_pic_groups
  # GET /bp_pic_groups.json
  def index
    @bp_pic_groups = BpPicGroup.page(params[:page]).per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bp_pic_groups }
    end
  end

  # GET /bp_pic_groups/1
  # GET /bp_pic_groups/1.json
  def show
    unless params[:delivery_mail_id].blank?
      @delivery_mail = DeliveryMail.find(params[:delivery_mail_id]).get_informations
      @attachment_files = AttachmentFile.attachment_files("delivery_mails", @delivery_mail.id)
    end
    
    @bp_pic_group = BpPicGroup.includes(:bp_pic_group_details => {:bp_pic => :business_partner}).find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @bp_pic_group }
    end
  end

  # GET /bp_pic_groups/new
  # GET /bp_pic_groups/new.json
  def new
    @bp_pic_group = BpPicGroup.new
    
    # コピーして新規作成
    if src_id = params[:src_id]
      source_group = BpPicGroup.find(src_id)
      @bp_pic_group.bp_pic_group_name = source_group.bp_pic_group_name
      @bp_pic_group.memo = source_group.memo
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @bp_pic_group }
    end
  end

  # GET /bp_pic_groups/1/edit
  def edit
    @bp_pic_group = BpPicGroup.find(params[:id])
    respond_to do |format|
      format.html  # edit.html.erb
      format.json { render json: @bp_pic_group }
    end
  end

  # POST /bp_pic_groups
  # POST /bp_pic_groups.json
  def create
    @bp_pic_group = BpPicGroup.new(params[:bp_pic_group])
    source_group_id = params[:src_id]
    
    respond_to do |format|
      begin
        set_user_column(@bp_pic_group)
        @bp_pic_group.save!
        
        # params[:src_id]があった場合、グループのコピーとみなす
        @bp_pic_group.create_clone_group(source_group_id) unless source_group_id.nil?
        
        format.html { redirect_to back_to, notice: 'Bp pic group was successfully created.' }
        format.json { render json: @bp_pic_group, status: :created, location: @bp_pic_group }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @bp_pic_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /bp_pic_groups/1
  # PUT /bp_pic_groups/1.json
  def update
    @bp_pic_group = BpPicGroup.find(params[:id])

    respond_to do |format|
      begin
        @bp_pic_group.update_attributes!(params[:bp_pic_group])
        format.html { redirect_to back_to, notice: 'Bp pic group was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @bp_pic_group.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # GET /bp_pic_groups/new_details/1
  # GET /bp_pic_groups/new_details/1.json
  def new_details
  
    @bp_pic_group_id = params[:id]
    @delivery_mail_id = params[:delivery_mail_id]
    
    respond_to do |format|
      format.html # new_details.html.erb
    end
  
  end
  
  # POST /bp_pic_groups/create_details
  # POST /bp_pic_groups/create_details.json
  def create_details
  
    @bp_pic_ids = params[:bp_pic_ids].split.uniq
    @bp_pic_group_id = params[:bp_pic_group_id]
    @delivery_mail_id = params[:delivery_mail_id]

    errids = []
    respond_to do |format|
      begin
        bp_pic_group_details = BpPicGroupDetail.where(:bp_pic_group_id => @bp_pic_group_id)
        @bp_pic_ids.each do |bp_pic_id|
          # validate
          if bp_pic_id =~ /\D+/ or
            BpPic.find(:first, :conditions => {:id => bp_pic_id}).nil? or
            bp_pic_group_details.any?{|detail| detail.bp_pic_id == bp_pic_id.to_i}
            errids << bp_pic_id
            next
          end

          # add detail
          bp_pic_group_detail = BpPicGroupDetail.new()
          bp_pic_group_detail.bp_pic_group_id = @bp_pic_group_id
          bp_pic_group_detail.bp_pic_id = bp_pic_id
          set_user_column(bp_pic_group_detail)
          bp_pic_group_detail.save!
        end

        if errids.empty?
          format.html { redirect_to back_to, notice: 'Bp pic group details were successfully created.' }
        else
          format.html { redirect_to back_to, notice: 'Bp pic group details were successfully created. but erros (' + errids.join(", ") + ').' }
        end
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new_details" }
        format.json { render json: @bp_pic_group.errors, status: :unprocessable_entity }
      end
    end
  
  end
  
  # DELETE /bp_pic_groups/1
  # DELETE /bp_pic_groups/1.json
  def destroy

    bp_pic_group = BpPicGroup.find(params[:id])
    bp_pic_group.deleted = 9
    bp_pic_group.deleted_at = Time.now
    set_user_column(bp_pic_group)
    bp_pic_group.save!

    respond_to do |format|
      format.html { redirect_to bp_pic_groups_path }
    end
  end

end
