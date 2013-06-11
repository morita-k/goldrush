# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicGroupDetailsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:users_1)
    @bp_pic_group_detail = bp_pic_group_details(:bp_pic_group_details_1)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bp_pic_group_details)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create bp_pic_group_detail" do
    assert_difference('BpPicGroupDetail.count') do
      post :create, bp_pic_group_detail: { bp_pic_group_id: @bp_pic_group_detail.bp_pic_group_id, bp_pic_id: @bp_pic_group_detail.bp_pic_id, memo: @bp_pic_group_detail.memo }, id: @bp_pic_group_detail.id, back_to: "/bp_pic_group_detail"
    end

    assert_redirected_to "/bp_pic_group_detail"
  end

  test "should show bp_pic_group_detail" do
    get :show, id: @bp_pic_group_detail 
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @bp_pic_group_detail
    assert_response :success
  end

  test "should update bp_pic_group_detail" do
    put :update, id: @bp_pic_group_detail, bp_pic_group_detail: { bp_pic_group_id: @bp_pic_group_detail.bp_pic_group_id, bp_pic_id: @bp_pic_group_detail.bp_pic_id, id: @bp_pic_group_detail.id, memo: @bp_pic_group_detail.memo }
    assert_redirected_to bp_pic_group_detail_path(assigns(:bp_pic_group_detail))
  end

  test "should destroy bp_pic_group_detail" do
    delete :destroy, id: @bp_pic_group_detail, back_to: bp_pic_group_details_path
    assert(BpPicGroupDetail.where(id: @bp_pic_group_detail, deleted: 0).empty?)
    
    assert_redirected_to bp_pic_group_details_path
  end
end
