# -*- encoding: utf-8 -*-

module StringUtil
  DETECT_WORD_REGEXP = Regexp.new(/[a-zA-Z][a-zA-Z0-9\.+\-# ]+/)
  FULLSPACE_TRIM_REGEXP = Regexp.new(/^[　 \t\r\n\f\v]*(.*)/o)
  # 全角トリム
  def StringUtil.strip_with_full_size_space(str)
    str.sub(FULLSPACE_TRIM_REGEXP, '\1').reverse.sub(FULLSPACE_TRIM_REGEXP, '\1').reverse
  end

  def StringUtil.hancut(str, bytes)
    arr = str.split(//)
    res = ""
    idx = 0
    arr.each{|x|
      break if idx >= bytes
      res << x
      idx += 1
    }
    res
  end
  def StringUtil.zencut(str, bytes)
    # SJISで数える
    $KCODE = 's'
    begin
      arr = str.tosjis.split(//)
      res = ""
      arr.each{|x|
#puts ">>>>>>>" + res.length.to_s + ' ' + x.length.to_s
        break if (res.length + x.length) > bytes
        res << x
      }
    ensure
      $KCODE = 'u'
    end
    return res.toutf8
  end

  def StringUtil.zencuts(str, bytes)
    # SJISで数える
    $KCODE = 's'
    begin
      arr = str.tosjis.split(//)
      res  = ""
      res2 = ""
      
      arr.each{|x|
#puts ">>>>>>>" + res.length.to_s + ' ' + x.length.to_s
        if (res.length + x.length) > bytes
          res2 << x
        else
          res << x
        end
      }
    ensure
      $KCODE = 'u'
    end
    return res.toutf8, res2.toutf8
  end

  def StringUtil.split_name(full_name)
    if full_name =~ /[ 　]/
      return $`, $'
    else
      return full_name, ""
    end
  end
  
  def StringUtil.to_test_address(email)
    "test+" + email.sub("@","_") + "@i.applicative.jp" unless email.blank?
  end
  
  def StringUtil.detect_words(str)
    r = DETECT_WORD_REGEXP
    StringUtil.detect_regex(str, r)
  end

  def StringUtil.detect_regex(str, r)
    words = []
    pos = 0
    while ma = r.match(str, pos)
      words << ma[0]
      pos = ma.offset(0)[1]
    end
    words.map{|x| x.strip}.uniq.sort
  end
  
  def StringUtil.constructs(arr)
    return [] if arr.empty?
    res = []
    arr.each do |x|
      if res.empty?
        res << [x]
      else
        l = res.last
        res << (l + [x])
      end
    end
    [res] + splits(arr[1..-1])
  end

  # 英字の連続と数字を区切る(Oracle10g -> [Oracle, 10g])。
  # 条件にhitしなければ、[]
  def StringUtil.splitnum(str)
    if str =~ /^([a-zA-Z]+)(\d.*)/
      return [$1,$2]
    else
      return []
    end
  end

  def StringUtil.breaknum(str)
    r = splitnum(str)
    r.empty? ? [str] : [str, r[0]]
  end

  # +で区切るただし、2個以上の+は無視(C++のため)
  def StringUtil.splitplus(str)
    plus = ""
    word = ""
    arr = []
    str.split(//).each do |x|
      if x == "+"
        plus += x
      else
        if plus == "+"
          plus = ""
          arr << word
          word = x
        elsif plus.blank?
          word += x
        else
          word = word + plus + x
          plus = ""
        end
      end
    end
    arr << (word + plus)
  end
end
