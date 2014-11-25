# encoding: utf-8

class RemarksController < ApplicationController
  # GET /remarks
  # GET /remarks.json
  def index
    @remarks = find_login_owner(:remarks).page(params[:page]).per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @remarks }
    end
  end

  # GET /remarks/1
  # GET /remarks/1.json
  def show
    @remark = Remark.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @remark }
    end
  end

  # GET /remarks/new
  # GET /remarks/new.json
  def new
    @remark = Remark.new
    @remark.remark_target_id = params[:remark_target_id]
    @remark.remark_key = params[:remark_key]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @remark }
    end
  end

  # GET /remarks/1/edit
  def edit
    @remark = Remark.find(params[:id])
  end

  # POST /remarks
  # POST /remarks.json
  def create
    @remark = create_model(:remarks, params[:remark])

    respond_to do |format|
      begin
        set_user_column @remark
        @remark.save!
        format.html { redirect_to back_to, notice: 'コメントを追加しました' }
        format.json { render json: @remark, status: :created, location: @remark }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @remark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /remarks/1
  # PUT /remarks/1.json
  def update
    @remark = Remark.find(params[:id])
    set_user_column @remark
    @remark.save!

    respond_to do |format|
      begin
        @remark.update_attributes!(params[:remark])
        format.html { redirect_to back_to, notice: 'コメントを更新しました' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @remark.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /remarks/1
  # DELETE /remarks/1.json
  def destroy
    @remark = Remark.find(params[:id])
    @remark.deleted = 9
    @remark.deleted_at = Time.now
    set_user_column @remark
    @remark.save!

    respond_to do |format|
      format.html { redirect_to params[:back_to], notice: 'コメントを削除しました' }
    end
  end
end

