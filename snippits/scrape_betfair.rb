# Example script to scrape the Betfair API for prices and store them in redis as json strings.

# WARNING - Beware of the Betfair data usage limits!!!

require 'eventmachine'
require 'em-betfair'
require 'date'
require 'time'
require 'redis'
require 'json'

# Not requiring activesupport just to get ordanalize
class Fixnum
  def ordinalize
    if (11..13).include?(self % 100)
      "#{self}th"
    else
      case self % 10
      when 1; "#{self}st"
      when 2; "#{self}nd"
      when 3; "#{self}rd"
      else    "#{self}th"
      end
    end
  end
end

EM::run {

  config = {
    "username" => "<YOUR BETFAIR USERNAME>",
    "password" => "<YOUR BETFAIR PASSWORD>", 
    "product_id" => "<YOUR BETFAIR PRODUCTID>", 
    "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
    "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
  }

  bf_client = Betfair::Client.new(config)
  redis_client = Redis.new
  timers = {}
  num_timers = 0

  # Fetch all the horse racing markets in the UK for today
  bf_client.get_all_markets ["GBR"], [7], "#{Date.today} 00:00:00", "#{Date.today} 23:59:00" do |response|

    response.hash_response["market_data"].each do |market_id,market_hash|

      menu_path = market_hash["menu_path"]
      track_name = menu_path.match(/\\.+\\.+\\(\w+\s{0,1}\w*)/)[1]

      # Lets just fetch the 'real' markets rather than AvB, Antepost, Place etc
      next unless track_name && !market_hash["name"].match(/To Be Placed/) && !menu_path.match(/ANTEPOST/) && !menu_path.match(/Forecast/) && track_name.match(/#{Date.today.day.ordinalize}/)

      # Fetch the runners
      bf_client.get_market market_id do |market_response|
        market_details = market_response.hash_response
        puts "Got market #{market_id} #{track_name} #{market_hash["name"]} #{Time.parse(market_details["market_time"])}"
        runners = market_details["runners"]

        # If the market is active, setup some periodical timers 
        next unless market_details["status"] == "ACTIVE"

        # would be nice to get the data from getSilks here
        redis_client.hset track_name, market_hash["name"], {"market_details" => market_details, "prices" => nil}.to_json

        next if num_timers > 59 # free API restriction

        # Update the odds every 60 seconds
        timers[market_id] = EventMachine::PeriodicTimer.new(60) do
          num_timers += 1
          bf_client.get_market_prices_compressed market_id do |prices_response|
            puts "Fetching prices for #{market_id}"
            price_data = prices_response.hash_response
            timers[market_id].cancel if timers[market_id] && price_data["status"] != "ACTIVE"
            race = redis_client.hget track_name, market_hash["name"]
            race_hash = JSON.parse(race)
            race_hash["prices"] = price_data
            redis_client.hset track_name, market_hash["name"], race_hash.to_json
          end
        end

      end

    end

  end

}