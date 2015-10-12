#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'open-uri/cached'
require 'colorize'
require 'pry'
require 'csv'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

@terms = {
  '2012' => 'List_of_MPs_elected_in_the_Mongolian_legislative_election,_2012',
  '2008' => 'List_of_MPs_elected_in_the_Mongolian_legislative_election,_2008',
}

@terms.each do |term, pagename|
  url = "https://en.wikipedia.org/wiki/" + pagename
  page = noko(url)


  # Constituency based
  members = page.xpath('.//h2/span[text()[contains(.,"Constituency")]]/following::table[1]')
    # Store this outside the loop so we can refer back in rowspans
    district = nil
  members.xpath('.//tr[td]').each do |tr|
    tds = tr.xpath('./td')
    if tds.count == 5
      district = tds[0]
    else
      # Nokogiri::XML::NodeSet doesn't have an unshift
      tds = [district, tds].flatten
    end
    data = { 
      name: tds[1].xpath('.//a').text.strip,
      name__mn: tds[2].text.strip,
      party: tds[4].text.strip,
      constituency: tds[0].text.strip.gsub("\n",' — '),
      term: term,
      wikiname: tds[1].xpath('.//a[not(@class="new")]/@title').text.strip,
      source: url,
    }
    ScraperWiki.save_sqlite([:name, :term], data)
  end

  # Party List 
  partylist = page.xpath('.//h2/span[text()[contains(.,"Party list")]]/following::table[1]')
  partylist.xpath('.//tr[td]').each do |tr|
    tds = tr.xpath('./td')
    data = { 
      name: tds[0].xpath('.//a').text.strip,
      name__mn: tds[1].text.strip,
      party: tds[3].text.strip,
      constituency: 'n/a',
      term: term,
      wikiname: tds[1].xpath('.//a[not(@class="new")]/@title').text.strip,
      source: url,
    }
    ScraperWiki.save_sqlite([:name, :term], data)
  end

end

