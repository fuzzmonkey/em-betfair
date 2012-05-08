# Betfair::Client

require 'uri'
require 'em-http'
require 'nokogiri'
#require 'tzinfo'

module Betfair

  BETFAIR_TIME_ZONES = {"RSA"=>"Africa/Johannesburg", "AST"=>"US/Arizona", "MST"=>"US/Mountain", "JPT"=>"Japan", "HK"=>"Hongkong", "GMT"=>"GMT", "PKT"=>"Etc/GMT-5", "UAE"=>"Asia/Dubai", "CST"=>"US/Central", "AKST"=>"US/Alaska", "BRT"=>"Brazil/East", "INT"=>"Asia/Calcutta", "SMT"=>"America/Santiago", "MSK"=>"Europe/Moscow", "AWST"=>"Australia/Perth", "PST"=>"US/Pacific", "EST"=>"US/Eastern", "KMT"=>"Jamaica", "CET"=>"CET", "ANST"=>"Australia/Darwin", "ACST"=>"Australia/Adelaide", "NZT"=>"NZ", "UKT"=>"Europe/London", "AMT"=>"Brazil/West", "THAI"=>"Asia/Bangkok", "SJMT"=>"America/Costa_Rica", "HST"=>"US/Hawaii", "EET"=>"EET", "AEST"=>"Australia/Sydney", "IEST"=>"America/Indiana/Indianapolis", "AQST"=>"Australia/Queensland"}

  class Client

    attr_accessor :session_token

    # config -          hash of betfair credentials & API endpoints
    #                   { "username" => "<YOUR BETFAIR USERNAME>", "password" => "<YOUR BETFAIR PASSWORD>", "product_id" => "<YOUR BETFAIR PRODUCTID>", "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService", "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService" }
    def initialize config
      @config = config
      @session_token = nil
    end

    # Rate limits
    # get_market 5
    # get_market_info
    # get_market_prices_compressed 60
    # get_market_traded_volume_compressed 60

    # Creates a session on the Betfair API, used by Betfair::Client internally to maintain session.
    def login &block
      build_request "global", "login", {"username" => @config["username"], "password" => @config["password"], "product_id" => @config["product_id"]}, block
    end

    # Returns all the available markets on Betfair.
    #
    # @param [Array] countries array of ISO 3166-1 country codes
    # @param [Array] event_type_ids array of Betfair event ids
    # @param [DateTime] to_date start time range of events to retrieve
    # @param [DateTime] from_date end time range of events to retrieve
    # @return [Betfair::Response]
    def get_all_markets countries=nil, event_type_ids=nil, to_date=nil, from_date=nil, &block
      with_session do
        build_request "exchange", "get_all_markets", {"countries" => countries, "event_type_ids" => event_type_ids, "to_date" => to_date, "from_date" => from_date}, block
      end
    end

    # Returns the details for a specifc market.
    # 
    # @param [String] market_id Betfair market ID
    # @return [Betfair::Response]
    def get_market market_id, &block
      with_session do
        build_request "exchange", "get_market", {"market_id" => market_id }, block
      end
    end

    # Returns the runner details for specifc markets.
    # 
    # @param [Array] market_ids Betfair market IDs
    # @return [Betfair::Response]
    def get_silks_v2 market_ids, &block
      with_session do
        build_request "exchange", "get_silks_v2", {"market_ids" => market_ids }, block
      end
    end

    # Returns the compressed market prices for a specifc market.
    # 
    # @param [String] market_id Betfair market ID
    # @param [String] currency_code three letter ISO 4217 country code
    # @return [Betfair::Response]
    def get_market_prices_compressed market_id, currency_code=nil, &block
      with_session do
        build_request "exchange", "get_market_prices_compressed", {"market_id" => market_id, "currency_code" => currency_code}, block
      end
    end

    # Returns the compressed traded volumes for a specifc market.
    # 
    # @param [String] market_id Betfair market ID
    # @param [String] currency_code three letter ISO 4217 country code
    # @return [Betfair::Response]
    def get_market_traded_volume_compressed market_id, currency_code=nil, &block
      with_session do
        build_request "exchange", "get_market_traded_volume_compressed", {"market_id" => market_id, "currency_code" => currency_code}, block
      end
    end

    private

    # Builds the EM::Http request object
    # 
    # service_name -    the endpoint to use (exchange or global)
    # action -          the API method to call on the API
    # data -            hash of parameters to populate the SOAP request
    # block -           the ballback for this request
    def build_request service_name, action, data={}, block
      request_data = { :data => data.merge!({"session_token" => @session_token}) }
      soap_req = Betfair::SOAPRenderer.new( service_name, action ).render( request_data )
      url = get_endpoint service_name
      headers = { 'SOAPAction' => action, 'Accept-Encoding' => 'gzip,deflate', 'Content-type' => 'text/xml;charset=UTF-8' }
      req = EventMachine::HttpRequest.new(url).post :body => soap_req, :head => headers
      req.errback { block.call(Response.new(nil,nil,false,"Error connecting to the API"))  }
      req.callback { parse_response(req.response,block) }
    end

    # Parses the API response, building a response object
    # 
    # @param [String] raw_rsp  response body from EM:Http request
    # block [block] block callback for this request
    def parse_response raw_rsp, block
      parsed_response = Nokogiri::XML raw_rsp

      soap_fault = parsed_response.xpath("//faultstring").first
      if soap_fault
        block.call(Response.new(raw_rsp,parsed_response,false,soap_fault.text))
        return
      end

      api_error = parsed_response.xpath("//header/errorCode").text
      method_error = parsed_response.xpath("//errorCode").last.text

      error_rsp = api_error == "OK" ? method_error : api_error
      unless api_error == "OK" && method_error == "OK"
        @session_token = nil if [api_error,method_error].include?("NO_SESSION") # so we try and login on the next request
        block.call(Response.new(raw_rsp,parsed_response,false,error_rsp))
        return
      end

      @session_token = parsed_response.xpath("//sessionToken").text

      block.call Response.new(raw_rsp,parsed_response,true)
    end

    def with_session
      yield unless @session_token.nil?
      login do |response|
        yield
      end
    end

    def get_endpoint service_name
      return @config["#{service_name}_endpoint"]
    end

  end

end