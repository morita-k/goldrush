# -*- encoding: utf-8 -*-
class PhotosController < ApplicationController

  # GET /photos/list
  def list
    @photos = Photo.where(deleted: 0, photo_status_type: :unfixed).order(:created_at)
  end

  def get_image
    filepath = params[:filepath]
    File.open(filepath, 'rb') do |f|
      send_data f.read, :type => "image/jpg", :disposition => "inline"
    end
  end

  def preview
    @photo = Photo.find(params[:id])
  end

  # GET /photos
  # GET /photos.json
  def index
    @photos = Photo.where(deleted: 0).page(params[:page]).per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @photos }
    end
  end

  # GET /photos/1
  # GET /photos/1.json
  def show
    @photo = Photo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @photo }
    end
  end

  # GET /photos/new
  # GET /photos/new.json
  def new
    @photo = Photo.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @photo }
    end
  end

  # GET /photos/1/edit
  def edit
    @photo = Photo.find(params[:id])
  end

  # POST /photos
  # POST /photos.json
  def create
    @photo = Photo.new(params[:photo])
    set_user_column @photo

    respond_to do |format|
      begin
        @photo.save!
        format.html { redirect_to @photo, notice: 'Photo was successfully created.' }
        format.json { render json: @photo, status: :created, location: @photo }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /photos/1
  # PUT /photos/1.json
  def update
    @photo = Photo.find(params[:id])
    @photo.attributes = params[:photo]
    set_user_column @photo

    respond_to do |format|
      begin
        @photo.save!
        format.html { redirect_to @photo, notice: 'Photo was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    @photo = Photo.find(params[:id])
    @photo.deleted = 9
    set_user_column @photo
    @photo.save!
    
    respond_to do |format|
      format.html { redirect_to photos_url }
      format.json { head :no_content }
    end
  end
end
