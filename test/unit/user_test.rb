require 'test_helper'

class UserTest < ActiveSupport::TestCase
   test "User find" do
     u = User.find(1)
     assert_equal(users(:users_1).login, u.login)
     assert_equal("system@aaa.com", u.email)
   end
end
