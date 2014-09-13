# -*- encoding: utf-8 -*-
require 'spec_helper'

describe RemarksController do
  login_user

  describe 'List' do
    before do
      #@remark_1 = FG.create(:remark_1)
      #@remark_2 = FG.create(:remark_2)
      ##http://dev.applicative.jp/goldrush/remarks
      #get :index
    end
    
    it '@remarksを定義してリストを表示する' do
      #expect(assigns(:remarks).size).to eq 2
      #expect(assigns(:remarks).first).to eq @remark_1
      #expect(response).to eq render_template('index')
    end

  end

  describe 'New' do
    
    before do
      #get :new
    end
    
     it '新規作成画面を表示する' do
       #expect(response).to eq render_template('new')
     end

    describe 'Create' do
      before do
        #@remark_paramaters = {'remark_target_id' => 1, 'remark_key' => 'key', 'remark_content' => 'content_for_create'}
        #parameters = {remark: @remark_parametars, back_to: '/'}
        #post :create, parameters
      end
      
      it '新規作成をして一覧画面に戻る' do
        #expect(Remark.all.last.attributes).to include @remark_parameters
      end
      
    end

  end 

  describe 'Show' do
    before do
      #@remark_1 = FG.create(:remark_1)
      #get :show, {id => 1}
    end
    
    it 'id=1のデータを表示する' do
      #expect(assigns(:remark)).to eq @remark_1
      #expect(response).to eq render_template('show')
    end
  end

end