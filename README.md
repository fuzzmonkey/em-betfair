# Betfair API client using Eventmachine and EM-Http

em-betfair is a work in progress evented client for the Betfair API. The following API calls have been implemented :

- login
- getMarket
- getSilksV2
- getAllMarkets
- getMarketPricesCompressed
- getMarketTradedVolumeCompressed

# Usage

	gem install em-betfair

	gem "em-betfair", "~> 0.1"

Create an instance of the client

	config = {
	  "username" => "<YOUR BETFAIR USERNAME>",
	  "password" => "<YOUR BETFAIR PASSWORD>", 
	  "product_id" => "<YOUR BETFAIR PRODUCTID>", 
	  "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
	  "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
	}
	bf_client = Betfair::Client.new(config)

Making a call to the API:

	EM::run {
	  bf_client.get_all_markets do |rsp|

	    rsp.raw_response # access the raw response body
	    rsp.parsed_response # access the Nokogiri XML object of the raw response
	    rsp.hash_response # access a hash of the response data

	    rsp.successfull # boolean for success
	    rsp.error # API error message if not successfull

	  end
	}

Note, logging in to the API is handled internally by the client.

# Ruby versions

Tested on 1.9.2 but should work on 1.8.7 too.
