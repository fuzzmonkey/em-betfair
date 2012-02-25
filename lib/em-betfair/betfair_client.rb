require 'uri'
require 'em-http'
require 'nokogiri'
#require 'tzinfo'

module Betfair

  BETFAIR_TIME_ZONES = {"RSA"=>"Africa/Johannesburg", "AST"=>"US/Arizona", "MST"=>"US/Mountain", "JPT"=>"Japan", "HK"=>"Hongkong", "GMT"=>"GMT", "PKT"=>"Etc/GMT-5", "UAE"=>"Asia/Dubai", "CST"=>"US/Central", "AKST"=>"US/Alaska", "BRT"=>"Brazil/East", "INT"=>"Asia/Calcutta", "SMT"=>"America/Santiago", "MSK"=>"Europe/Moscow", "AWST"=>"Australia/Perth", "PST"=>"US/Pacific", "EST"=>"US/Eastern", "KMT"=>"Jamaica", "CET"=>"CET", "ANST"=>"Australia/Darwin", "ACST"=>"Australia/Adelaide", "NZT"=>"NZ", "UKT"=>"Europe/London", "AMT"=>"Brazil/West", "THAI"=>"Asia/Bangkok", "SJMT"=>"America/Costa_Rica", "HST"=>"US/Hawaii", "EET"=>"EET", "AEST"=>"Australia/Sydney", "IEST"=>"America/Indiana/Indianapolis", "AQST"=>"Australia/Queensland"}

  class Client

    attr_accessor :session_token

    def initialize config
      @config = config
      @session_token = false
    end

    def login &block
      build_request "global", "login", {"username" => @config["username"], "password" => @config["password"], "product_id" => @config["product_id"]}, block
    end

    def get_all_markets countries=nil, event_type_ids=nil, to_date=nil, from_date=nil, &block
      with_session do
        build_request "exchange", "get_all_markets", {"countries" => countries, "event_type_ids" => event_type_ids, "to_date" => to_date, "from_date" => from_date}, block
      end
    end

    def get_market market_id, &block
      with_session do
        build_request "exchange", "get_market", {"market_id" => market_id }, block
      end
    end

    # def get_market_prices_compressed market_id, currency_code=nil
    #   with_session do
    #     build_request "exchange", "get_market_prices_compressed", {"market_id" => market_id, "currency_code" => currency_code}
    #   end
    # end
    # 
    # def get_market_traded_volume_compressed market_id, currency_code=nil
    #   with_session do
    #     build_request "exchange", "get_market_traded_volume_compressed", {"market_id" => market_id, "currency_code" => currency_code}
    #   end
    # end

    private

    def build_request service_name, action, data={}, block
      request_data = { :data => data.merge!({"session_token" => @session_token}) }
      soap_req = Betfair::SOAPRenderer.new( service_name, action ).render( request_data )
      url = get_endpoint service_name
      headers = { 'SOAPAction' => action, 'Accept-Encoding' => 'gzip,deflate', 'Content-type' => 'text/xml;charset=UTF-8' }
      req = EventMachine::HttpRequest.new(url).post :body => soap_req, :head => headers
      req.errback { puts "Failed to make request : #{service_name}-#{action}."  }
      req.callback { parse_response(req.response,block) }
    end

    def with_session
      yield if @session_token
      login do |response|
        yield
      end
    end

    def parse_response raw_rsp, block
      parsed_response = Nokogiri::XML raw_rsp
      api_error = parsed_response.xpath("//header/errorCode").text

      method_error = parsed_response.xpath("//errorCode").last.text

      # TODO - unless its login failed, set the session token to nil and try and login again

      error_rsp = api_error == "OK" ? method_error : api_error
      unless api_error == "OK" && method_error == "OK"
        block.call(Response.new(raw_rsp,parsed_response,false,error_rsp))
        return
      end

      session = parsed_response.xpath("//sessionToken").text
      @session_token = session
      block.call Response.new(raw_rsp,parsed_response,true)
    end

    def get_endpoint service_name
      return @config["#{service_name}_endpoint"]
    end

  end

end