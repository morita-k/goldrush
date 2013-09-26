# language: ja
フィーチャ: 全画面表示テスト

シナリオ: ログイン画面
  もし"/auth/sign_in"に移動する
  かつ"/auth/password/new"に移動する
  かつ"/auth/password/edit"に移動する
  かつ"/auth/cancel"に移動する
  かつ"/auth/sign_up"に移動する
  かつ"/auth/edit"に移動する

シナリオ: ユーザ画面
  前提ユーザをロードする
  かつログインする
  もし"/users"に移動する
  かつ"/users/new"に移動する
  かつ"/users/1/edit"に移動する

シナリオ:タグ画面
  前提ユーザをロードする
  かつログインする
  もし"/tags"に移動する
  かつ"/tags/new"に移動する

シナリオ:メールテンプレート画面
  前提ユーザをロードする
  かつログインする
  もし"/mail_templates"に移動する
  かつ"/mail_templates/new"に移動する

シナリオ:リマーク画面
  前提ユーザをロードする
  かつログインする
  もし"/remarks"に移動する
  かつ"/remarks/new"に移動する

シナリオ:ホーム画面
  前提ユーザをロードする
  かつログインする
  もし"/home"に移動する

シナリオ:取引先担当グループ詳細画面
  前提ユーザをロードする
  かつログインする
  もし"/bp_pic_group_details"に移動する
  かつ"/bp_pic_group_details/new"に移動する
  
シナリオ:取引先担当グループ画面
  前提ユーザをロードする
  かつログインする
  もし"/bp_pic_groups"に移動する
  かつ"/bp_pic_groups/new"に移動する

シナリオ:名刺取込画面
  前提ユーザをロードする
  かつログインする
  もし"/photos/list"に移動する

シナリオ:配信メール画面
  前提ユーザをロードする
  かつログインする
  もし"/delivery_mails"に移動する
  かつ"/delivery_mails/new"に移動する
