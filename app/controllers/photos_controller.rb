# -*- encoding: utf-8 -*-
class PhotosController < ApplicationController

  # GET /photos/list
  def list
    @photos = Photo.where(deleted: 0, photo_status_type: :unfixed).order('created_at desc')
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

  def delete
    photo_id = params[:photoid]

    Photo.delete_photo(photo_id)

    redirect_to :controller => :photos, :action => :list
  end

  def rotate
    photo_id = params[:photoid]
    left_rotate = params[:left_rotate]
    target_page = params[:target_page]

    Photo.rotate_photo(photo_id, left_rotate)

    if target_page == 'photo'
      redirect_to :controller => :photos, :action => :list
    else
      bp_pic_id = params[:bp_pic_id]
      redirect_to :controller => :bp_pic, :action => :show, :id => bp_pic_id
    end
  end
end
