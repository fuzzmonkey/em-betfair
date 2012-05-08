require 'spec_helper'

config = {
  "username" => "<YOUR BETFAIR USERNAME>",
  "password" => "<YOUR BETFAIR PASSWORD>", 
  "product_id" => "<YOUR BETFAIR PRODUCTID>", 
  "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
  "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
}

describe Betfair::Client do

  before :all do
    @bf_client = Betfair::Client.new(config)
  end

  describe "get_all_markets" do

    it "should work against a remote API" do
      # EM::run {
      #   @bf_client.get_all_markets ["GBR"],[7] do |response|
      #     puts response.raw_response
      #     EM::stop
      #   end
      # }
    end

  end

  describe "get_market" do

    it "should work against a remote API" do
      # EM::run {
      #   @bf_client.get_market "104968439" do |response|
      #     puts response.raw_response
      #     EM::stop
      #   end
      # }
    end

  end

  describe "get_silks_v2" do

    it "should work against a remote API" do
      # EM::run {
      #   @bf_client.get_silks_v2 [105668397] do |response|
      #     puts response.raw_response
      #     EM::stop
      #   end
      # }
    end

  end
  
  describe "get_market_prices_compressed" do

    it "should work against a remote API" do
      # EM::run {
      #   @bf_client.get_market_prices_compressed "104968512" do |response|
      #     puts response.raw_response
      #     EM::stop
      #   end
      # }
    end

  end
  
  describe "get_market_traded_volume_compressed" do

    it "should work against a remote API" do
      # EM::run {
      #   @bf_client.get_market_traded_volume_compressed "104968512" do |response|
      #     puts response.raw_response
      #     EM::stop
      #   end
      # }
    end

  end

end
