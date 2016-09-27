#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri/cached'

require 'pry'

class Table
  def initialize(node)
    @table = node
  end

  def rows
    constituency = nil
    table.xpath('.//tr[td]').map do |tr|
      tds = tr.xpath('./td')
      constituency = tds.shift.text.strip.gsub("\n",' — ') if tds.first[:rowspan]
      Row.new(tds).to_h.merge(constituency: constituency)
    end
  end

  private

  attr_reader :table
end

class Row
  def initialize(tds)
    @tds = tds
  end

  def to_h
    {
      name: name,
      name__mn: name_mn,
      party: party,
      wikiname: wikiname,
    }
  end

  private

  attr_reader :tds

  def name
    tds[0].xpath('.//a').text.strip
  end

  def name_mn
    tds[1].text.strip
  end

  def party
    tds[3].text.strip
  end

  def wikiname
    tds[0].xpath('.//a[not(@class="new")]/@title').text.strip
  end
end

class Khurai
  def initialize(term, url)
    @url = url
    @term = term
  end

  def members
    Table.new(table).rows.map do |row|
      row.merge(term: term)
    end
  end

  private

  attr_reader :url, :term

  def page
    Nokogiri::HTML(open(url).read)
  end

  def table
    page.xpath('.//h2/span[text()[contains(.,"Constituency")]]/following::table[1]')
  end
end

base_url = 'https://en.wikipedia.org/wiki/'

terms = [
  { year: '2012', url: base_url+'List_of_MPs_elected_in_the_Mongolian_legislative_election,_2012' },
  { year: '2008', url: base_url+'List_of_MPs_elected_in_the_Mongolian_legislative_election,_2008' },
]

terms.each do |term|
  Khurai.new(term[:year], term[:url]).members.each do |mem|
    ScraperWiki.save_sqlite([:name, :term], mem)
  end
end
