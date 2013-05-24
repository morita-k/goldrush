require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup do
    @tag = tags(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tags)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tag" do
    assert_difference('Tag.count') do
      post :create, tag: { display_order1: @tag.display_order1, display_order2: @tag.display_order2, display_order3: @tag.display_order3, inc_count: @tag.inc_count, starred: @tag.starred, tag_count: @tag.tag_count, tag_key: @tag.tag_key, tag_level: @tag.tag_level, tag_text: @tag.tag_text }
    end

    assert_redirected_to tag_path(assigns(:tag))
  end

  test "should show tag" do
    get :show, id: @tag
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @tag
    assert_response :success
  end

  test "should update tag" do
    put :update, id: @tag, tag: { display_order1: @tag.display_order1, display_order2: @tag.display_order2, display_order3: @tag.display_order3, inc_count: @tag.inc_count, starred: @tag.starred, tag_count: @tag.tag_count, tag_key: @tag.tag_key, tag_level: @tag.tag_level, tag_text: @tag.tag_text }
    assert_redirected_to tag_path(assigns(:tag))
  end

  test "should destroy tag" do
    assert_difference('Tag.count', -1) do
      delete :destroy, id: @tag
    end

    assert_redirected_to tags_path
  end
end
