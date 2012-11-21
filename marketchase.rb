## MTGO Price Grabber v1.0 (grab_booster_prices.rb)
## by Dutch Boyd (dutch@dutchboyd.com)
## November 18, 2012
##
## This Ruby Program is a utility for Magic:The Gathering Online.  It 
## opens the Supernovabots pricelist, parses the data line by line, and
## writes the set, buyPrice, and sellPrice into a MySQL database.
##
## I'm using a cron job to run this script every 15 minutes and populate
## a DB which feeds a jScript charting program called HighChats.  For
## a look at how it works, check out MTGOCharts.com.  If you have
## any questions or comments, or have a project you would like to
## collaberate on, feel free to contact me.

require 'open-uri'
require 'mysql'
require 'yaml'

module Marketchase
  DbConfig = YAML.load_file('database.yml')

  def self.checkbuyprice (buy, set)
    if buy.strip.empty?
      # Buy Variable is blank
      # Fill out your db info here.  Next version should have support for loading a dbconfig file		
      dbh = Mysql.new(DbConfig['host'], DbConfig['user'], DbConfig['password'], DbConfig['database'])
      # MySQL Query gets the last value for buyPrice
      querystring = "SELECT BuyPrice FROM `boosters` WHERE MTGSet='#{set}' AND Time=(SELECT Max(Time) FROM boosters WHERE MTGSet='#{set}')"
      d = dbh.query(querystring)
      dbh.close
      b = d.fetch_row[0]
      return b
    else
      # Buy Variable is not blank
      b = buy
      return b
    end
  end
  def self.checksellprice	(sell, set)
    if sell.strip.empty?
      dbh = Mysql.new(DbConfig['host'], DbConfig['user'], DbConfig['password'], DbConfig['database'])
      d = dbh.query("SELECT SellPrice FROM `boosters` WHERE MTGSet='#{set}' AND Time=(SELECT MAX(TIME) FROM boosters WHERE MTGSet='#{set}')")
      dbh.close
      s = d.fetch_row[0]
      return s
    else
      s = sell
      return s
    end
  end

  def self.run
    #opening Supernova booster pricelist
    f = open('http://supernovabots.com/prices_6.txt')
    boosterPrices = f.readlines

    #For each line, setting Buy/Sell/Set vars and writing to the database
    boosterPrices.each do |l|

      # Here we are working with regex to detect whether the line is valid
      # and to pull out the set.  Future versions will pull out quantity.
      # REGEX string to capture the set :  /\s\[[\w]{2,3}\]/
      # REGEX string to capture the quantity : /\S\[[\w]{1,3}\]/
      md = l.match /[^\[]+\[(\w+)\]\s+(\d+\.\d+)\s+(\d+\.\d+)/
      if md
        _, set, buy, sell = md.to_a

        # Here, if the buyPrice or sellPrice is blank, we populate the value
        # with the last value in our database... probably better to extrapolate
        # using a .95:1 ratio of buy:sell prices.  Not only would that be more
        # accurate, but it would also save database queries. Future version feature.

        buyPrice = checkbuyprice(buy, set).strip
        sellPrice = checksellprice(sell, set).strip
        dbh = Mysql.new(DbConfig['host'], DbConfig['user'], DbConfig['password'], DbConfig['database'])
        dbh.query("INSERT INTO boosters (MTGSet, BuyPrice, SellPrice) VALUES ('#{set}', '#{buyPrice}', '#{sellPrice}')")
        dbh.close
      end
    end
  end
end
