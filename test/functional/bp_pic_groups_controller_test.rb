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
      post :create, bp_pic_group: { bp_pic_group_name: "my test group!", matching_way_type: "bp_member", mail_template_id: '1', memo: "my test group memo" }, id: @bp_pic_group.id, back_to: "/bp_pic_groups"
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
    put :update, bp_pic_group: { bp_pic_group_name: @bp_pic_group.bp_pic_group_name, matching_way_type: 'biz_offer', mail_template_id: '2', memo: @bp_pic_group.memo }, id: @bp_pic_group.id, back_to: "/bp_pic_groups"
    assert_redirected_to "/bp_pic_groups"
  end

  test "should destroy bp_pic_group" do
    delete :destroy, id: @bp_pic_group
    assert(BpPicGroup.where(id: @bp_pic_group, deleted: 0).empty?)

    assert_redirected_to bp_pic_groups_path
  end

  test "should get copy(new)" do
    get :new, src_id: 1

    assert_response :success
    assert !@bp_pic_group.bp_pic_group_name.blank?, "bp_pic_group_name is blank"
    assert !@bp_pic_group.memo.blank?, "memo is blank"
  end

  test "should copy(create) bp_pic_group" do
    assert_difference('BpPicGroup.count') do
      post :create, src_id: 1,  bp_pic_group: { bp_pic_group_name: @bp_pic_group.add_copy_string, matching_way_type: @bp_pic_group.matching_way_type, memo: @bp_pic_group.memo },  back_to: "/bp_pic_groups"
    end

    assert_match(/のコピー/, @bp_pic_group.bp_pic_group_name)
    assert_redirected_to "/bp_pic_groups"
  end
end
