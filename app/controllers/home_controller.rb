# -*- encoding: utf-8 -*-
require 'star_util'
class HomeController < ApplicationController

  def index
  end

  def stale_object
  end
  
  def change_star
    model = params[:model].constantize.find(params[:id])
    star_colors = SysConfig.star_color
    # star_colorsの配列サイズで値がローテートする
    model.starred = (model.starred + 1) % star_colors.size
    set_user_column model
    model.save!
    
    # javascriptの返送
    color = star_colors[model.starred]
    attr_class = StarUtil.attr_class(model)
    respond_to do |format|
      format.js { render :text => "Star.update('#{ attr_class }', '#{ color }');" }
    end
  end

  def fix
    model = params[:model].constantize.find(params[:target_id])
    model.starred = params[:starred] || 3
    set_user_column model
    model.save!
    render :text => "OK", :layout => false
  end

end
