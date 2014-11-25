# -*- encoding: utf-8 -*-


class MailTemplatesController < ApplicationController
  # GET /mail_templates
  # GET /mail_templates.json
  def index
    @mail_templates = find_login_owner(:mail_templates)
                        .where(deleted: 0)
                        .order("mail_template_category, id desc")
                        .page(params[:page])
                        .per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mail_templates }
    end
  end

  # GET /mail_templates/1
  # GET /mail_templates/1.json
  def show
    @mail_template = MailTemplate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mail_template }
    end
  end

  # GET /mail_templates/new
  # GET /mail_templates/new.json
  def new
    @mail_template = MailTemplate.new
    @mail_template.content = <<EOS
%%business_partner_name%%
%%bp_pic_name%%様
EOS

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mail_template }
    end
  end

  # GET /mail_templates/1/edit
  def edit
    @mail_template = MailTemplate.find(params[:id])
  end

  # POST /mail_templates
  # POST /mail_templates.json
  def create
    @mail_template = create_model(:mail_templates, params[:mail_template])
    set_user_column @mail_template

    respond_to do |format|
      begin
        @mail_template.save!
        format.html { redirect_to @mail_template, notice: 'Mail template was successfully created.' }
        format.json { render json: @mail_template, status: :created, location: @mail_template }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @mail_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /mail_templates/1
  # PUT /mail_templates/1.json
  def update
    @mail_template = MailTemplate.find(params[:id])
    @mail_template.attributes = params[:mail_template]
    set_user_column @mail_template

    respond_to do |format|
      begin
        @mail_template.save!
        format.html { redirect_to @mail_template, notice: 'Mail template was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @mail_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mail_templates/1
  # DELETE /mail_templates/1.json
  def destroy
    @mail_template = MailTemplate.find(params[:id])
    @mail_template.deleted = 9
    set_user_column @mail_template
    @mail_template.save!
    
    respond_to do |format|
      format.html { redirect_to mail_templates_url }
      format.json { head :no_content }
    end
  end
end

