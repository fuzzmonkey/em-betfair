require 'spec_helper'
require 'webmock/rspec'
require 'logger'

config = {
  "username" => "some_username", 
  "password" => "some_password", 
  "product_id" => 22, 
  "exchange_endpoint" => "http://exchange.betfair.com", #"https://api.betfair.com/exchange/v5/BFExchangeService",
  "global_endpoint" => "http://global.betfair.com", #"https://api.betfair.com/global/v3/BFGlobalService"
  "silks_base_url" => "http://content-cache.betfair.com/feeds_images/Horses/SilkColours/"
}

describe Betfair::Client do

  before :all do
    logger = Logger.new(STDOUT)
    @bf_client = Betfair::Client.new(config, logger)
  end

  describe "SOAP faults" do

    it "should handle SOAP faults" do
        stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
        stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("soap_fault.xml"), :status => 500)
        EM::run {
          @bf_client.get_all_markets do |rsp|
            rsp.successfull.should eq false
            rsp.hash_response.should be_nil
            rsp.error.should eq "INTERNAL_ERROR"
            EM::stop
          end
        }
      end
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
          rsp.hash_response.should be_an_instance_of Hash
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
          rsp.hash_response.should be_an_instance_of Hash
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
          rsp.hash_response.should be_an_instance_of Hash
          rsp.parsed_response.xpath("//runners").children.should_not be_empty
          EM::stop
        end
      }
    end

  end

  describe "get_silks_v2" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("get_silks_v2.xml"), :status => 200)
      EM::run {
        @bf_client.get_silks_v2 ["104968439"] do |rsp|
          rsp.successfull.should eq true
          rsp.error.should eq ""
          rsp.hash_response.should be_an_instance_of Hash
          rsp.parsed_response.xpath("//marketDisplayDetails").children.should_not be_empty
          EM::stop
        end
      }
    end

  end

  describe "get_market_prices_compressed" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("get_market_prices_compressed.xml"), :status => 200)
      EM::run {
        @bf_client.get_market_prices_compressed "104968512" do |rsp|
          rsp.successfull.should eq true
          rsp.error.should eq ""
          rsp.hash_response.should be_an_instance_of Hash
          rsp.parsed_response.xpath("//marketPrices").first.should_not be_nil
          EM::stop
        end
      }
    end

  end

  describe "get_market_traded_volume_compressed" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("get_market_traded_volume_compressed.xml"), :status => 200)
      EM::run {
        @bf_client.get_market_prices_compressed "104968512" do |rsp|
          rsp.successfull.should eq true
          rsp.error.should eq ""
          rsp.hash_response.should be_an_instance_of Hash
          rsp.parsed_response.xpath("//tradedVolume").first.should_not be_nil
          EM::stop
        end
      }
    end

  end

  # TODO - test for multiple bets
  describe "place_bets" do

    it "should handle an OK response" do
      stub_request(:post, "http://global.betfair.com").to_return(:body => load_response("login_ok.xml"), :status => 200)
      stub_request(:post, "http://exchange.betfair.com").to_return(:body => load_response("place_bets.xml"), :status => 200)
      EM::run {
        bet = {"size" => 5.0, "asian_line_id" => 0, "bet_type" => "B", "bet_type_category_type" => "E", "bet_persistence_type" => "NONE", "market_id" => 1, "price" => 2.0, "selection_id" => 12300, "bsp_liability" => 0 }
        @bf_client.place_bets [bet] do |rsp|
          rsp.successfull.should eq true
          rsp.error.should eq ""
          rsp.hash_response.should be_an_instance_of Array
          rsp.parsed_response.xpath("//betResults/n2:PlaceBetsResult/betId", "n2" => "http://www.betfair.com/publicapi/types/exchange/v5/").text.should_not be_nil
          EM::stop
        end
      }
    end

  end

end