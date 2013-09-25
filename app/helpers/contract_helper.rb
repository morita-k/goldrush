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

  def in_term?(term_start, term_end, contract)
    contract.contract_start_date <= term_end and contract.contract_end_date >= term_start
  end

  def include_term?(term_start, term_end, contracts)
    contracts.each do |contract|
      return contract if in_term?(term_start,term_end,contract)
    end
    return nil
  end
end
