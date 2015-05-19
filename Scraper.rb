require 'open-uri'
require 'nokogiri'

#page class
#holds and ouputs data relating to a single page
#---------------------------------------------------
class Page
  def initialize(link, html, output_iterator)
  	@link          = link
  	@output_number = output_iterator
  	@words         = Hash.new(0)
  	@temp_words    = Nokogiri::HTML.parse(html)
  	@fixed_array   = Array.new
  	
  	clean_words

  	count_words

  	print
  end

  def clean_words
  	@temp_words = @temp_words.css("body").inner_text.scan(/([a-z]+(('([a-z]))|\.)?)/i)
  end

  def count_words
    @temp_words.each do |word|
      @fixed_array.push(word[0])
    end

    @fixed_array.map { |key| @words[key] += 1 }

    @words = @words.sort_by{ |k, v| v }
  end

  def print
    @file_name = @output_number.to_s + ".txt"

    output = File.open(@file_name, "w")
    output << @link + "/n"

    @words.each do |word, count|
      output << "#{word}: #{count} \n"
    end

    output.close
  end

end


#Scraper Class
#Scrapes Urls and turns them into page objects
#--------------------------------------------------------
class Scraper
  #the below take the place of the global variables from
  #the previous crawler
  attr_reader :links, :link_count, :words 

  def initialize
    @output_iterator = 0
    #@global_outfile  = File.open("GLOBAL.txt","w")
    @links           = Array.new
    @link_count      = Hash.new
  end

  #retrieve html and send to other methods
  def scrape(url)
    begin
      temp_html = Nokogiri::HTML(open(url))
    rescue OpenURI::HTTPError => e #handle errors on page load
      puts url + " is not accessable"
    else
      clean(temp_html)

      update_links(temp_html)

      @page = Page.new(url, temp_html.text, @output_iterator)
      @output_iterator += 1

      explore_links
    end
  end

  #get rid of scripts and other nasties in the html
  def clean(html)
    html.xpath("//script").remove
  end

  #add links to their container
  def update_links(html)
    @links.push(*html.css("a"))#maybe push isnt the best idea

    @links = @links.uniq#test if you can just @links.uniq
  end

  #follow the next link down the line, and start over again
  def explore_links
    @links.each do |link|
      if (link["href"] || '').include? "/science-technology/"
        temp_link = link["href"]
        if @link_count.has_key?(temp_link)
          @link_count[temp_link] += 1
        else
          @link_count[temp_link] = 1	
          if !(temp_link || '').include? "http://www.usm.edu"
            scrape("http://www.usm.edu" + temp_link)
          else
          	scrape(temp_link)
          end
        end
      end
    end
  end

end

scraper = Scraper.new

scraper.scrape('http://www.usm.edu/science-technology/')
