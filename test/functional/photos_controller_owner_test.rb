# -*- encoding: utf-8 -*-
require 'test_helper'

class PhotosControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = PhotosController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_photos = Photo.where(:owner_id => @owner_id, :photo_status_type => :unfixed)

    get :index
    photos = assigns(:photos).select {|photo| photo.owner_id == @owner_id}
    assert_equal(current_owner_photos.size, photos.size)
    assert_response :success
  end

  test "should get index by another owner" do
    sign_in users(:users_1)

    get :index
    photos = assigns(:photos).select {|photo| photo.owner_id == @owner_id}
    assert_empty(photos)
    assert_response :success
  end
end
