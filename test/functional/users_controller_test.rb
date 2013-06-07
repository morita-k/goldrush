require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:users_1)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, user: { access_level_type: @user.access_level_type, current_sign_in_at: @user.current_sign_in_at, current_sign_in_ip: @user.current_sign_in_ip, last_sign_in_at: @user.last_sign_in_at, last_sign_in_ip: @user.last_sign_in_ip, locked_at: @user.locked_at, login: @user.login, nickname: @user.nickname, per_page: @user.per_page, sign_in_count: @user.sign_in_count }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    put :update, id: @user, user: { access_level_type: @user.access_level_type, current_sign_in_at: @user.current_sign_in_at, current_sign_in_ip: @user.current_sign_in_ip, last_sign_in_at: @user.last_sign_in_at, last_sign_in_ip: @user.last_sign_in_ip, locked_at: @user.locked_at, login: @user.login, nickname: @user.nickname, per_page: @user.per_page, sign_in_count: @user.sign_in_count }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
