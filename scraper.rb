#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'open-uri/cached'
# require 'colorize'
require 'pry'
require 'csv'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

@WIKI = 'http://en.wikipedia.org'

@terms = {
  '2012' => 'List_of_MPs_elected_in_the_Mongolian_legislative_election,_2012',
  '2008' => 'List_of_MPs_elected_in_the_Mongolian_legislative_election,_2008',
}

@terms.each do |term, pagename|
  url = "#{@WIKI}/wiki/#{pagename}"
  page = noko(url)

  # Store this outside the loop so we can refer back in rowspans
  district = nil

  members = page.xpath('.//h2/span[text()[contains(.,"Constituency")]]/following::table[1]')
  members.xpath('.//tr[td]').each do |tr|
    tds = tr.xpath('./td')
    if tds.count == 5
      district = tds[0]
    else
      # Nokogiri::XML::NodeSet doesn't have an unshift
      tds = [district, tds].flatten
    end
    data = { 
      constituency: tds[0].text.strip.gsub("\n",' — '),
      name: tds[1].xpath('.//a').text.strip,
      name_mn: tds[2].text.strip,
      party: tds[4].text.strip,
      term: term,
      wikipedia: tds[1].xpath('.//a[not(@class="new")]/@href').text.strip,
      source: url,
    }
    data[:wikipedia].prepend @WIKI unless data[:wikipedia].empty?
    puts data.values.to_csv
    # ScraperWiki.save_sqlite([:name, :term], data)
  end
end

