# encoding: utf-8
# Commonly used webrat steps
# <a href="http://github.com/brynary/webrat" target="_blank" rel="noreferrer" style="cursor:help;display:inline !important;">http://github.com/brynary/webrat</a>

step ':buttonボタンをクリックする' do |button|
  click_button(button)
end

step ':linkリンクをクリックする' do |link|
  click_link(link)
end

step '再読み込みする' do
  visit request.request_uri
end

step ':target_pageに移動する' do |target_page|
  visit target_page
end

step ':fieldに:valueと入力する' do |field, value|
  fill_in(field, :with => value)
end

# opposite order from Engilsh one(original)
step ':fieldから:valueを選択' do |field, value|
  selects(value, :from => field)
end

step ':fieldをチェックする' do |field|
  checks(field)
end

step ':fieldのチェックを外す' do |field|
  unchecks(field)
end

step ':fieldを選択する' do |field|
  chooses(field)
end

# opposite order from Engilsh one(original)
step ':fieldとしてをファイル:pathを添付する' do |field, path|
  attaches_file(field, path)
end

step ':textと表示されていること' do |text|
  page.body.should =~ /#{Regexp.escape(text)}/m
end

step ':textと表示されていないこと' do |text|
  page.body.should_not =~ /#{text}/m
end

step ':labelがチェックされていること' do |label|
  field_labeled(label).should be_checked
end

step ':pageに移動していること' do |page|
  current_path.should == page
end

step 'ユーザをロードする' do
  ActiveRecord::Fixtures.reset_cache
  fixtures_folder = File.join(Rails.root, 'test', 'fixtures')
  ActiveRecord::Fixtures.create_fixtures(fixtures_folder, ['users','employees'])
end

step 'ログインする' do
  visit '/auth/sign_in'
  fill_in "auth[email]", :with => 'system@aaa.com'
  fill_in "auth[password]", :with => 'aaaaaa'
  click_button "ログイン"
end