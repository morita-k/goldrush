# -*- encoding: utf-8 -*-

require "httpclient"
require "nokogiri"
require 'csv'
require 'net/http'

Net::HTTP.version_1_2
Net::HTTP.start('www.hellowork.go.jp', 80) {|http|
  response = http.get('/ja/')
}

class HelloworkCrawler < Crawler

  def self.crawl(client, url)

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
  end

  def self.next_craw(client,doc)
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
    Nokogiri.parse(res2.body)
  end
  
  def self.initialize2(doc,links,nextpage,doc2)
    links = doc.xpath('//table//a[@name="link"]/@href').map{|x|x.value}
    nextpage = doc
    doc2 = doc.xpath('//input[@name="fwListNaviBtnNext"]')
    return links,nextpage,doc2
  end

  def self.data_acquisition(client,links,company,nume)
    companies = links.map do |link|
      puts nume = nume + 1
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
        company[arr[0]] = [arr[0],arr[1],arr[2],arr[3]]
      }
      arr[0]
    end
    return nume
  end

  def self.next_data_acquisition(client,nextpage,num,doc2,company,nume)
    if doc2 != nil then
      while nextpage.xpath('//input[@name="fwListNaviBtnNext"]').empty? != true do
        begin
          nextpageres = client.post("https://www.hellowork.go.jp/servicef/130050.do", {
            :fwListNaviBtnNext => "次へ>>",
            :fwListNowPage => num + 1,
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
          nextpage = Nokogiri.parse(nextpageres.body)
          links = nextpage.xpath('//table//a[@name="link"]/@href').map{|x|x.value}
          companies = links.map do |link|
            puts nume = nume + 1
            nextpage2 = client.get "https://www.hellowork.go.jp/servicef/" + link
            doc = Nokogiri.parse(nextpage2.body)
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
              company[arr[0]] = [arr[0],arr[1],arr[2],arr[3]]
            }
          puts arr[0]
          puts nextpage.xpath('//input[@name="fwListNaviBtnNext"]')
          end
          num = num + 1
        rescue SocketError => e
          retry
        end
      end
    end
  end

  def self.csv_output(output_pass,company)
    res = company.map{
      |key,val| 
      CSV.open(output_pass,'a') do |file|
        file << val
      end
    }
  end

  def self.main(url,pass)
    client = HTTPClient.new
    company = {}
    doc = []
    links = ""
    nextpage = ""
    doc2 = ""
    num = 0
    nume = 0
    crawl(client,url)
    doc = next_craw(client,doc)
    links,nextpage,doc2 = initialize2(doc,links,nextpage,doc2)
    nume = data_acquisition(client,links,company,nume)
    next_data_acquisition(client,nextpage,num,doc2,company,nume)
    csv_output(pass,company)
  end
end
