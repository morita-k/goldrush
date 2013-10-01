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

  def delete
    photo_id = params[:photoid]

    Photo.delete_photo(photo_id)

    redirect_to :controller => :photos, :action => :list
  end
end
