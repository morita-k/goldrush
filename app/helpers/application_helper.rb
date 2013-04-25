# -*- encoding: utf-8 -*-
require 'string_util'
require 'name_util'
require 'type_util'
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include NameUtil
  include TypeUtil

  def _time(time)
    if time.blank?
      ""
    elsif [ActiveSupport::TimeWithZone, Time, Date].include?(time.class)
      t = time.to_time.getlocal
      if t.today?
        t.strftime("%H:%M")
      else
        t.strftime("%Y/%m/%d")
      end
    else
      time
    end
  end

  def _time_long(time)
    if time.blank?
      ""
    elsif [ActiveSupport::TimeWithZone, Time, Date].include?(time.class)
      t = time.to_time.getlocal.strftime("%Y/%m/%d %H:%M:%S")
    else
      time
    end
  end

  def logged_in?
    auth_signed_in?
  end

  def current_user
    current_auth
  end

  def show_default_initial_amount(x)
    over_super? ? x : '※ 表示できません'
  end

  def over_super?
    logged_in? && ['super'].include?(current_user.access_level_type)
  end

  def over_account?
    logged_in? && ['super','account'].include?(current_user.access_level_type)
  end

  def over_normal?
    logged_in? && ['super','account','normal'].include?(current_user.access_level_type)
  end


  def edit?
    ["edit","update"].include?(controller.action_name)
  end

  def edit_detail?
    controller.action_name == 'edit_detail'
  end

  def currency_field(object_name, method, options = {})
    options[:style] = options[:style].to_s + ";text-align: right;"
    options[:onblur] = "this.value=fnum(this.value);this.style.textAlign='right'"
    options[:onFocus] = "if(this.readOnly==false){this.value=ufnum(this.value);this.style.textAlign='left'}"
    if o = eval("@#{object_name}")
      if val = (o.respond_to?(method) && o.send(method))
        options[:value] = money_format(val.to_i)
      end
    end
    text_field(object_name, method, options)
  end

  def currency_field_tag(name, value = nil, options = {}) 
    options[:style] = options[:style].to_s + ";text-align: right;"
    options[:onblur] = "this.value=fnum(this.value);this.style.textAlign='right'"
    options[:onFocus] = "if(this.readOnly==false){this.value=ufnum(this.value);this.style.textAlign='left'}"
    text_field_tag(name, money_format(value), options)
  end

=begin
  def date_field(object_name, method, options = {})
    cal = "cal_#{object_name}_#{method}"
    flg = "flg_cal_#{object_name}_#{method}"
    result = <<EOS
<script type="text/javascript"><!--
  var #{cal} = new JKL.Calendar('#{cal}','#{options[:formid]}','#{object_name}[#{method}]');
  var #{flg} = true;
//-->
</script>
EOS
    options[:onChange] = "#{cal}.getFormValue(); #{cal}.hide();"
    options[:onClick] = "if(!this.readOnly){offsetCalendar($('#{cal}'), this); #{cal}.write();}"
    options[:size] = 15 unless options[:size]
    options[:onblur] = "if (#{flg}) {#{cal}.hide();}"
    if o = eval("@#{object_name}")
      if val = (o.respond_to?(method) && o.send(method))
        options[:value] = val.to_date
      end
    end
    result << text_field(object_name, method, options)
    result << "<span id='#{cal}' onmouseover='#{flg} = false;' onmouseout='#{flg} = true;' ></span>"
    return result
  end
=end

  def date_field(object_name, method, options = {})
    
    #date = Time.now.strftime("%Y/%m/%d")
    options['data-provide'] = "typeahead"
    options['class'] = [options['class'], "date-time-picker"].compact.join(" ")

    result = <<EOS
     <script type="text/javascript">
        // <![CDATA[
        jQuery(function () {
            jQuery('.typeahead').typeahead()
        });
        // ]]>
      </script>
      #{text_field object_name, method, options}
      <script>
        jQuery(function() {
        //テキストボックスにカレンダーをバインドする（パラメータは必要に応じて）
        jQuery("##{object_name}_#{method}").datepicker({
          firstDay: 1,    //週の先頭を月曜日にする（デフォルトは日曜日）
          dateFormat: 'yy/mm/dd',        

       //年月をドロップダウンリストから選択できるようにする場合
       changeYear: false,
       changeMonth: false,
EOS

    if("#{object_name}_#{method}" == "expense_application_preferred_date")
      result += <<EOS
        beforeShow: function(input, inst){
          inst.dpDiv.css({marginTop: -260 + 'px'});
        },
EOS
    else
      result += <<EOS
        beforeShow: function(input, inst){
          inst.dpDiv.css({marginTop: 0 + 'px'});
        },

EOS
    end

    result += <<EOS
           });
         });
       </script>
EOS
    return raw result;
  end

  def datetime_field(object_name, method, options = {})
    value = instance_variable_get("@#{object_name}").send(method)
    time_str = value && (value.is_a?(DateTime)||value.is_a?(Time)) && value.strftime('%H:%M') || ''
    date_field(object_name, method, options) + " " + text_field_tag("#{object_name}_#{method}_time", time_str, :size => 10)
  end

=begin
  def date_field_tag(name, value = nil, options = {})
    cal = "cal_#{name}"
    flg = "flg_cal_#{name}"
    result = <<EOS
<script type="text/javascript"><!--
  var #{cal} = new JKL.Calendar('#{cal}','#{options[:formid]}','#{name}');
  var #{flg} = true;
//-->
</script>
EOS
    options[:onChange] = "#{cal}.getFormValue(); #{cal}.hide();"
    options[:onClick] = "if(!this.readOnly){offsetCalendar($('#{cal}'), this); #{cal}.write();}"
    options[:size] = 15 unless options[:size]
    options[:onblur] = "if (#{flg}) {#{cal}.hide();}"
    result << text_field_tag(name, value, options)
    result << "<span id='#{cal}' onmouseover='#{flg} = false;' onmouseout='#{flg} = true;' ></span>"
    return result
  end
=end

  def date_field_tag(name, value = nil, options = {})
       result = <<EOS
     <script type="text/javascript">
        // <![CDATA[
        jQuery(function () {
            jQuery('.typeahead').typeahead()
        });
        // ]]>
      </script>
      <input id="#{name}" name="#{name}" type="text" data-provide="typeahead" />
      <script>
        jQuery(function() {
        //テキストボックスにカレンダーをバインドする（パラメータは必要に応じて）
        jQuery("##{name}").datepicker({
          firstDay: 1,    //週の先頭を月曜日にする（デフォルトは日曜日）
          dateFormat: 'yy/mm/dd',
          prevText: '<<',
          nextText: '>>',

          //年月をドロップダウンリストから選択できるようにする場合
          changeYear: false,
          changeMonth: false,

         });
       });
      </script>
EOS
    return raw result;

  end

  def getDayOfWeek(date)
    getDayOfWeekDay(date.wday)
  end

  def getDayOfWeekDay(wday)
    arr = ["日","月","火","水","木","金","土"]
    arr[wday]
  end

  # カラム名を受け取ってそれがシステムカラムなのかを返す
  def system_column?(column)
    SysConfig.system_column?(column)
  end
  
  def getFlgName(flg)
    flg == 0 ? 'なし' : 'あり'
  end

  # text_fieldにTimestamp型の属性を渡すと、DBから帰ってきた文字列をそのまま表示してしまう。
  # その為、内部で保持している属性情報を「DBから帰ってきた文字列」から「Time型」に変換する必要がある。
  # ちなみに、「DBから返ってきた文字列」は、object.method.before_type_castで見ることができる。内部では
  # このmethodを多用しているようだ。
  def time_text_field(object_name, method, options = {})
    if v = self.instance_variable_get("@#{object_name}")
      tmp = self.instance_variable_get("@#{object_name}").send(method) if v.respond_to?(method)
      v.send(method + '=', tmp) if tmp.class == Time
    end
    text_field(object_name, method, options)
  end

  # put_paginatesで使う関数
  def each_pages(pages, &block)
    st = (pages.current.to_i - 4)
    ed = (st + 10)
    st = st < 1 ? 1 : st
    ed = ed > pages.page_count ? pages.page_count : ed
    (st..ed).each do |x|
      yield x
    end
  end

  # Paginateタグ一式を出力する
  def put_paginates(pages, css_class = 'paginate', total_count = 0)
    "<div class='#{css_class}'>#{put_paginates_span(pages, css_class, total_count)}</div>"
  end
  
  def put_paginates_prefix(pages, css_class = 'paginate', total_count = 0, urlstr = nil)
    "<div class='#{css_class}'>#{put_paginates_span_prefix(pages, css_class, total_count, urlstr)}</div>"
  end
  
  def put_paginates_span(pages, css_class = 'paginate', total_count = 0)
    put_paginates_span_prefix(pages, css_class, total_count, request.env['REQUEST_URI'])
  end

  # Paginateタグ一式を出力する
  def put_paginates_span_prefix(pages, css_class, total_count, urlstr) # url_for(:kyoten_cd => ?, :eigyotancd => ?)
    # url_forがroutes.rbの絡みで不思議な踊りを踊るので、自力でURL生成(涙)
    urlstr =~ /\?/
    prefix = $` || urlstr
    suffix = $'.to_s.gsub(/\&*page=\d+/,'')
    prefix = prefix + '?' + (suffix.blank? ? 'page=' : suffix + '&page=')

    first = pages.current.first? ? '<<最新' : link_to('<<最新', prefix + pages.first_page.to_i.to_s)
    prev = pages.current.previous ? link_to('<前', prefix + pages.current.previous.to_i.to_s) : '<前'
    numbers = ""
    each_pages(pages) { |x|
      numbers += ' ' + (pages.current.to_i == x.to_i ? x.to_s : link_to(x, prefix + x.to_s))
    }
    nex = (pages.current.next ? link_to('次>', prefix + pages.current.next.to_i.to_s) : '次>')
    last = pages.current.last? ? '最後>>' : link_to('最後>>', prefix + pages.last_page.to_i.to_s)

    total_count_str = total_count == 0 ? '' : " total: #{total_count}"

    "<span class='paginate_span'>#{first} #{prev} #{numbers} #{nex} #{last} #{total_count_str}</span>"
  end

  def put_textarea_size_change(eid)
    <<EOS
<a class="size_change" href="#" tabindex="-1" onClick="e = $('#{eid}');e.setAttribute('cols',45);e.setAttribute('rows',3);return false;">45x3</a> 
<a class="size_change" href="#" tabindex="-1" onClick="e = $('#{eid}');e.setAttribute('cols',80);e.setAttribute('rows',20);return false;">80x20</a> 
<a class="size_change" href="#" tabindex="-1" onClick="e = $('#{eid}');e.setAttribute('cols',100);e.setAttribute('rows',40);return false;">100x40</a>
EOS
  end
  
  def support_over_color(attend)
    if attend.support_end_date.class == Date && attend.support_end_date < Date.today
      "style='background-color: silver;'"
    end
  end

  def resizable_area(object_name, method, options = {})
#    options[:size] = '45x3' if options[:size].blank?
#    raw(put_textarea_size_change(object_name + '_' + method) + "<br/>\n" + text_area(object_name, method, options))
    
    options[:style] = ';width: 80%;height: 6em' if options[:style].blank?
    text_area(object_name, method, options)
  end

  def resizable_area_tag(name, value = nil, options = {})
    options[:size] = '45x3' if options[:size].blank?
    raw(put_textarea_size_change(name) + "<br/>\n" + text_area_tag(name, value, options))
  end

  
  def money_format_i(num)
    money_format(num.to_i)
  end

  def money_format(num)
    return (num.to_s =~ /[-+]?\d{4,}/) ? (num.to_s.reverse.gsub(/\G((?:\d+\.)?\d{3})(?=\d)/, '\1,').reverse) : num.to_s
  end
  
  def link_and_if(condition, name, options = {}, html_options = {}, &block)
    if condition
      link_to(name, options, html_options, &block)
    else
      name
    end
  end

  def link_to_popup_mode(name, options = {}, html_options = {}, &block)
    if @popup_mode
      options[:popup] = 1
    end
    link_to(name, options, html_options, &block)
  end

  def form_tag_popup_mode(url_for_options = {}, options = {}, &block)
    if @popup_mode
      url_for_options[:popup] = 1
    end
    form_tag(url_for_options,options,&block)
  end

  def back_to
    params[:back_to]
  end

  def request_url
    request.env['REQUEST_URI']
  end

  def back_to_link_popup_mode(name, options = {}, html_options = {}, &block)
    if @popup_mode
      options[:popup] = 1
    end
    back_to_link(name, options, html_options, &block)
  end

  def back_to_link(name, options = {}, html_options = {}, &block)
    if options.class == String
      x = if options.include?('?')
        options += "&"
      else
        options += "?"
      end
      options += x + "back_to=" + URI.encode(request_url, Regexp.new("[^#{URI::PATTERN::ALNUM}]"))
    elsif options.is_a?(ActiveRecord::Base)
      options = polymorphic_path(options) + "?back_to=" + URI.encode(request_url, Regexp.new("[^#{URI::PATTERN::ALNUM}]"))
    else
      options[:back_to] = request_url
    end
    link_to(name, options, html_options, &block)
  end

  def back_to_link_if(cond, name, options = {}, html_options = {}, &block)
    options[:back_to] = request_url
    link_to_if(cond, name, options, html_options, &block)
  end

  def link_or_back(name, options = {}, html_options = {}, &block)
    link_to(name, (back_to || options), html_options, &block)
  end

  def delete_to(name, object, action = 'destroy')
    link_to(name, { :action => action, :id => object, :back_to => back_to, :authenticity_token => form_authenticity_token }, :confirm => 'この情報を削除します。よろしいですか?', :method => :post)
  end

  def square_table(array, options = {}, tag_options = {}, &block)
    col = (options[:col] || 3).to_i
    tag_option_arr = ['table']
    tag_options[:class] = 'square_table' unless tag_options[:class]
    if tag_options.is_a?(Hash)
      tag_options.each do |key, val|
        tag_option_arr << [key.to_s, "'#{val.to_s}'"].join("=")
      end
    end
    str = ""
    str << "<#{tag_option_arr.join(' ')}>\n"
    first = true
    array.each_index do |idx|
      if idx % col == 0
        str << '<tr style="text-align: center;">'
        col.times do |j|
          str << '<td>'
          if x = array[idx+j]
            str << block.call(x, idx)
          end
          str << '</td>'
        end
        str << "</tr>\n"
      end
    end
    str << '</table>'
  end

  def popup?
    @popup_mode
  end

  def link_to_change_approval_status(application_approval)
    result = []
    return result unless application_approval
    change_to_statuses =  ApplicationApproval.change_to_status(application_approval.approval_status_type)
    return result unless change_to_statuses
    change_to_statuses.each{|change_to_status|
      str = ApplicationApproval.approval_action_str(change_to_status)
      if change_to_status == 'reject'
        result << link_to(str, { :controller => 'application_approval', :action => 'reject', :id => application_approval, :application_type => application_approval.application_type, :approval_status_type => change_to_status, :back_to => request.env['REQUEST_URI'] })
      else
        result << link_to(str, { :controller => 'application_approval', :action => 'change_approval_status', :id => application_approval, :application_type => application_approval.application_type, :approval_status_type => change_to_status, :back_to => request.env['REQUEST_URI'] }, :confirm => "この申請を#{str}します。よろしいですか?", :method => :post)
      end
    }
    result 
  end

  def back_to
    params[:back_to]
  end

  def request_url
    request.env['REQUEST_URI']
  end

  def link_or_back(name, options = {}, html_options = {}, &block)
    link_to(name, (back_to || options), html_options, &block)
  end

  def back_to_field_tag
    params[:back_to].blank? ? "" : hidden_field_tag('back_to', params[:back_to]) 
  end

  def calHourMinuteFormat(sec)
    require 'date_time_util'
    DateTimeUtil.calHourMinuteFormat(sec)
  end
  
    def star_links(target)
    link_to(raw("<span id='starred_icon_#{target.id}' name='starred_icon_name_#{target.id}' style='#{_starstyle(target.starred)}'>★</span>"), "#", :onclick => "return changeFlg(#{target.id}, 'starred');")
  end
  
  def _starstyle(flg)
    flg.to_i == 1 ? "color: #ffff00" : "color: #dfdfdf"
  end
  
  def popup_hidden_field
    if popup?
      return hidden_field_tag :popup, params[:popup]
    else
      return ''
    end
  end
end
