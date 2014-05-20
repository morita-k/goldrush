# -*- encoding: utf-8 -*-
require 'spec_helper'

describe SpecialWordsController do
  login_user

  before(:all) do
    FG.create(:Employee)
  end

  describe 'リスト画面を取得する' do

    context 'get index' do
      it '何も作成されていないので空のリストを取得する' do
        get :index
        expect(response).to be_success
        expect(response).to render_template("index")

        expect(assigns(:special_words)).to have(0).items
      end

      it '1個作成された場合1個のリストを取得する' do
        FG.create(:special_words_test011)

        get :index
        expect(response).to be_success
        expect(response).to render_template("index")

        special_words_list = assigns(:special_words)
        expect(special_words_list).to have(1).items

      end

      it '複数作成された場合複数のリストを取得する' do
        FG.create(:special_words_test011)
        FG.create(:special_words_test021)
        FG.create(:special_words_test031)

        get :index
        expect(response).to be_success
        expect(response).to render_template("index")

        special_words_list = assigns(:special_words)
        expect(special_words_list).to have(3).items

      end
    end
  end

  describe '詳細画面を取得する' do
    context 'get show' do
      it '対象を取得する' do
        special_words_test011 = FG.create(:special_words_test011)
        get :show, :id => special_words_test011.id

        expect(response).to be_success
        expect(response).to render_template("show")
        special_word = assigns(:special_word)
        expect(special_word.id).to eq special_words_test011.id
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
        special_word = assigns(:special_word)
        expect(special_word.id).to eq nil
      end
    end
  end

  describe '編集画面を取得する' do
    context 'get edit' do
      it '対象を取得する' do
        special_words_test011 = FG.create(:special_words_test011)
        get :edit, :id => special_words_test011.id

        expect(response).to be_success
        expect(response).to render_template("edit")
        special_word = assigns(:special_word)
        expect(special_word.id).to eq special_words_test011.id
      end

      it '対象のIdが不正な場合エラーが発生する' do
        expect{get :edit, :id => '999'}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'special_wordを作成する' do
    context 'post create' do
      it '対象を作成する' do
        special_words_test011 = FG.build(:special_words_test011)
        post :create, :special_word => special_words_test011.attributes

        special_word = assigns(:special_word)
        expect(response).to redirect_to(:action => 'show', :id => special_word.id)
        expect(special_word.id).not_to eq special_words_test011.id
      end
    end
  end

  describe 'special_wordを更新する' do
    context 'post update' do
      it '対象を更新する' do
        special_words_test011 = FG.create(:special_words_test011)
        special_words_test011.memo = 'modify_memo'
        post :update, :special_word => special_words_test011.attributes , :id => special_words_test011.id

        special_word = assigns(:special_word)
        expect(response).to redirect_to(:action => 'show', :id => special_word.id)
        expect(special_word.id).to eq special_words_test011.id
        expect(special_word.memo).to eq 'modify_memo'
      end
    end
  end

  describe 'special_wordを削除する' do
    context 'post destroy' do
      it '対象を削除する' do
        special_words_test011 = FG.create(:special_words_test011)
        post :destroy, :id => special_words_test011.id

        expect(response).to redirect_to(:action => 'index')

        special_word = assigns(:special_word)
        expect(special_word.deleted).to eq 9
      end

      it '対象のIdが不正な場合エラーが発生する' do
        expect{post :destroy, :id => '999'}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end