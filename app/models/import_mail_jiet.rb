# -*- encoding: utf-8 -*-

class ImportMailJIET < ImportMail

  #=====
  # JIETメール解析処理のメイン
  # 考え方:
  #   インデントによって内容をまとめ、整形する
  #   解析結果から案件照会人材所属を作成
  #=====
  def ImportMailJIET.analyze_jiet_offer(mail)
    logger.info "start analyze_jiet_offer method. message_id: #{mail.message_id}"

    # ハッシュ化して署名部分を取り除き、案件照会を作成する
    offers = ImportMailJIET.jiet_mail_parse(mail.mail_body)
    offers.each{|offer| 
      offer["会社名"] = ImportMailJIET.trimming_name(offer["会社名"])
      exist_bp = BusinessPartner.where(owner_id: mail.owner_id, business_partner_name: offer["会社名"], deleted: 0).first

      if exist_bp.nil?
        target_bp, target_pic = ImportMailJIET.create_bp_and_bp_pic(mail.owner_id, mail.id, offer)
      elsif exist_bp.bp_pics.blank?
        target_bp = exist_bp
        target_pic = ImportMailJIET.create_bp_pic(mail.owner_id, mail.id, exist_bp.id)
      else
        target_bp = exist_bp

        # とりあえず一番最初に登録されている担当者を紐付ける
        target_pic = exist_bp.bp_pics.first
      end
      
      ImportMailJIET.create_business_and_biz_offer(mail.owner_id, mail.received_at, offer, target_bp.id, target_pic.id, mail.id)
    }

    logger.info "finish analyze_jiet_offer method. message_id: #{mail.message_id}"
  end
  
  def ImportMailJIET.analyze_jiet_human(mail)
    logger.info "start analyze_jiet_human method. message_id: #{mail.message_id}"

    # ハッシュ化して署名部分を取り除き、人材所属を作成する
    humans = ImportMailJIET.jiet_mail_parse(mail.mail_body)
    humans.each{|human|
      human["会社名"] = ImportMailJIET.trimming_name(human["会社名"])
      exist_bp = BusinessPartner.where(owner_id: mail.owner_id, business_partner_name: human["会社名"], deleted: 0).first

      if exist_bp.nil?  
        target_bp, target_pic = ImportMailJIET.create_bp_and_bp_pic(mail.owner_id, mail.id, human)
      elsif exist_bp.bp_pics.blank?
        target_bp = exist_bp
        target_pic = ImportMailJIET.create_bp_pic(mail.owner_id, mail.id, exist_bp.id)
      else
        target_bp = exist_bp

        # とりあえず一番最初に登録されている担当者を紐付ける
        target_pic = exist_bp.bp_pics.first
      end

      # 人材所属限定の加工処理
      human["性別"], human["年齢"] = human["性別（年齢）"].scan(/(.*)\((.*)\)/).first unless human["性別（年齢）"].nil?

      human["社員区分"] = ImportMailJIET.to_employment_type(human["社員区分"])
      human["性別"] = ImportMailJIET.to_sex_type(human["性別"])
      human["年齢"] = HumanResource.normalize_age(human["年齢"])

      ImportMailJIET.create_human_resource_and_bp_member(mail.owner_id, human, target_bp.id, target_pic.id, mail.id)
    }

    logger.info "finish analyze_jiet_human method. message_id: #{mail.message_id}"
  end
  
  #=====
  # JIETメール解析用ヘルパー
  #=====
  def ImportMailJIET.jiet_mail_parse(mail_body)
    # todo: sysconfigから取得出来るようにする
    separator = /-----*/
    items = mail_body.split(Regexp.new(separator))
    jiet_mail_item_list = []

    # メイン解析処理
    items.map{|item|
      jiet_mail_item = {}
      ImportMailJIET.group_by_indent(item.split("\n")).reject{|s| s == ""}.flat_map{|s|
        s.scan(/(.*?)[\s　]*?：[\s　]*?([\s\S]*)/)
      }.each{|arr|
        jiet_mail_item[arr[0]] = arr[1].chop
      }
      jiet_mail_item_list.push(jiet_mail_item)
    }

    # 署名部分をparseした結果の空ハッシュを削除
    jiet_mail_item_list.reject{|item| item == {}}
    # Valueの末尾改行を削除
  end
  
  def ImportMailJIET.create_bp_and_bp_pic(owner_id, import_mail_id, mail)
    bp = BusinessPartner.new
    mail["会社名"] = ImportMailJIET.trimming_name(mail["会社名"])
    bp.attributes = {
      owner_id: owner_id,
      business_partner_name: mail["会社名"],
      business_partner_short_name: mail["会社名"],
      business_partner_name_kana: mail["会社名"],
      sales_status_type: "listup",
      basic_contract_first_party_status_type: "none",
      basic_contract_second_party_status_type: "none",
      url: mail["URL"],
      category: mail["業種"],
      import_mail_id: import_mail_id
    }.reject{|k, v| v.blank?}

    bp.save!

    # 取引先担当者も同時に作成する
    pic = ImportMailJIET.create_bp_pic(owner_id, import_mail_id, bp.id)

    [bp, pic]
  end
  
  def ImportMailJIET.create_bp_pic(owner_id, import_mail_id, bp_id)
    pic = BpPic.new
    pic.attributes = {
      owner_id: owner_id,
      business_partner_id: bp_id,
      bp_pic_name: "ご担当者",
      bp_pic_short_name: "ご担当者",
      bp_pic_name_kana: "ご担当者",
      email1: "unknown+#{bp_id}@unknown.applicative.jp",
      import_mail_id: import_mail_id,
      jiet: 1,
      working_status_type: 'working'
    }.reject{|k, v| v.blank?}

    pic.save!

    pic
  end
  
  def ImportMailJIET.create_business_and_biz_offer(owner_id, received_at, offer, business_partner_id, bp_pic_id, import_mail_id)
    business = Business.new
    business.attributes = {
      owner_id: owner_id,
      business_status_type: "offered",
      issue_datetime: received_at,
      term_type: "suspense",
      business_title: offer["案件概要"],
      business_point: offer["業種"],
      place: ImportMailJIET.linefeed_join(offer["作業地域"], offer["作業場所"]),
      period: offer["参入時期"],
      skill_title: offer["職務"],
      skill_must: ImportMailJIET.linefeed_join(offer["ＯＳ"],offer["ＤＢ"],offer["言語"],offer["ハードウェア"],offer["ネットワーク"],offer["ツール"],offer["フレームワーク"]),
      career_years: offer["経験年数"],
      age_limit: offer["年齢範囲"],
      nationality_limit: offer["国籍"],
      link: offer["リンク"],
      memo: ImportMailJIET.linefeed_join(offer["作業形態"],offer["コメント"])
    }.reject{|k, v| v.blank?}

    business.save! if business.new_record? # 新規だった場合、スキルタグ生成の為に一時保存
    business.make_skill_tags!
    business.save!

    biz_offer = BizOffer.new
    biz_offer.attributes = {
      owner_id: owner_id,
      business_id: business.id,
      business_partner_id: business_partner_id,
      bp_pic_id: bp_pic_id,
      biz_offer_status_type: "open",
      biz_offered_at: received_at,
      payment_text: offer["予算"],
      sales_route_limit: offer["社員区分"],
      import_mail_id: import_mail_id
    }.reject{|k, v| v.blank?}

    biz_offer.convert!
    biz_offer.save!
  end

  def ImportMailJIET.create_human_resource_and_bp_member(owner_id, human, business_partner_id, bp_pic_id, import_mail_id)
    hr = HumanResource.new
    hr.attributes = {
      owner_id: owner_id,
      initial: "JIET",
      age: human["年齢"],
      sex_type: human["性別"],
      nationality: human["国籍"],
      near_station: human["最寄り駅"],
      experience: human["経験年数"],
      skill_title: human["職務"],
      skill: ImportMailJIET.linefeed_join(human["ＯＳ"],human["ＤＢ"],human["言語"],human["ハードウェア"],human["ネットワーク"],human["ツール"],human["フレームワーク"]),
      communication_type: "unknown",
      human_resource_status_type: "sales",
      jiet: 1,
      link: human["リンク"],
      memo: ImportMailJIET.linefeed_join(human["希望作業場所"],human["コメント"])
    }.reject{|k, v| v.blank?}

    hr.save! if hr.new_record? # 新規だった場合、スキルタグ生成の為に一時保存
    hr.make_skill_tags!
    hr.save!

    bp_member = BpMember.new
    bp_member.attributes = {
      owner_id: owner_id,
      human_resource_id: hr.id,
      business_partner_id: business_partner_id,
      bp_pic_id: bp_pic_id,
      employment_type: human["社員区分"],
      can_start_date_memo: human["稼動可能日"],
      payment_memo: human["単価"],
      import_mail_id: import_mail_id,
      memo: ImportMailJIET.linefeed_join(human["人財概要"], human["作業希望形態"])
    }.reject{|k, v| v.blank?}

    bp_member.convert!
    bp_member.save!
  end
  
  #
  # Helper's Helper
  #
  def ImportMailJIET.linefeed_join(*items)
    items.reject{|s| s == ""}.join("\n")
  end
 
  def ImportMailJIET.group_by_indent(list)
    item = ""
    grouped_items = []

    # インデントをもとに各項目をまとめる
    list.each { |str|
      list_head = str[0]
      if list_head =~ /[\t\s　]/
        item += str.strip + "\n"
      else 
        grouped_items.push(item)
        item = str + "\n"
      end
    }
    grouped_items.push(item) # ループで漏れる末端要素の追加
  end
  
  def ImportMailJIET.trimming_name(str)
    str.gsub(/[\s　\n]/, "")
  end
  
  def self.to_employment_type(mail_employment_type)
    case mail_employment_type
    when /正社員/
      "permanent"
    when /契約社員/
      "temporary"
    when /個人/ # メール内容として存在するか不明 13.07.23現在
      "freelance"
    else
      "unknown"
    end
  end
  
  def self.to_sex_type(mail_sex_type)
    # 「その他」の判定が難しいので不明と同一視する。
    case mail_sex_type
      when /男性/
        "man"
      when /女性/
        "woman"
      else
        "unknown"
      end
  end

=begin
  BUSINESS_TAG = [
    "会社名",
    "URL",
    "案件概要",
    "作業形態",
    "作業地域",
    "作業場所",
    "ＯＳ",
    "ＤＢ",
    "言語",
    "ハードウェア",
    "ネットワーク",
    "ツール",
    "フレームワーク",
    "参入時期",
    "年齢範囲",
    "予算",
    "社員区分",
    "国籍",
    "業種",
    "職務",
    "経験年数",
    "コメント",
    "リンク"
  ]

  HUMAN_TAG = [
    "会社名",
    "URL",
    "人財概要",
    "性別（年齢）",
    "社員区分",
    "作業希望形態",
    "希望作業場所",
    "ＯＳ",
    "ＤＢ",
    "言語",
    "ハードウェア",
    "ネットワーク",
    "ツール",
    "フレームワーク",
    "稼動可能日",
    "国籍",
    "単価",
    "業種",
    "職務",
    "経験年数",
    "最寄り駅",
    "コメント",
    "リンク"
  ]
=end

end
