# -*- encoding: utf-8 -*-

module StringUtil
  # 全角トリム
  def StringUtil.strip_with_full_size_space(str)
    s = "　 \t\r\n\f\v"
    str.sub(/^[#{s}]*(.*)/o, '\1').reverse.sub(/^[#{s}]*(.*)/o, '\1').reverse
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
    "test+" + email.sub("@","_") + "@i.applicative.jp"
  end
  
  def StringUtil.detect_words(str)
    words = []
    r = Regexp.new(/[a-zA-Z][a-zA-Z0-9 ]+/)
    pos = 0
    while ma = r.match(str, pos)
      words << ma[0]
      pos = ma.offset(0)[1]
    end
    words.uniq.sort
  end
end
