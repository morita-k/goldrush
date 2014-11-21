# -*- encoding: utf-8 -*-


class TagsController < ApplicationController
  before_filter :only_super_user

  # GET /tags
  # GET /tags.json
  def index
    session[:tags_search] ||= {}
    if params[:search_button]
      set_conditions
    elsif params[:clear_button]
      session[:tags_search] = {}
    end

    # 検索条件を処理
    cond, order_by = make_conditions
    
    @tags = find_login_owner(:tags).where(cond).order(order_by).page(params[:page]).per(current_user.per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tags }
    end
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    @tag = Tag.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.json
  def new
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = create_model(:tags, params[:tag])
    set_user_column @tag

    respond_to do |format|
      begin
        @tag.save!
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render json: @tag, status: :created, location: @tag }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.json
  def update
    @tag = Tag.find(params[:id])
    @tag.attributes = params[:tag]
    set_user_column @tag

    respond_to do |format|
      begin
        @tag.save!
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag = Tag.find(params[:id])
    @tag.deleted = 9
    set_user_column @tag
    @tag.save!
    
    respond_to do |format|
      format.html { redirect_to tags_url }
      format.json { head :no_content }
    end
  end

  def fix
    if params[:tag_id]
      tag = Tag.find(params[:tag_id])
    else
      tag = find_login_owner(:tags).where("deleted = 0 and tag_text = ?", params[:tag]).first
    end
    tag.starred = params[:starred] || 3
    tag.save!
    render :text => "OK", :layout => false
  end

  private

  def set_conditions
    session[:tags_search] = {
      :tag_key => params[:tag_key],
      :tag_text => params[:tag_text],
      :starred => params[:starred]
    }
  end

  def make_conditions(session_params = session[:tags_search])
    param = []
    sql = "deleted = 0"
    order_by = "tag_key desc, tag_count desc, display_order1 desc"
    
    if !(x = session_params[:tag_key]).blank?
      sql += " and tag_key = ?"
      param << x
    end
    
    if !(x = session_params[:tag_text]).blank?
      sql += " and tag_text = ?"
      param << x
    end
    
    if !(x = session_params[:starred]).blank?
      sql += " and starred = ?"
      param << x
    end
    
    return [param.unshift(sql), order_by]
  end
end

