# -*- encoding: utf-8 -*-
class OutflowMailController < ApplicationController

  def list
  	# @outfolow_mails = OutflowMail.where(deleted: 0)
  	@outflow_mails = "test"

  	render layout: 'blank'
  end

end