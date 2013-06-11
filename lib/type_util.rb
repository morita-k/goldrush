# -*- encoding: utf-8 -*-
module TypeUtil
  @@types = nil
  @@type_conditions = nil

  def TypeUtil.initTypes
    yaml_file = File.join(Rails.root,'config','types.yml')
    if File.exist?(yaml_file)
      TypeUtil.setTypes_offline(yaml_file)
    else
      TypeUtil.setTypes
    end
  end

  # 名称マスタの初期読み込み
  # @@types[:type_section][:type_key]で名称にアクセスできる
  def TypeUtil.setTypes
    types = Type.find(:all, :conditions => "deleted = 0 ", :order => " type_section, display_order1")
    @@types = Hash.new
    @@type_conditions = Hash.new
    types.each {|x|
      @@types[x.type_section] = Hash.new if @@types[x.type_section].nil?
      @@types[x.type_section][x.type_key] = x
      @@type_conditions[x.type_section] = Array.new if @@type_conditions[x.type_section].nil?
      @@type_conditions[x.type_section].push [x.long_name, x.type_key]
    }
  end
  
  def TypeUtil.setTypes_offline(yaml_file)
    yaml = YAML.load_file(yaml_file)
    @@types = Hash.new
    @@type_conditions = Hash.new
    yaml.each{|key,val|
      val.delete('id')
      x = Type.new(val)
      @@types[x.type_section] = Hash.new if @@types[x.type_section].nil?
      @@types[x.type_section][x.type_key] = x
      @@type_conditions[x.type_section] = Array.new if @@type_conditions[x.type_section].nil?
      @@type_conditions[x.type_section].push [x.long_name, x.type_key]
    }
  end


  def getTypes(section)
    TypeUtil.getTypeConditions(section)
  end

  def TypeUtil.getTypeConditions(section)
    # キャッシュデータの初期化
    initTypes unless @@types
    @@type_conditions[section] || []
  end

  def TypeUtil.getTypes(section)
    # キャッシュデータの初期化
    initTypes unless @@types
    @@types[section.to_s] || {}
  end
  
  # 名称オブジェクトを取得
  def getTypeObject(section, key)
    TypeUtil.getTypeObject(section, key)
  end

  def TypeUtil.getTypeObject(section, key)
    x = TypeUtil.getTypes(section.to_s)
    x[key.to_s]
  end

  # 区分名称を取得
  def getLongType(section, key, unknown = "Unknown type")
    TypeUtil.getLongType(section, key, unknown)
  end

  def TypeUtil.getLongType(section, key, unknown = "Unknown type")
    return unknown + "(#{key})" if key.blank?
    type = TypeUtil.getTypeObject(section, key)
    type.blank? ? unknown + "(#{key})" : type.long_name
  end

  # 区分略称を取得
  def getShortType(section, key)
    return '' if key.blank?
    if TypeUtil.getTypes(section).nil?
      "Unknown type(#{key})"
    else
      type = TypeUtil.getTypeObject(section, key)
      type.nil? ? "Unknown type(#{key})" : type.short_name
    end
  end

  # 区分その他の名前を取得
  def getOtherType(section, key)
    return '' if key.blank?
    if TypeUtil.getTypes(section).nil?
      "Unknown type(#{key})"
    else
      type = TypeUtil.getTypeObject(section, key)
      type.nil? ? "Unknown type(#{key})" : type.other_name
    end
  end

end
