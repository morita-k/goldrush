# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicGroupsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:users_1)
    @bp_pic_group = bp_pic_groups(:bp_pic_groups_1)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bp_pic_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create bp_pic_group" do
    assert_difference('BpPicGroup.count') do
      post :create, bp_pic_group: { bp_pic_group_name: @bp_pic_group.bp_pic_group_name, memo: @bp_pic_group.memo }, id: @bp_pic_group.id, back_to: "/bp_pic_groups"
    end
 
    assert_redirected_to "/bp_pic_groups"
  end

  test "should show bp_pic_group" do
    get :show, id: @bp_pic_group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @bp_pic_group
    assert_response :success
  end

  test "should update bp_pic_group" do
    put :update, id: @bp_pic_group, bp_pic_group: { bp_pic_group_name: @bp_pic_group.bp_pic_group_name, memo: @bp_pic_group.memo }, id: @bp_pic_group.id, back_to: "/bp_pic_groups"
    assert_redirected_to "/bp_pic_groups"
  end

  test "should destroy bp_pic_group" do
    delete :destroy, id: @bp_pic_group
    assert(BpPicGroup.where(id: @bp_pic_group, deleted: 0).empty?)
    
    assert_redirected_to bp_pic_groups_path
  end
end
