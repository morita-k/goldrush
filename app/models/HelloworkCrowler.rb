require "httpclient"
require "nokogiri"
require 'csv'

class HelloworkCrawler < Crawler

  def crawl(url)
   
    client = HTTPClient.new
    client.get(url)

    res = client.post("https://www.hellowork.go.jp/servicef/130020.do", {
      :kyushokuNumber1 => "",
      :kyushokuNumber2 => "",
      :kyushokuUmu => 2,
      :kyujinShurui => 1,
      :gekkyuKagen => "",
      :teate => 1,
      :kiboShokushu => "B",
      :todofuken1 => "",
      :chiku1 => "",
      :todofuken2 => "",
      :chiku2 => "",
      :todofuken3 => "",
      :chiku3 => "",
      :todofuken4 => "",
      :chiku4 => "",
      :todofuken5 => "",
      :chiku5 => "",
      :nenrei => "",
      :kiboSangyo => "G",
      :commonNextScreen => "詳細条件入力",
      :screenId => "130020",
      :action => "",
      :codeAssistType => "",
      :codeAssistKind => "",
      :codeAssistCode => "",
      :codeAssistItemCode => "",
      :codeAssistItemName => "",
      :codeAssistDivide => "",
      :xab_vrbs => "commonNextScreen,commonSearch,detailSearchButton,commonDelete"
    })
    doc1 = Nokogiri.parse(res.body)
  end

  def next_craw
    res2 = client.post("https://www.hellowork.go.jp/servicef/130030.do", {
      :kiboShokushuDetail => 10,
      :freeWordType => 0,
      :freeWord => "",
      :kiboSangyoDetail => 39,
      :shukyuFutsuka => 0,
      :nenkanKyujitsu => "",
      :rdoJkgi => 9,
      :fulltimeKaishiHH => "",
      :fulltimeKaishiMM => "",
      :fulltimeShuryoHH => "",
      :fulltimeShuryoMM => "",
      :license1 => "",
      :license2 => "",
      :license3 => "",
      :jigyoshomei => "",
      :commonSearch => "検索",
      :kyushokuUmuHidden => 2,
      :kyujinShuruiHidden => 1,
      :teateHidden => 1,
      :kiboShokushuHidden => "B",
      :kiboSangyoHidden => "G",
      :screenId => "130030",
      :action => "",
      :codeAssistType => "",
      :codeAssistKind => "",
      :codeAssistCode => "",
      :codeAssistItemCode => "",
      :codeAssistItemName => "",
      :codeAssistDivide => "",
      :xab_vrbs => "commonNextScreen,commonSearch,commonDelete"
    })
    doc = Nokogiri.parse(res2.body)
  end

  def Variable
    doc2 = doc.xpath('//input[@name="fwListNaviBtnNext"]')
    links = doc.xpath('//table//a[@name="link"]/@href').map{|x|x.value}
    @company = {}
    @nume = 0
    @num = 0
    @nextpage = doc
  end

  def data_acquisition
    companies = links.map do |link|
	    puts @nume = @nume + 1
      res = client.get "https://www.hellowork.go.jp/servicef/" + link
      doc = Nokogiri.parse(res.body)
      arr = Array.new(4,"")
      doc.xpath("//table/tr").each{|x|
        if "事業所名" == x.xpath("th")[0].text
          arr[0] = x.xpath("td")[0].text.strip
        end
        if "所在地" == x.xpath("th")[0].text
          arr[1] = x.xpath("td")[0].text.strip
        end
        if "電話番号" == x.xpath("th")[0].text
          arr[2] = x.xpath("td")[0].text.strip
        end
        if "事業内容" == x.xpath("th")[0].text
          arr[3] = x.xpath("td")[0].text.strip
        end
        @company[arr[0]] = [arr[0],arr[1],arr[2],arr[3]]
      }
#  CSV.open("/home/morita/デスクトップ/hellowork.csv",'a') do |file|
#    file << [arr[0],arr[1],arr[2],arr[3]]
#  end
      arr[0]
    end
  end

  def next_data_acquisition
    if doc2 != nil then
      while @nextpage.xpath('//input[@name="fwListNaviBtnNext"]').empty? != true or @num == 0 do
        begin
	        nextpageres = client.post("https://www.hellowork.go.jp/servicef/130050.do", {
            :fwListNaviBtnNext => "次へ>>",
            :fwListNowPage => @num + 1,
            :fwListLeftPage => 1,
            :fwListNaviCount => 11,
            :kyushokuUmuHidden => 2,
            :kyujinShuruiHidden => 1,
            :teateHidden => 1,
            :kiboShokushuHidden => "B",
            :kiboSangyoHidden => "G",
            :kiboShokushuDetailHidden => 10,
            :freeWordTypeHidden => 0,
            :kiboSangyoDetailHidden => 39,
            :shukyuFutsukaHidden => 0,
            :rdoJkgiHidden => 9,
            :screenId => 130050,
            :action => "",
            :codeAssistType => "",
            :codeAssistKind => "",
            :codeAssistCode => "",
            :codeAssistItemCode => "",
            :codeAssistItemName => "",
            :codeAssistDivide => "",
            :xab_vrbs => "detailJokenDispButton,commonNextScreen,detailJokenChangeButton,commonDetailInf"
	        })
	        @nextpage = Nokogiri.parse(nextpageres.body)
	        links = @nextpage.xpath('//table//a[@name="link"]/@href').map{|x|x.value}
	        companies = links.map do |link|
	          puts @nume = @nume + 1
    	      nextpage = client.get "https://www.hellowork.go.jp/servicef/" + link
	          doc = Nokogiri.parse(nextpage.body)
    	      arr = Array.new(4,"")
    	      doc.xpath("//table/tr").each{|x|
	            if "事業所名" == x.xpath("th")[0].text
	              arr[0] = x.xpath("td")[0].text.strip
    	        end
    	        if "所在地" == x.xpath("th")[0].text
    	          arr[1] = x.xpath("td")[0].text.strip
    	        end
	            if "電話番号" == x.xpath("th")[0].text
	              arr[2] = x.xpath("td")[0].text.strip
	            end
    	        if "事業内容" == x.xpath("th")[0].text
	              arr[3] = x.xpath("td")[0].text.strip
    	        end
                @company[arr[0]] = [arr[0],arr[1],arr[2],arr[3]]
	          }
	          puts arr[0]
	          puts @nextpage.xpath('//input[@name="fwListNaviBtnNext"]')
    	    end
	        @num = @num + 1
        rescue SocketError => e
          retry
        end
      end
    end
  end

  def csv_output(output_pass)
    res = @company.map{
      |key,val| 
      CSV.open(output_pass,'a') do |file|
        file << val
      end
    }
  end

end
