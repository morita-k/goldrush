# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DailyReport ,'get_daily_report' do
  describe '順次テスト' do
    def create_reports
      31.times do
        FG.create(:sequence_dates01)
      end
    end

    before(:all) do
      self.use_transactional_fixtures = false
    end

    after(:all) do
      self.use_transactional_fixtures = true
    end

    it 'データがない状態で呼び出すとその月のデータが呼び出されるが未作成のままである' do
      expect(DailyReport.all).to have(0).items
      result_daily_report = DailyReport.get_daily_report('2014-01', '1')

      expect(result_daily_report).to have(31).items

      expect(DailyReport.all).to have(0).items
    end

    it 'データがある状態で呼び出すとその月のデータが呼び出される' do
      create_reports
      result_daily_report = DailyReport.get_daily_report('2014-01', '1')

      expect(result_daily_report).to have(31).items

      expect(DailyReport.all).to have(31).items
    end

    it '違う月を引数にするとデータが呼び出されるが未作成のままである' do
      result_daily_report = DailyReport.get_daily_report('2013-12', '1')

      expect(result_daily_report).to have(31).items

      expect(DailyReport.all).to have(31).items
    end

    it '違うユーザIDを引数にするとデータが呼び出されるが未作成のままである' do
      result_daily_report = DailyReport.get_daily_report('2013-12', '2')

      expect(result_daily_report).to have(31).items

      expect(DailyReport.all).to have(31).items
    end

  end

  describe 'エラーテスト' do
    it '存在しない月を引数にするとエラーになる' do
      expect{DailyReport.get_daily_report('11111-1111', '1')}.to raise_error(ArgumentError)
    end

    it '引数をnilにするとエラーになる' do
      expect{DailyReport.get_daily_report(nil, nil)}.to raise_error(NoMethodError)
    end
  end
end

describe DailyReport ,'get_distinct_user' do
  describe '順次テスト' do
    before(:all) do
      self.use_transactional_fixtures = false
    end

    after(:all) do
      self.use_transactional_fixtures = true
    end

    it 'データがない状態でユーザを取得すると何も取得できない' do
      result_daily_report = DailyReport.get_distinct_user

      expect(result_daily_report).to have(0).items
    end

    it 'データを1つ追加すると取得できる' do
      FG.create(:daily_report_test011)

      result_daily_report = DailyReport.get_distinct_user

      expect(result_daily_report).to have(1).items
    end

    it '違うユーザのデータを1つ追加すると取得できる数が増える' do
      FG.create(:daily_report_test021)

      result_daily_report = DailyReport.get_distinct_user

      expect(result_daily_report).to have(2).items
    end

    it '同じユーザのデータを追加すると取得できる数が変わらない' do
      FG.create(:daily_report_test022)

      result_daily_report = DailyReport.get_distinct_user

      expect(result_daily_report).to have(2).items
    end
  end
end

describe DailyReport ,'update_daily_report' do
  it '数値を入力していると更新される' do
    target_daily_report = FG.create(:daily_report_test011)
    target_daily_report.succeeds = 2
    target_daily_report.gross_profits = 3
    target_daily_report.interviews = 4
    target_daily_report.new_meetings = 5
    target_daily_report.exist_meetings = 6
    target_daily_report.contact_matter = '変更連絡事項'

    target_data = Hash.new
    target_data['1'] = target_daily_report

    DailyReport.update_daily_report(target_data, '1')

    result_daily_report = DailyReport.all
    expect(result_daily_report).to have(1).items
    expect(result_daily_report[0].id).to eq(1)
    expect(result_daily_report[0].succeeds).to eq(2)
    expect(result_daily_report[0].gross_profits).to eq(3)
    expect(result_daily_report[0].interviews).to eq(4)
    expect(result_daily_report[0].new_meetings).to eq(5)
    expect(result_daily_report[0].exist_meetings).to eq(6)
    expect(result_daily_report[0].contact_matter).to eq('変更連絡事項')
    expect(result_daily_report[0].daily_report_input_type).to eq('existinput')
  end

  it '数値を全ての項目が入力されていないと更新されない' do
    target_daily_report = FG.create(:daily_report_test011)
    target_daily_report.succeeds = nil
    target_daily_report.gross_profits = nil
    target_daily_report.interviews = nil
    target_daily_report.new_meetings = nil
    target_daily_report.exist_meetings = nil
    target_daily_report.contact_matter = '変更連絡事項'

    target_data = Hash.new
    target_data['1'] = target_daily_report

    DailyReport.update_daily_report(target_data, '1')
    result_daily_report = DailyReport.all
    expect(result_daily_report).to have(1).items
    expect(result_daily_report[0].succeeds).to eq(1)
    expect(result_daily_report[0].gross_profits).to eq(1)
    expect(result_daily_report[0].interviews).to eq(1)
    expect(result_daily_report[0].new_meetings).to eq(1)
    expect(result_daily_report[0].exist_meetings).to eq(1)
    expect(result_daily_report[0].contact_matter).to eq('連絡事項')
    expect(result_daily_report[0].daily_report_input_type).to eq('notinput')
  end

  it '数値を入力していると更新される(user_idがない場合でも引数のuser_idで補完する)' do
    target_daily_report = FG.build(:daily_report_test011)
    target_daily_report.succeeds = 2
    target_daily_report.gross_profits = 3
    target_daily_report.interviews = 4
    target_daily_report.new_meetings = 5
    target_daily_report.exist_meetings = 6
    target_daily_report.contact_matter = '変更連絡事項'
    target_daily_report.id = ''

    target_data = Hash.new
    target_data['1'] = target_daily_report

    DailyReport.update_daily_report(target_data, '1')

    result_daily_report = DailyReport.all
    expect(result_daily_report).to have(1).items
    expect(result_daily_report[0].succeeds).to eq(2)
    expect(result_daily_report[0].gross_profits).to eq(3)
    expect(result_daily_report[0].interviews).to eq(4)
    expect(result_daily_report[0].new_meetings).to eq(5)
    expect(result_daily_report[0].exist_meetings).to eq(6)
    expect(result_daily_report[0].contact_matter).to eq('変更連絡事項')
    expect(result_daily_report[0].daily_report_input_type).to eq('existinput')
  end

  describe 'エラーテスト' do
    it '引数をnilにするとエラーになる' do
      expect{DailyReport.update_daily_report(nil, nil)}.to raise_error(NoMethodError)
    end
  end
end

describe DailyReport ,'get_summary_report' do
  def create_reports
    31.times do
      FG.create(:sequence_dates01)
      FG.create(:sequence_dates02)
      FG.create(:sequence_dates03)
    end
  end

  before(:all) do
    create_reports
  end

  describe '順次テスト' do

    before(:all) do
      self.use_transactional_fixtures = false
    end

    after(:all) do
      self.use_transactional_fixtures = true
    end

    it '集計期間:日次, 対象:なし, 集計方法:全体' do
      daily_report_summary = Hash.new
      daily_report_summary[:summary_term_flg] = 'day'
      daily_report_summary[:summary_target_flg] = nil
      daily_report_summary[:summary_method_flg] = 'summary'

      result_daily_report = DailyReport.get_summary_report(daily_report_summary, '2014-01')

      expect(result_daily_report.all).to have(31).items

      0.upto(30) do |n|
        expect(result_daily_report[n].succeeds).to eq(2)
        expect(result_daily_report[n].gross_profits).to eq(2)
        expect(result_daily_report[n].interviews).to eq(2)
        expect(result_daily_report[n].new_meetings).to eq(2)
        expect(result_daily_report[n].exist_meetings).to eq(2)
      end
    end

    it '集計期間:日次, 対象:なし, 集計方法:個別' do
      daily_report_summary = Hash.new
      daily_report_summary[:summary_term_flg] = 'day'
      daily_report_summary[:summary_target_flg] = nil
      daily_report_summary[:summary_method_flg] = 'individual'

      result_daily_report = DailyReport.get_summary_report(daily_report_summary, '2014-01')

      expect(result_daily_report.all).to have(62).items

      0.upto(61) do |n|
        expect(result_daily_report[n].succeeds).to eq(1)
        expect(result_daily_report[n].gross_profits).to eq(1)
        expect(result_daily_report[n].interviews).to eq(1)
        expect(result_daily_report[n].new_meetings).to eq(1)
        expect(result_daily_report[n].exist_meetings).to eq(1)

        if n < 31
          expect(result_daily_report[n].user_id).to eq(1)
        else
          expect(result_daily_report[n].user_id).to eq(2)
        end
      end
    end

    it '集計期間:日次, 対象:1, 集計方法:全体' do
      daily_report_summary = Hash.new
      daily_report_summary[:summary_term_flg] = 'day'
      daily_report_summary[:summary_target_flg] = '1'
      daily_report_summary[:summary_method_flg] = 'summary'

      result_daily_report = DailyReport.get_summary_report(daily_report_summary, '2014-01')

      expect(result_daily_report.all).to have(31).items

      0.upto(30) do |n|
        expect(result_daily_report[n].succeeds).to eq(1)
        expect(result_daily_report[n].gross_profits).to eq(1)
        expect(result_daily_report[n].interviews).to eq(1)
        expect(result_daily_report[n].new_meetings).to eq(1)
        expect(result_daily_report[n].exist_meetings).to eq(1)
      end
    end

    it '集計期間:日次, 対象:1, 集計方法:個別' do
      daily_report_summary = Hash.new
      daily_report_summary[:summary_term_flg] = 'day'
      daily_report_summary[:summary_target_flg] = '1'
      daily_report_summary[:summary_method_flg] = 'individual'

      result_daily_report = DailyReport.get_summary_report(daily_report_summary, '2014-01')

      expect(result_daily_report.all).to have(31).items

      0.upto(30) do |n|
        expect(result_daily_report[n].succeeds).to eq(1)
        expect(result_daily_report[n].gross_profits).to eq(1)
        expect(result_daily_report[n].interviews).to eq(1)
        expect(result_daily_report[n].new_meetings).to eq(1)
        expect(result_daily_report[n].exist_meetings).to eq(1)
        expect(result_daily_report[n].user_id).to eq(1)
      end
    end
  end

  describe 'エラーテスト' do
    it '引数の値が指定とは違う場合nilが返ってくる' do
      daily_report_summary = Hash.new
      daily_report_summary[:summary_term_flg] = 'other'
      daily_report_summary[:summary_target_flg] = 'other'
      daily_report_summary[:summary_method_flg] = 'other'

      result_daily_report = DailyReport.get_summary_report(daily_report_summary, '2014-01')

      expect(result_daily_report).to be_nil
    end

    it '対象の月のデータが存在しない場合空のリストが返ってくる' do
      daily_report_summary = Hash.new
      daily_report_summary[:summary_term_flg] = 'day'
      daily_report_summary[:summary_target_flg] = '1'
      daily_report_summary[:summary_method_flg] = 'summary'

      result_daily_report = DailyReport.get_summary_report(daily_report_summary, '9999-01')

      expect(result_daily_report.all).to have(0).items
    end
  end
end



