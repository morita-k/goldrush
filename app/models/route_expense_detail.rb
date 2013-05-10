# -*- encoding: utf-8 -*-
class RouteExpenseDetail < ActiveRecord::Base

  belongs_to :route_expense
  
  validates_presence_of :station_from, :station_to, :organization_name, :monthly_amount
  validates_length_of :station_from, :maximum=>100
  validates_length_of :station_to, :maximum=>100
  validates_length_of :memo, :maximum=>4000, :allow_blank => true
  
end
