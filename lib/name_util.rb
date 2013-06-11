# -*- encoding: utf-8 -*-
module NameUtil
  @@names = nil

  def NameUtil.initNames
    yaml_file = File.join(Rails.root,'config','names.yml')
    if File.exist?(yaml_file)
      NameUtil.setNames_offline(yaml_file)
    else
    NameUtil.setNames
    end
  end

  def NameUtil.setNames
    names = Name.find(:all, :conditions => "deleted = 0 ")
    @@names = Hash.new
    names.each {|x|
      @@names[x.name_section] = Hash.new if @@names[x.name_section].nil?
      @@names[x.name_section][x.name_key] = x
    }
  end

  def NameUtil.setNames_offline(yaml_file)
    yaml = YAML.load_file(yaml_file)
    @@names = Hash.new
    yaml.each {|key,val|
      val.delete('id')
      x = Name.new(val)
      @@names[x.name_section] = Hash.new if @@names[x.name_section].nil?
      @@names[x.name_section][x.name_key] = x
    }
  end

  def  NameUtil.getNames
    initNames unless @@names
    @@names
  end
  
  def getNameObject(section, key)
    if NameUtil.getNames[section.to_s].nil?
      nil
    else
      NameUtil.getNames[section.to_s][key.to_s]
    end
  end

  def getLongName(section, key)
    if NameUtil.getNames[section.to_s].nil?
      "Unknown name"
    else
      name = NameUtil.getNames[section.to_s][key.to_s]
      name.nil? ? "Unknown name" : name.long_name
    end
  end

  def self.getLongNameX(section, key)
    if NameUtil.getNames[section.to_s].nil?
      "Unknown name"
    else
      name = NameUtil.getNames[section.to_s][key.to_s]
      name.nil? ? "Unknown name" : name.long_name
    end
  end

  def getShortName(section, key)
    if NameUtil.getNames[section.to_s].nil?
      "Unknown name"
    else
      name = NameUtil.getNames[section.to_s][key.to_s]
      name.nil? ? "Unknown name" : name.short_name
    end
  end

  def getOtherName(section, key)
    if NameUtil.getNames[section.to_s].nil?
      "Unknown name"
    else
      name = NameUtil.getNames[section.to_s][key.to_s]
      name.nil? ? "Unknown name" : name.other_name
    end
  end

end
