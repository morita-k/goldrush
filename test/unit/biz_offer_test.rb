# -*- encoding: UTF-8 -*-
require 'test_helper'

class BizOfferTest < ActiveSupport::TestCase

  test "convert some properties" do
    m = BizOffer.new
    
    m.payment_text = "100万　8万　20万"
    m.convert!
    assert_equal 1000000.0, m.payment_max
    
    m.payment_text = ""
    m.convert!
    assert_equal nil, m.payment_max
    
  end
  
end
