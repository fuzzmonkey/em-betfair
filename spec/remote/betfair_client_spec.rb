require 'spec_helper'

config = {
  "username" => "<YOUR BETFAIR USERNAME>",
  "password" => "<YOUR BETFAIR PASSWORD>", 
  "product_id" => "<YOUR BETFAIR PRODUCTID>", 
  "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
  "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
}

describe BetFair::Client do

  before :all do
    @bf_client = BetFair::Client.new(config)
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

end
