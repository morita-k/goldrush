namespace :app do
  
  def logger
    Rails.logger
  end

  desc "The batch of calculation of days total of vacation."
  task :calculate_vacation => :environment do
    logger.info "Start vacation calculation batch.: " + Time.now.strftime("%Y/%m/%d %H:%M:%S")

    year = (ENV['YEAR'] || Date.today.year.to_s)

    Vacation.calculate_vacations(year)

    logger.info "Bye vacation calculation batch.: " + Time.now.strftime("%Y/%m/%d %H:%M:%S")
  end

  desc "The batch of calculation of compensatories of vacation."
  task :calculate_compensatories => :environment do
    logger.info "Start vacation calculate_compensatories batch.: " + Time.now.strftime("%Y/%m/%d %H:%M:%S")

    if ENV['NEXT']
      date = ENV['NEXT']
    else
      bm = BaseMonth.get_base_month_by_date(Date.today + 1.month)
      date = bm.start_date.to_date.strftime('%Y/%m/%d')
    end

    Vacation.calculate_compensatories(date)

    logger.info "Bye vacation calculate_compensatories batch.: " + Time.now.strftime("%Y/%m/%d %H:%M:%S")
  end

end
