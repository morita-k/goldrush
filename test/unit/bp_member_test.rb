# -*- encoding: UTF-8 -*-
require 'test_helper'

class BpMemberTest < ActiveSupport::TestCase

  test "convert some properties" do
    m = BpMember.new
    
    m.payment_memo = "100万　8万　20万"
    m.convert!
    assert_equal 80000.0, m.payment_min
    
    m.payment_memo = ""
    m.convert!
    assert_equal nil, m.payment_min
    
  end
  
end
