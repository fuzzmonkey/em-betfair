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

    def initialize config
      EM::run {
        Fiber.new {
          @logger = Logger.new(STDOUT)
          @bf_client = Betfair::Client.new(config, @logger)
          @redis = EM::Protocols::Redis.connect
          @logger.info "Betfair::SimpleBot started"
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
        if bsp_market["status"] != "ACTIVE"
          # @redis.del bsp_market["id"] # clear out the market if it's over?
          next
        end

        menu_path = bsp_market["menu_path"]
        track_name = menu_path.match(/\\.+\\.+\\(\w+\s{0,1}\w*)/)[1]

        market = @redis.get bsp_market["id"]
        market = market ? JSON.parse(market) : {"market_details" => bsp_market, "runners" => [], "market_name" => track_name}

        @logger.debug "Got market #{track_name} #{bsp_market["name"]}"

        if market["runners"].empty?
          market_details = @bf_client.get_market(bsp_market["id"]).hash_response
          market["runners"] = market_details["runners"]
        end

        @redis.set bsp_market["id"], market.to_json

        # Figure out whether or not we need to poll this market
      end
    end

  end

end

config = YAML::load( File.open( BASE + 'etc/config.yml' ) )
Betfair::SimpleBot.new(config)