# Betfair API client using Eventmachine and EM-Http

em-betfair is a work in progress evented client for the Betfair API. The following API calls have been implemented :

- login
- getAllMarkets
- getMarket

# Usage

Create an instance of the client

	config = {
	  "username" => "<YOUR BETFAIR USERNAME>",
	  "password" => "<YOUR BETFAIR PASSWORD>", 
	  "product_id" => "<YOUR BETFAIR PRODUCTID>", 
	  "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
	  "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
	}
	bf_client = BetFair::Client.new(config)

Making a call to the API:

	EM::run {
	  bf_client.get_all_markets do |rsp|

	    rsp.raw_response # access the raw response body
	    rsp.parsed_response # access the Nokogiri XML object of the raw response

	    rsp.successfull # boolean for success
	    rsp.error # API error messge if not successfull

	  end
	}

Note, logging in to the API is handled internally by the client.