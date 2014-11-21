# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = BpPicController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    @bp_pic = bp_pics(:bp_pics_5)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_bp_pics = BpPic.where(:owner_id => @owner_id)

    get :index
    bp_pics = assigns(:bp_pics).select {|bp_pic| bp_pic.owner_id == @owner_id}
    assert_equal(current_owner_bp_pics.size, bp_pics.size)
    assert_response :success
  end

  test "should create bp_pic" do
    assert_difference("BpPic.where(:owner_id => #{@owner_id}).count", +1) do
      post :create, bp_pic: { business_partner_id: 1, bp_pic_name: @bp_pic.bp_pic_name, bp_pic_short_name: @bp_pic.bp_pic_short_name, bp_pic_name_kana: @bp_pic.bp_pic_name_kana, email1: "test@example.com", working_status_type: "working" }, back_to: "/bp_pic/list"
    end

    assert_redirected_to "/bp_pic/list"
  end

  test "should get index by another owner" do
    sign_in users(:users_1)

    get :index
    bp_pics = assigns(:bp_pics).select {|bp_pic| bp_pic.owner_id == @owner_id}
    assert_empty(bp_pics)
    assert_response :success
  end

end
