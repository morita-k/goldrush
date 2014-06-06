# -*- encoding: utf-8 -*-

module TagsHelper
  def tag_star_radios(starred, id="")
    res = [3,4,0,1,2].map do |x|
      <<EOS
      <label class="btn btn-default#{starred.to_s == x.to_s ? ' active' : '' }">
        #{radio_button_tag "starred#{id}", x.to_s, starred.to_s == x.to_s, :tag_id => id } <span style="#{StarUtil.attr_style(x)}">★</span>
      </label>
EOS
    end
    raw res.join
  end 
end

