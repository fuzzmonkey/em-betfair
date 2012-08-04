require 'eventmachine'
require 'em-betfair'
require 'json'
require 'em-redis'

require 'date'
require 'logger'
require 'yaml'
require 'pathname'
require_relative 'em_redis_patch'

BASE = Pathname.new(__FILE__).realpath.parent

module Betfair

  class SimpleBot
    
    # TODO - need a proper filter on markets to call 'get_market' on

    def initialize config
      EM::run {
        Fiber.new {
          @logger = Logger.new(STDOUT)
          @logger.info "Betfair::SimpleBot started"
          @bf_client = Betfair::Client.new(config, @logger)
          @redis = EM::Protocols::Redis.connect
          @include_place_markets = false
          EventMachine::PeriodicTimer.new(60) { Fiber.new { update_markets }.resume }
        }.resume
      }
    end

    def update_markets
      @logger.debug "Fetching markets"
      markets_response = @bf_client.get_all_markets ["GBR"], [7], "#{Date.today} 00:00:00", "#{Date.today} 23:59:00"

      unless markets_response.successfull
        @logger.error markets_response.error
        return
      end

      # update the status of the market in redis, if it's changed (e.g != ACTIVE), cancel any pollers
      # if we have the market, don't call get_market

      markets_response.hash_response["bsp_markets"].each do |bsp_market|
        if bsp_market["status"] != "ACTIVE" || !@include_place_markets && bsp_market["name"] == "To Be Placed"
          # @redis.del bsp_market["id"] # clear out the market if it's over?
          next
        end

        menu_path = bsp_market["menu_path"]
        track_name = menu_path.match(/\\.+\\.+\\(\w+\s{0,1}\w*)/)[1]
        bsp_market["track_name"] = track_name

        market = @redis.hget track_name, bsp_market["id"]
        market = market ? JSON.parse(market) : bsp_market

        @logger.debug "Got market #{bsp_market["track_name"]} #{bsp_market["name"]} #{bsp_market["id"]}"

        if market["details"]
          @logger.debug market["details"]["market_time"]
        else
          market_details = @bf_client.get_market(bsp_market["id"])
          if market_details.successfull
            market["details"] = market_details.hash_response
          else
            @logger.error market_details.error
          end
        end

        @redis.hset track_name, bsp_market["id"], market.to_json
      end
    end

  end

end

config = YAML::load( File.open( BASE + 'etc/config.yml' ) )
Betfair::SimpleBot.new(config)