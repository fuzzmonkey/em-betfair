require 'spec_helper'
require 'webmock/rspec'

config = {
  "username" => "some_username", 
  "password" => "some_password", 
  "product_id" => 22, 
  "exchange_endpoint" => "http://exchange.betfair.com", #"https://api.betfair.com/exchange/v5/BFExchangeService",
  "global_endpoint" => "http://global.betfair.com", #"https://api.betfair.com/global/v3/BFGlobalService"
  "silks_base_url" => "http://content-cache.betfair.com/feeds_images/Horses/SilkColours/"
}

describe Betfair::Client do

  describe "free API" do

    it "should enable rate limiting" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").with(:headers => {"SOAPAction" => "get_all_markets"}).to_return(:body => load_response("get_all_markets.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").with(:headers => {"SOAPAction" => "get_market"}).to_return(:body => load_response("get_market.xml"), :status => 200)
      EM::run {
        bf_client = Betfair::Client.new(config)
        bf_client.get_all_markets do |rsp|
          rsp.hash_response["market_data"].each do |mkt_id,market_data|
            bf_client.get_market mkt_id do |rsp|
              puts "Got data for #{mkt_id}"
            end
          end
        end
      }
    end

  end

  # describe "paid API" do
  # 
  #   it "should not enable rate limiting" do
  #     EM::run {
  #       bf_client = Betfair::Client.new(config)
  #     }
  #   end
  # 
  # end

end