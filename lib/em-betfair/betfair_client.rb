# Betfair::Client

require 'uri'
require 'em-http'
require 'nokogiri'
require 'logger'
require 'fiber'
#require 'tzinfo'

module Betfair

  BETFAIR_TIME_ZONES = {"RSA"=>"Africa/Johannesburg", "AST"=>"US/Arizona", "MST"=>"US/Mountain", "JPT"=>"Japan", "HK"=>"Hongkong", "GMT"=>"GMT", "PKT"=>"Etc/GMT-5", "UAE"=>"Asia/Dubai", "CST"=>"US/Central", "AKST"=>"US/Alaska", "BRT"=>"Brazil/East", "INT"=>"Asia/Calcutta", "SMT"=>"America/Santiago", "MSK"=>"Europe/Moscow", "AWST"=>"Australia/Perth", "PST"=>"US/Pacific", "EST"=>"US/Eastern", "KMT"=>"Jamaica", "CET"=>"CET", "ANST"=>"Australia/Darwin", "ACST"=>"Australia/Adelaide", "NZT"=>"NZ", "UKT"=>"Europe/London", "AMT"=>"Brazil/West", "THAI"=>"Asia/Bangkok", "SJMT"=>"America/Costa_Rica", "HST"=>"US/Hawaii", "EET"=>"EET", "AEST"=>"Australia/Sydney", "IEST"=>"America/Indiana/Indianapolis", "AQST"=>"Australia/Queensland"}
  REQUEST_RATE_LIMITS = {"login" => 24, "get_market" => 5, "get_market_info" => 5, "get_market_prices_compressed" => 60, "get_market_traded_volume_compressed" => 60 }
  FREE_PRODUCT_ID = 82

  class Client

    attr_accessor :session_token

    # @param [Hash] config hash of betfair credentials & API endpoints
    #                   { "username" => "<YOUR BETFAIR USERNAME>", "password" => "<YOUR BETFAIR PASSWORD>", "product_id" => "<YOUR BETFAIR PRODUCTID>", "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService", "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService" }
    # @param [Object] logger optional class for logging that responds to debug and error
    def initialize config, logger=nil
      @config = config
      @session_token = nil
      @num_requests = {}
      @logger = logger if logger
      EventMachine::PeriodicTimer.new(60) { reset_requests } if EM.reactor_running?
    end

    # Creates a session on the Betfair API, used by Betfair::Client internally to maintain session.
    def login
      make_request "global", "login", {"username" => @config["username"], "password" => @config["password"], "product_id" => @config["product_id"]}
    end

    # Returns all the available markets on Betfair.
    #
    # @param [Array] countries array of ISO 3166-1 country codes
    # @param [Array] event_type_ids array of Betfair event ids
    # @param [DateTime] to_date start time range of events to retrieve
    # @param [DateTime] from_date end time range of events to retrieve
    # @return [Betfair::Response]
    def get_all_markets countries=nil, event_type_ids=nil, to_date=nil, from_date=nil
      with_session do
        make_request "exchange", "get_all_markets", {"countries" => countries, "event_type_ids" => event_type_ids, "to_date" => to_date, "from_date" => from_date}
      end
    end

    # Returns the details for a specifc market.
    # 
    # @param [String] market_id Betfair market ID
    # @return [Betfair::Response]
    def get_market market_id
      with_session do
        make_request "exchange", "get_market", {"market_id" => market_id }
      end
    end

    # Returns the runner details for specifc markets.
    # 
    # @param [Array] market_ids Betfair market IDs
    # @return [Betfair::Response]
    def get_silks_v2 market_ids
      with_session do
        make_request "exchange", "get_silks_v2", {"market_ids" => market_ids }
      end
    end

    # Returns the compressed market prices for a specifc market.
    # 
    # @param [String] market_id Betfair market ID
    # @param [String] currency_code three letter ISO 4217 country code
    # @return [Betfair::Response]
    def get_market_prices_compressed market_id, currency_code=nil
      with_session do
        make_request "exchange", "get_market_prices_compressed", {"market_id" => market_id, "currency_code" => currency_code}
      end
    end

    # Returns the compressed traded volumes for a specifc market.
    # 
    # @param [String] market_id Betfair market ID
    # @param [String] currency_code three letter ISO 4217 country code
    # @return [Betfair::Response]
    def get_market_traded_volume_compressed market_id, currency_code=nil
      with_session do
        make_request "exchange", "get_market_traded_volume_compressed", {"market_id" => market_id, "currency_code" => currency_code}
      end
    end

    # Places bets on the BetFair API
    # 
    # @param [Array] bets Array of bets to be placed
    # @return [Betfair::Response]
    def place_bets bets
      with_session do
        make_request "exchange", "place_bets", {"bets" => bets}
      end
    end

    private

    # Makes the EM::Http request
    # 
    # service_name -    the endpoint to use (exchange or global)
    # action -          the API method to call on the API
    # data -            hash of parameters to populate the SOAP request
    def make_request service_name, request_action, data={}
      log :debug, "building request #{service_name} #{request_action}"
      if defer_request? request_action
        EventMachine::Timer.new(30) { build_request(make_request, request_action, data) }
        return
      end
      increment_num_requests request_action unless @session_token && request_action == "login"
      request_data = { :data => data.merge!({"session_token" => @session_token}) }
      soap_req = Betfair::SOAPRenderer.new( service_name, request_action ).render( request_data )
      log :debug, soap_req
      url = get_endpoint service_name
      headers = { 'SOAPAction' => request_action, 'Accept-Encoding' => 'gzip,deflate', 'Content-type' => 'text/xml;charset=UTF-8' }
      f = Fiber.current
      request = EventMachine::HttpRequest.new(url).post :body => soap_req, :head => headers
      request.callback { f.resume(request) }
      request.errback  { f.resume(request) }
      Fiber.yield
      return Response.new(nil,nil,false,"Error connecting to the API") if request.error
      return parse_response(request_action,request.response) unless request.error
    end

    # Parses the API response, building a response object
    # 
    # @param [String] request_action SOAP action of the request
    # @param [String] raw_rsp  response body from EM:Http request
    def parse_response request_action, raw_rsp
      log :debug, raw_rsp
      parsed_response = Nokogiri::XML raw_rsp

      soap_fault = parsed_response.xpath("//faultstring").first
      if soap_fault
        log :error, "SOAP Error: #{soap_fault.text}"
        return Response.new(raw_rsp,parsed_response,false,soap_fault.text)
      end

      api_error = parsed_response.xpath("//header/errorCode").text
      method_error = parsed_response.xpath("//errorCode").last.text

      error_rsp = api_error == "OK" ? method_error : api_error
      unless api_error == "OK" && method_error == "OK"
        log :error, "API Error: #{api_error} | METHOD Error: #{method_error}"
        @session_token = nil if [api_error,method_error].include?("NO_SESSION") # so we try and login on the next request
        return Response.new(raw_rsp,parsed_response,false,error_rsp)
      end
      @session_token = parsed_response.xpath("//sessionToken").text

      return Response.new(raw_rsp,parsed_response,true)
    end

    def with_session
      yield unless @session_token.nil?
      login
      yield
    end

    def get_endpoint service_name
      return @config["#{service_name}_endpoint"]
    end

    def increment_num_requests request_action
      @num_requests[request_action] ||= 0
      @num_requests[request_action] +=1
    end

    def reset_requests
      @num_requests = {}
    end

    # Checks the number of requests this minute against the free API rate limits
    # @param [String] request_action soap request to check limits for
    # @return [boolean] whether the request should be deferred
    def defer_request? request_action
      return false unless REQUEST_RATE_LIMITS[request_action] && @config["product_id"] != FREE_PRODUCT_ID
      defer = @num_requests[request_action].to_i >= REQUEST_RATE_LIMITS[request_action]
      log :debug, "Request rate limit: #{REQUEST_RATE_LIMITS[request_action]} | Requests this minute: #{@num_requests[request_action]} | Deferring - #{defer}"
      return defer
    end

    def log level, message
      @logger.send level, message if @logger
    end

  end

end