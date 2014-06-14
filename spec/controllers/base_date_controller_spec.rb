# -*- encoding: utf-8 -*-
require 'spec_helper'

describe BaseDateController do
  login_user

  before(:all) do
  end

  describe 'リスト画面を取得する' do

    context 'get index' do
      it '空のリストを取得する' do
        get :index
        expect(response).to be_success
        expect(response).to render_template("list")

        expect(assigns(:base_dates)).to have(0).items
      end

      it '平日が1件作成された場合、0件のリストを取得する' do
        FG.create(:base_date_non_holiday)

        get :index
        expect(response).to be_success
        expect(response).to render_template("list")
        base_dates_list = assigns(:base_dates)
        expect(base_dates_list).to have(0).items
      end

      it '祝日が1件作成された場合、1件のリストを取得する' do
        FG.create(:base_date_holiday1)

        get :index
        expect(response).to be_success
        expect(response).to render_template("list")
        base_dates_list = assigns(:base_dates)
        expect(base_dates_list).to have(1).items
      end

      it '祝日が複数件作成された場合、カレンダー日付降順に取得する' do
        FG.create(:base_date_holiday1)
        FG.create(:base_date_holiday2)
        FG.create(:base_date_holiday3)

        get :index
        expect(response).to be_success
        expect(response).to render_template("list")
        base_dates_list = assigns(:base_dates)
        expect(base_dates_list[0].calendar_date).to be > base_dates_list[1].calendar_date
        expect(base_dates_list[1].calendar_date).to be > base_dates_list[2].calendar_date
      end
    end
  end

  describe '詳細画面を取得する' do
    context 'get show' do
      it '対象を取得する' do
        holiday1 = FG.create(:base_date_holiday1)
        get :show, :id => holiday1.id

        expect(response).to be_success
        expect(response).to render_template("show")
        base_date = assigns(:base_date)
        expect(base_date.id).to eq holiday1.id
      end

      it '対象のIdが不正な場合エラーが発生する' do
        expect{get :show, :id => '999'}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '新規作成画面を取得する' do
    context 'get new' do
      it '対象を取得する' do
        get :new

        expect(response).to be_success
        expect(response).to render_template("new")
        base_date = assigns(:base_date)
        expect(base_date.id).to eq nil
      end
    end
  end

  describe '編集画面を取得する' do
    context 'get edit' do
      it '対象を取得する' do
        holiday1 = FG.create(:base_date_holiday1)
        get :edit, :id => holiday1.id

        expect(response).to be_success
        expect(response).to render_template("edit")
        base_date = assigns(:base_date)
        expect(base_date.id).to eq holiday1.id
      end

      it '対象のIdが不正な場合エラーが発生する' do
        expect{get :edit, :id => '999'}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '祝日を作成する' do
    context 'post create_holiday' do
      it '対象を祝日に更新する' do
        non_holiday = FG.create(:base_date_non_holiday)
        param = {:calendar_date => '2014/12/31', :comment1 => '祝日に更新', :lock_version => 0}
        post :create_holiday, :base_date => param
        
        base_date = assigns(:base_date)
        expect(response).to redirect_to(:action => 'list')
        expect(base_date.id).to eq non_holiday.id
        expect(base_date.calendar_date.strftime('%Y/%m/%d')).to eq param[:calendar_date]
        expect(base_date.comment1).to eq param[:comment1]
        expect(base_date.holiday_flg).to eq 1
      end
    end
  end

  describe '祝日を更新する' do
    context 'post update' do
      it '対象を更新する' do
        holiday1 = FG.create(:base_date_holiday1)
        holiday1.comment1 = 'コメント更新'
        post :update, :base_date => holiday1.attributes, :id => holiday1.id

        base_date = assigns(:base_date)
        expect(response).to redirect_to(:action => 'show', :id => base_date.id)
        expect(base_date.id).to eq holiday1.id
        expect(base_date.comment1).to eq holiday1.comment1
      end

      it '対象のIdが不正な場合エラーが発生する' do
        expect{post :update, :id => '999'}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '祝日を平日に戻す' do
    context 'post destroy_holiday' do
      it '対象を平日に更新する' do
        holiday1 = FG.create(:base_date_holiday1)
        post :destroy_holiday, :id => holiday1.id

        base_date = BaseDate.find(holiday1.id, :conditions => "deleted = 0 ")
        expect(response).to redirect_to(:action => 'list')
        expect(base_date.holiday_flg).to eq 0
        expect(base_date.comment1).to eq ''
      end

      it '対象のIdが不正な場合エラーが発生する' do
        expect{post :destroy_holiday, :id => '999'}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
