# -*- encoding: utf-8 -*-
class SpecialWordsController < ApplicationController
  before_filter :only_super_user

  # GET /special_words
  # GET /special_words.json
  def index
    session[:special_words_search] ||= {}
    if params[:search_button]
      set_conditions
    elsif params[:clear_button]
      session[:special_words_search] = {}
    end

    # 検索条件を処理
    cond, order_by = make_conditions
    
    @special_words = find_login_owner(:special_words)
                        .where(cond)
                        .order(order_by)
                        .page(params[:page])
                        .per(current_user.per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @special_words }
    end
  end

  # GET /special_words/1
  # GET /special_words/1.json
  def show
    @special_word = SpecialWord.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @special_word }
    end
  end

  # GET /special_words/new
  # GET /special_words/new.json
  def new
    @special_word = SpecialWord.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @special_word }
    end
  end

  # GET /special_words/1/edit
  def edit
    @special_word = SpecialWord.find(params[:id])
  end

  # POST /special_words
  # POST /special_words.json
  def create
    @special_word = create_model(:special_words, params[:special_word])
    set_user_column @special_word

    respond_to do |format|
      begin
        @special_word.save!
        format.html { redirect_to((back_to || @special_word), notice: 'Special word was successfully created.') }
        format.json { render json: @special_word, status: :created, location: @special_word }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @special_word.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /special_words/1
  # PUT /special_words/1.json
  def update
    @special_word = SpecialWord.find(params[:id])
    @special_word.attributes = params[:special_word]
    set_user_column @special_word

    respond_to do |format|
      begin
        @special_word.save!
        format.html { redirect_to((back_to || @special_word), notice: 'Special word was successfully updated.') }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @special_word.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /special_words/1
  # DELETE /special_words/1.json
  def destroy
    @special_word = SpecialWord.find(params[:id])
    @special_word.deleted = 9
    set_user_column @special_word
    @special_word.save!
    
    respond_to do |format|
      format.html { redirect_to special_words_url }
      format.json { head :no_content }
    end
  end
  private

  def set_conditions
    session[:special_words_search] = {
      :special_word_type => params[:special_word_type]
    }
  end

  def make_conditions(session_params = session[:special_words_search])
    param = []
    sql = "deleted = 0"
    order_by = "special_word_type, id desc"
    
    if !(x = session_params[:special_word_type]).blank?
      sql += " and special_word_type = ?"
      param << x
    end
    
    return [param.unshift(sql), order_by]
  end
end
