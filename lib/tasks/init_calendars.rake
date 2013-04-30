namespace :app do
  # arg check
  def check_args
    if ENV['START'].blank? || ENV['END'].blank?
      raise "usage: rake app:basedategen START=2000/1/1 END=2010/12/31"
    end
  end

  def check_period(st, ed)
    raise "Error: START > END" if st > ed
    return if BaseDate.count == 0
    m = BaseDate.find_by_sql("select max(calendar_date) as max_date, min(calendar_date) as min_date from base_dates")
    return unless m[0].max_date
    raise "Error: Calendar_date was be serialize.(now existing #{m[0].min_date} #{m[0].max_date})" unless (m[0].max_date.to_date+1 == st or m[0].min_date.to_date-1 == ed)
  end

  #
  # update the holidays
  #
  def update_holidays(st, ed)
   require "rexml/document"
   holiday_file = File.join([Rails.root,'config','holidays.xml'])
   doc = nil
   File.open(holiday_file, 'r') do |file|
     doc = REXML::Document.new file.read
   end
   doc.elements.each('HolidayList/Holiday/Row'){|row|
     date = row.elements['Date'].text.to_date
     next if (date < st or date > ed)
     #next unless c = Calendar.find(:first, :conditions => ['calendar_date = ? ', date])
     next unless bd = BaseDate.find(:first, :conditions => ['calendar_date = ? ', date])
     bd.holiday_flg = 1
     bd.comment1 = row.elements['Name1'].text
     bd.save!
   }
  end
    

  desc 'Generate calendars usage: RAILS_ENV=production rake app:basedategen START=2013/1/1 END=2018/12/31 (and put "holidays.yml" on RAILS_ROOT/config dir. before get holiday xml data by "http://www.h3.dion.ne.jp/~sakatsu/holiday_topic.htm")'
  task :basedategen => :environment do
    check_args

    st = ENV['START'].to_date
    ed = ENV['END'].to_date
    check_period st, ed
    st.step(ed,1) do |x|
      BaseDate.new({
        :calendar_date => x,
        :day_of_week => x.wday,
        :day_of_year => x.yday,
        :lastday_flg => (x == x.at_end_of_month ? 1 : 0),
        :created_user => 'rake_init_cal', 
        :updated_user => 'rake_init_cal'
      }).save!
    end

    update_holidays st, ed
    
  end

  def check_basemonthgen_args
    if ENV['START'].blank? || ENV['MCNT'].blank?
      raise "usage: rake app:basemonthgen START=2000/1 MCNT=3"
    end
  end

  desc 'Generate base months usage: RAILS_ENV=production rake app:basemonthgen START=2013/1 MCNT=60'
  task :basemonthgen => :environment do
    check_basemonthgen_args
    month_start_date = SysConfig.get_month_start_date.value1
    start_date = (ENV['START'] + "/" + month_start_date).to_date
    end_date = start_date.next_month - 1
    ActiveRecord::Base::transaction() do
      months = ENV['MCNT'].to_i
      (months).times do |idx|
puts ">>>>>>>>>>> START_DATE: " + start_date.to_s
        if base_month = BaseMonth.find(:first, :conditions => ["start_date = ? and deleted = 0", start_date])
puts ">>>>>>>>>>> 1"
          if base_month.last_flg == 1 && idx < (months - 1) # BaseMonthが存在していて、最終月でなければ。。
puts ">>>>>>>>>>> 2"
            base_month.last_flg = 0
            base_month.updated_user = 'basemonthgen'
            base_month.save!
          end
          next
        end
        base_month = BaseMonth.new
        base_month.report_month = end_date.to_date.month
        base_month.start_date = start_date.to_date
        base_month.end_date = end_date.to_date
        base_month.last_flg = (idx == (months - 1) ? 1 : 0)
        base_month.created_user = 'basemonthgen'
        base_month.updated_user = 'basemonthgen'
        base_month.save!
        start_date = end_date + 1
        end_date = start_date.next_month - 1
      end
    end
  end
end
