# -*- encoding: utf-8 -*-
module ContractHelper

  def each_month(st, ed, &block)
    res = ""
    x = st
    while x < ed do
      res << capture(x, &block)
      x = x.next_month
    end
    raw res
  end

  def include_term?(term_start, term_end, contracts)
    Contract.include_term?(term_end, term_end, contracts)
  end

  def color(contract, type)
    {
      "abort" => "gray",
      "closed" => "gray",
      "confirming" => (contract.confirm_warning? ? "red" : "yellow"),
      "contracted" => "seagreen",
      "finished" => "gray",
      "proc_acceptance" => "greenyellow",
      "proc_order" => "greenyellow",
      "waiting_acceptance" => "greenyellow",
      "waiting_offer" => "greenyellow",
      "waiting_order" => "greenyellow",
    }[type]
  end

  def years(date=Date.today)
    ((date.year - 2)..(date.year + 3)).map{|x| x.to_s}.unshift("")
  end

  def months
    (1..12).map{|x| sprintf("%02d",x) }.unshift("")
  end

  def pay(payment)
    (payment / 10000).to_i.to_s + "万円"
  end

  def rate(a,b)
    return "-" if a == 0
    (b.to_f / a * 100).round(2).to_s + "%"
  end

  def title
    y = params[:year]
    m = params[:month]
    x = if !y.blank? && !m.blank?
      "#{y}年#{m}月度 "
    elsif !y.blank?
      "#{y}年度 "
    end
    x.to_s + getLongName('table_name','contracts') + "一覧"
  end
end
