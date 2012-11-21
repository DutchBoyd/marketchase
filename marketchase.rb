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
require 'active_record'

class Booster < ActiveRecord::Base

end

module Marketchase
  def self.booster_parse(line)
    case line
      when /[^\[]+\[(\w+)\]\s+(\d+\.\d+)\s+(\d+\.\d+)/
        { set: $1, buy: $2, sell: $3 }
      when /([^\[]+\[)(\w+)(\]\s+)(\d+\.\d+)\s+/
        # determine if amount is buy or sell
        buy_column_start = 52
        if ($1 + $2 + $3).length > buy_column_start
          buy, sell = nil, $4
        else
          buy, sell = $4, nil
        end
        { set: $2, buy: buy, sell: sell }
      else
        nil
    end
  end

  def self.connect_db
    ActiveRecord::Base.establish_connection(YAML.load_file('database.yml'))
  end

  def self.run
    connect_db

    #opening Supernova booster pricelist
    f = open('http://supernovabots.com/prices_6.txt')
    boosterPrices = f.readlines

    #For each line, setting Buy/Sell/Set vars and writing to the database
    boosterPrices.each do |l|
      if parsed = booster_parse(l)
        # Here, if the buyPrice or sellPrice is blank, we populate the value
        # with the last value in our database... probably better to extrapolate
        # using a .95:1 ratio of buy:sell prices.  Not only would that be more
        # accurate, but it would also save database queries. Future version feature.

        set = parsed[:set]
        buyPrice = parsed[:buy] || Booster.where(MTGSet: set).last.BuyPrice
        sellPrice = parsed[:sell] || Booster.where(MTGSet: set).last.SellPrice
        Booster.create!(MTGSet: set, BuyPrice: buyPrice, SellPrice: sellPrice)
      end
    end
  end
end
