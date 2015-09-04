# -*- encoding: utf-8 -*-
require "httpclient"
require "nokogiri"
require 'csv'

class ItunesCrawler < Crawler

  def ItunesCrawler.main(url,pass)
    client = HTTPClient.new
    company = {}
    num = 1
    column_num = 0
    ic = ItunesCrawler.new
    ic.crawl(client,url,num,company,column_num,ic)
    ic.csv_output(pass,company,ic)
  end
  
  def crawl(client,url,num,company,column_num,ic)
    res = client.get(url)
    doc = Nokogiri.parse(res.body)
  #  puts doc.xpath('//div[@id="selectedgenre"]/ul[@class="list alpha"]/li/a[@title="ƒQ[ƒ€‚ð‚³‚ç‚Éi‚èž‚ÝŒŸõB"]/@href')
    while column_num != 27
      puts doc.xpath('//div[@id="selectedgenre"]/ul[@class="list alpha"]/li/a[@title="ƒQ[ƒ€‚ð‚³‚ç‚Éi‚èž‚ÝŒŸõB"]/@href')[column_num]
      res = client.get(doc.xpath('//div[@id="selectedgenre"]/ul[@class="list alpha"]/li/a[@title="ƒQ[ƒ€‚ð‚³‚ç‚Éi‚èž‚ÝŒŸõB"]/@href')[column_num])
      doc = Nokogiri.parse(res.body)
      while doc.xpath('//a[@class="paginate-more"]').empty? != true 
        begin
          if num != 1 then
            res = client.get(doc.xpath('//a[@class="paginate-more"]/@href')[0])
            doc = Nokogiri.parse(res.body)
          end
          links_first = doc.xpath('//div[@class="column first"]/ul/li/a/@href').map{|x|x.value}
          links_column = doc.xpath('//div[@class="column"]/ul/li/a/@href').map{|x|x.value}
          links_last = doc.xpath('//div[@class="column last"]/ul/li/a/@href').map{|x|x.value}
          
          client,num = ic.data_links_first_acquisitions(client,company,num,links_first)
          client,num = ic.data_links_column_acquisitions(client,company,num,links_column)
          client,num = ic.data_links_last_acquisitions(client,company,num,links_last)
        rescue SocketError => e
          retry
        rescue NoMethodError => e
          retry
        rescue Timeout::Error => e
          retry
        end
        puts "a"
        num = num + 1
        puts doc.xpath('//a[@class="paginate-more"]').empty?
      end
      column_num = column_num + 1
      num = 1
    end
  end

  def data_links_first_acquisitions(client,company,num,links_first)
    puts num
    puts 1
    companies = links_first.map do |link|
      res = client.get link
      doc = Nokogiri.parse(res.body)
      arr = Array.new(2,"")
      if doc.xpath('//div[@class="intro has-gcbadge"]/div[@class="left"]').empty? != true then
        doc.xpath('//div[@class="intro has-gcbadge"]/div[@class="left"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
          arr[1] = (x.xpath("h2")[0].text.strip).delete("ŠJ”­: ")
          company[arr[1]] = [arr[1],arr[0]]
          puts arr[0]
        }
      elsif doc.xpath('//div[@class="intro "]/div[@class="left"]').empty? != true then
        doc.xpath('//div[@class="intro "]/div[@class="left"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
          arr[1] = (x.xpath("h2")[0].text.strip).delete("ŠJ”­: ")
          company[arr[1]] = [arr[1],arr[0]]
        }
        puts arr[0]
      end
    end
    return client,num
  end
  
  def data_links_column_acquisitions(client,company,num,links_column)
    puts num
    puts 2
    companies = links_column.map do |link|
      res = client.get link
      doc = Nokogiri.parse(res.body)
      arr = Array.new(2,"")
      if doc.xpath('//div[@class="intro has-gcbadge"]/div[@class="left"]').empty? != true then
        doc.xpath('//div[@class="intro has-gcbadge"]/div[@class="left"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
          arr[1] = (x.xpath("h2")[0].text.strip).delete("ŠJ”­: ")
          company[arr[1]] = [arr[1],arr[0]]
        }
        puts arr[0]
      elsif doc.xpath('//div[@class="intro "]/div[@class="left"]').empty? != true then
        doc.xpath('//div[@class="intro "]/div[@class="left"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
          arr[1] = (x.xpath("h2")[0].text.strip).delete("ŠJ”­: ")
          company[arr[1]] = [arr[1],arr[0]]
        }
        puts arr[0]
      end
    end
    return client,num
  end
  
  def data_links_last_acquisitions(client,company,num,links_last)
    puts num
    puts 3
    companies = links_last.map do |link|
      res = client.get link
      doc = Nokogiri.parse(res.body)
      arr = Array.new(2,"")
      if doc.xpath('//div[@class="intro has-gcbadge"]/div[@class="left"]').empty? != true then
        doc.xpath('//div[@class="intro has-gcbadge"]/div[@class="left"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
          arr[1] = (x.xpath("h2")[0].text.strip).delete("ŠJ”­: ")
          company[arr[1]] = [arr[1],arr[0]]
        }
        puts arr[0]
      elsif doc.xpath('//div[@class="intro "]/div[@class="left"]').empty? != true then
        doc.xpath('//div[@class="intro "]/div[@class="left"]').each{|x|
          arr[0] = x.xpath("//h1")[0].text.strip
          arr[1] = (x.xpath("h2")[0].text.strip).delete("ŠJ”­: ")
          company[arr[1]] = [arr[1],arr[0]]
        }
        puts arr[0]
      end
    end
    return client,num
  end

  def csv_output(output_pass,company)
    res = company.map{
      |key,val| 
      CSV.open(output_pass,'a') do |file|
        file << val
      end
    }
  end

end

