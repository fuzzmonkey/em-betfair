# Example script to scrape the Betfair API for prices and store them in redis as json strings.
# Updated to include new built in handling of rate limiting for free API

require 'eventmachine'
require 'em-betfair'
require 'date'
require 'time'
require 'em-redis'
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
    "product_id" => "82",
    "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
    "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
  }

  bf_client = Betfair::Client.new(config)
  redis_clieint = EM::Protocols::Redis.connect

  bf_client.get_all_markets ["GBR"], [7], "#{Date.today} 00:00:00", "#{Date.today} 23:59:00" do |response|

    response.hash_response["market_data"].each do |market_id,market_hash|

      menu_path = market_hash["menu_path"]
      track_name = menu_path.match(/\\.+\\.+\\(\w+\s{0,1}\w*)/)
      track_name = track_name ? track_name[1] : nil

      # TODO - I'd like the client to handle this or at least the response parser.
      next unless track_name && !market_hash["name"].match(/To Be Placed/) && !menu_path.match(/ANTEPOST/) && !menu_path.match(/Forecast/) && track_name.match(/#{Date.today.day.ordinalize}/)

      # Fetch the runners
      bf_client.get_market market_id do |market_response|
        market_details = market_response.hash_response
        puts "Got market #{market_id} #{track_name} #{market_hash["name"]} #{Time.parse(market_details["market_time"])}"
        runners = market_details["runners"]

        next unless market_details["status"] == "ACTIVE"

        redis_client.hset track_name, market_hash["name"], {"market_details" => market_details, "prices" => nil}.to_json do |rsp|

          puts "Saved #{market_id} #{track_name} #{market_hash["name"]} in redis"

        end

      end

    end

  end

}