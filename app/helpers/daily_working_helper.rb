# -*- encoding: utf-8 -*-
module DailyWorkingHelper
  def get_color_come_lately(daily_working)
    # daily_working.calc_come_lately?(@target_employee) ? '#FF0000' : '#000000'
  end

  def get_color_out_time(daily_working)
    if daily_working.calc_leave_early?(@target_employee)
      '#FF0000'
    elsif daily_working.over_time_taxi_flg == 1
      '#FF0000'
    elsif daily_working.over_time_meel_flg == 1
      'blue'
    else
      'black'
    end
  end
end
