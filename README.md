# Betfair API client using Eventmachine and EM-Http

em-betfair is a work in progress evented client for the Betfair API. The following API calls have been implemented :

- login
- getMarket
- getSilksV2
- getAllMarkets
- getMarketPricesCompressed
- getMarketTradedVolumeCompressed
- placeBets

# Usage

	gem install em-betfair

	gem "em-betfair", "~> 0.3"

Create an instance of the client

	config = {
	  "username" => "<YOUR BETFAIR USERNAME>",
	  "password" => "<YOUR BETFAIR PASSWORD>", 
	  "product_id" => "<YOUR BETFAIR PRODUCTID>", 
	  "exchange_endpoint" => "https://api.betfair.com/exchange/v5/BFExchangeService",
	  "global_endpoint" => "https://api.betfair.com/global/v3/BFGlobalService"
	}
	# Need to create the client inside the reactor for the periodic timer for handling rate limiting to be initialised.
	EM::run {
		logger = Logger.new(STDOUT) #optional
		bf_client = Betfair::Client.new(config,logger)
	}

Making a call to the API:

	EM::run {
		Fiber.new do
			rsp = bf_client.get_all_markets

			rsp.successfull # boolean for success
			rsp.error # API error message if not successfull

			rsp.raw_response # access the raw response body
			rsp.parsed_response # access the Nokogiri XML object of the raw response
			rsp.hash_response # access a hash of the response data
		end.resume
	}

Note, logging in to the API is handled internally by the client.

# Rate Limiting

If you're using the free access Betfair API then you will be subject to rate limiting. Going over the limits can incur charges on your account. To accommodate this, the em-betfair client has built in support for rate limits using EventMachine timers. As requests are made, an internal hash is updated containing the request type and number of requests made. This hash is reset every 60 seconds. Before each request to the API is made, the number of requests for the given request is checked against the rate limits and the request delayed by 30 seconds if the limit has been reached.

For more information on the rate limits imposed on the free access API see [here](http://bdp.betfair.com/index.php?option=com_content&task=view&id=36&Itemid=62).

# TODO

 * Add support for Fibers to untangle the code.
 * Improve rate limit hash reaper. It might be better to timestamp each request and only delete requests over 60s old, rather than blowing away the entire hash.
 * Finish / improve rate limit tests.
 * Handle login / session management better.

# Ruby versions

Tested on 1.9.2 but should work on 1.8.7 too.
