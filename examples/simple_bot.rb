require 'eventmachine'
require 'em-betfair'
require 'logger'

module Betfair

  class SimpleBot

    def initialize config
      EM::run {
        @logger = Logger.new(STDOUT)
        @bf_client = Betfair::Client.new(config, @logger)
        # @redis = EM::Protocols::Redis.connect
        @logger.info "Betfair::SimpleBot running"
        EventMachine::PeriodicTimer.new(60) { Fiber.new { update_markets }.resume }
      }
    end

    def update_markets
      markets_response = @bf_client.get_all_markets ["GBR"], [7], "#{Date.today} 00:00:00", "#{Date.today} 23:59:00"

      # update the status of the market in redis, if it's changed (e.g != ACTIVE), cancel any pollers
      # if we have the market, don't call get_market

      markets_response.hash_response["bsp_markets"].each do |bsp_market|
        next unless bsp_market["status"] == "ACTIVE"

        menu_path = bsp_market["menu_path"]
        track_name = menu_path.match(/\\.+\\.+\\(\w+\s{0,1}\w*)/)

        market_details = @bf_client.get_market(bsp_market["id"]).hash_response
        runners = market_details["runners"]

        # Save runners / market in redis. 
        # redis_client.hset track_name, market_hash["name"], {"market_details" => market_details, "prices" => nil}.to_json do |rsp|

        # Figure out whether or not we need to poll this market

      end
    end

  end

end

config = {
  "username" => "some_username", 
  "password" => "some_password", 
  "product_id" => 22, 
  "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
  "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService",
  "silks_base_url" => "http://content-cache.betfair.com/feeds_images/Horses/SilkColours/"
}

Betfair::SimpleBot.new(config)