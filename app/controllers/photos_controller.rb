# -*- encoding: utf-8 -*-
class PhotosController < ApplicationController

  # GET /photos/
  def index
    @photos = find_login_owner(:photos).where(deleted: 0, photo_status_type: :unfixed).order('created_at desc')
  end

  def get_image
    photo = Photo.find(params[:id])
    if params[:tn]
      filepath = photo.thumbnail_path
    else
      filepath = photo.file_path
    end

    File.open(filepath, 'rb') do |f|
      send_data f.read, :type => "image/jpg", :disposition => "inline"
    end
  end

  def preview
    @photo = Photo.find(params[:id])
  end

  def delete
    photo_id = params[:id]

    Photo.delete_photo(photo_id)

    redirect_to back_to || {:controller => :photos, :action => :index}
  end

  def rotate
    photo_id = params[:photo_id]
    left_rotate = params[:left_rotate]

    Photo.rotate_photo(photo_id, left_rotate)

    redirect_to back_to
  end
end
