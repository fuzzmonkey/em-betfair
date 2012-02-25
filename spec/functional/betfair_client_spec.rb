require 'spec_helper'
require 'webmock/rspec'

config = {
  "username" => "some_username", 
  "password" => "some_password", 
  "product_id" => 22, 
  "exchange_endpoint" => "http://exchange.betfair.com", #"https://api.betfair.com/exchange/v5/BFExchangeService",
  "global_endpoint" => "http://global.betfair.com" #"https://api.betfair.com/global/v3/BFGlobalService"
}

describe Betfair::Client do

  before :all do
    @bf_client = Betfair::Client.new(config)
  end

  describe "with no session token" do

    it "shouldn't be successfull" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_failed.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("get_all_markets_no_session.xml"), :status => 200)
      EM::run {
        @bf_client.get_all_markets do |rsp|
          rsp.successfull.should eq false
          rsp.error.should eq "NO_SESSION"
          EM::stop
        end
      }
    end

  end

  describe "login" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      EM::run {
        @bf_client.login do |rsp|
          rsp.successfull.should eq true
          # rsp.hash_response.should eq true
          rsp.error.should eq ""
          EM::stop
        end
      }
    end

    it "should handle invalid username/password" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_failed.xml"), :status => 200)
      EM::run {
        @bf_client.login do |rsp|
          rsp.successfull.should eq false
          rsp.error.should eq "INVALID_USERNAME_OR_PASSWORD"
          EM::stop
        end
      }
    end

  end

  describe "get_all_markets" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("get_all_markets.xml"), :status => 200)
      EM::run {
        @bf_client.get_all_markets do |rsp|
          rsp.successfull.should eq true
          rsp.error.should eq ""
          # rsp.hash_response.should eq true
          rsp.parsed_response.xpath("//marketData").text.should_not eq ""
          EM::stop
        end
      }
    end

  end

  describe "get_market" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("get_market.xml"), :status => 200)
      EM::run {
        @bf_client.get_market "104968439" do |rsp|
          rsp.successfull.should eq true
          rsp.error.should eq ""
          # rsp.hash_response.should eq true
          rsp.parsed_response.xpath("//runners").children.should_not be_empty
          EM::stop
        end
      }
    end

  end

  describe "get_all_markets" do

  end

  describe "get_market_prices_compressed" do

  end

  describe "get_market_traded_volume_compressed" do

  end

end