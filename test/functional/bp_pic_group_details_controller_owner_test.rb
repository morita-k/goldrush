# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicGroupDetailssControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = BpPicGroupDetailsController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    @bp_pic_group_detail = bp_pic_group_details(:bp_pic_group_details_2)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_bp_pic_group_details = BpPicGroupDetail.where(:owner_id => @owner_id)

    get :index
    bp_pic_group_details = assigns(:bp_pic_group_details).select {|bp_pic_group_detail| bp_pic_group_detail.owner_id == @owner_id}
    assert_equal(current_owner_bp_pic_group_details.size, bp_pic_group_details.size)
    assert_response :success
  end

  test "should create bp_pic_group_detail" do
    assert_difference("BpPicGroupDetail.where(:owner_id => #{@owner_id}).count", +1) do
      @new_bp_pic_group_detail = bp_pic_group_details(:bp_pic_group_details_2)
      @new_bp_pic_group_detail.bp_pic_id = 2
      post :create, bp_pic_group_detail: { bp_pic_group_id: @new_bp_pic_group_detail.bp_pic_group_id, bp_pic_id: @new_bp_pic_group_detail.bp_pic_id, memo: @bp_pic_group_detail.memo }, id: @new_bp_pic_group_detail.id, back_to: "/bp_pic_group_detail"
    end

    assert_no_difference("BpPicGroupDetail.where(:owner_id => #{@owner_id}).count") do
      post :create, bp_pic_group_detail: { bp_pic_group_id: @bp_pic_group_detail.bp_pic_group_id, bp_pic_id: @bp_pic_group_detail.bp_pic_id, memo: @bp_pic_group_detail.memo }, id: @bp_pic_group_detail.id, back_to: "/bp_pic_group_detail"
    end

    assert_redirected_to "/bp_pic_group_detail"
  end

  test "should get index by another owner" do
    sign_in users(:users_1)

    get :index
    bp_pic_group_details = assigns(:bp_pic_group_details).select {|bp_pic_group_detail| bp_pic_group_detail.owner_id == @owner_id}
    assert_empty(bp_pic_group_details)
    assert_response :success
  end
end

