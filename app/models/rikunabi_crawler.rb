require "httpclient"
require "nokogiri"
require 'csv'

class RikunabiCrawler < Crawler

  def crawl(client,url)
    client.get(url)
    res = client.post("http://next.rikunabi.com/rnc/docs/cp_s00700.jsp?__m=1439884939667-4373695622116622265", {
      :wrk_plc_long_cd => "0313100000",
      :indus_long_cd => "010101",
      :employ_frm_cd => "",
      :srch_ann_inc_cd => "",
      :scale_cd => "",
      :estb_year_cd => "",
      :keyword => "",
      :l_screen_id => "cp_s00700",
      :l_srch_id => "cp_s00700",
      :n_list_flg => "",
      :disp_cd => "cp_s01990",
      :ov_wrt_aprvl_f => 0
    })
    Nokogiri.parse(res.body)
  end

  def data_acquisition(client,doc,company,num)
    links = doc.xpath('//div[@class="list_box"]/div[@class="n_list_footer"]/div[@class="inner_footer"]/div[@class="company_info_btn"]/a/@href').map{|x|x.value}
    companies = links.map do |link|
      res = client.get "http://next.rikunabi.com" + link
      doc = Nokogiri.parse(res.body)
      arr = Array.new(7,"")
      doc.xpath('//div[@id="kaishagaiyou_inner"]/dl[@class="clr"]').each{|x|
        arr[0] = x.xpath("//h1")[0].text.strip

        if "事業内容" == x.xpath("dt")[0].text
          arr[1] = x.xpath("dd")[0].text.strip
        end
        if "事業所" == x.xpath("dt")[0].text
          arr[2] = x.xpath("dd")[0].text.strip
        end
        if "設立" == x.xpath("dt")[0].text
          arr[3] = x.xpath("dd")[0].text.strip
        end
        if "代表者" == x.xpath("dt")[0].text
          arr[4] = x.xpath("dd")[0].text.strip
        end
        if "従業員数" == x.xpath("dt")[0].text
          arr[5] = x.xpath("dd")[0].text.strip
        end
        if "資本金" == x.xpath("dt")[0].text
          arr[6] = x.xpath("dd")[0].text.strip
        end
        company[arr[0]] = [arr[0],arr[1],arr[2],arr[3],arr[4],arr[5],arr[6]]
      }
      num = num + 1
      puts num
      puts arr[0]
    end
    return num
  end

  def next_data_acquisition(client,doc,num,company,path1,path2,path3)
    while doc.xpath('//div[@class="n_ichiran_950_pager"]/div[@class="multicol clr"]/div[@class="rightcol"]/div[@class="spr_paging"]/div[@class="spr_next"]/span').empty? or num == 0 do
      begin
        path2 = path2.to_i + 50
        nextpage_res = client.get(path1 + path2.to_s + path3)
        doc = Nokogiri.parse(nextpage_res.body)
        links = doc.xpath('//div[@class="list_box"]/div[@class="n_list_footer"]/div[@class="inner_footer"]/div[@class="company_info_btn"]/a/@href').map{|x|x.value}
        companies = links.map do |link|
          sequel_nextpage_res = client.get "http://next.rikunabi.com" + link
          sequel_doc = Nokogiri.parse(sequel_nextpage_res.body)
          arr = Array.new(7,"")
          sequel_doc.xpath('//div[@id="kaishagaiyou_inner"]/dl[@class="clr"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
            if "事業内容" == x.xpath("dt")[0].text
              arr[1] = x.xpath("dd")[0].text.strip
            end
            if "事業所" == x.xpath("dt")[0].text
              arr[2] = x.xpath("dd")[0].text.strip
            end
            if "設立" == x.xpath("dt")[0].text
              arr[3] = x.xpath("dd")[0].text.strip
            end
            if "代表者" == x.xpath("dt")[0].text
              arr[4] = x.xpath("dd")[0].text.strip
            end
            if "従業員数" == x.xpath("dt")[0].text
              arr[5] = x.xpath("dd")[0].text.strip
            end
            if "資本金" == x.xpath("dt")[0].text
              arr[6] = x.xpath("dd")[0].text.strip
            end
            company[arr[0]] = [arr[0],arr[1],arr[2],arr[3],arr[4],arr[5],arr[6]]
          }
          num = num + 1
          puts num
          puts arr[0]
        end
      rescue SocketError => e
        retry
      end
    end
  end

  def csv_output(output_pass,company)
    res = company.map{
      |key,val| 
      CSV.open(output_pass,'a') do |file|
        file << val
      end
    }
  end

  def RikunabiCrawler.main(url,pass)
    client = HTTPClient.new
    company = {}
    doc = []
    links = ""
    num = 0
    path1 = "http://next.rikunabi.com/area_wp0313100000/il010101/crn"
    path2 = 1
    path3 = ".html"
    rc = RikunabiCrawler.new
    doc = rc.crawl(client,url)
    num = rc.data_acquisition(client,doc,company,num)
    rc.next_data_acquisition(client,doc,num,company,path1,path2,path3)
    rc.csv_output(pass,company)
  end

end
