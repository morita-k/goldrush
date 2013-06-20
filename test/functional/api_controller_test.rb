# -*- encoding: utf-8 -*-
require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  setup do
    sign_in users(:users_1)
  end
  
  test "send mails" do
    get :broadcast_mail
    
    assert_response :success
  end
end