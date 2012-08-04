# Utility class for chopping up Betfair API responses and turning them into hashes

module Betfair

  # TODO - version this to handle changes in the API
  # TODO - this might be nicer as a structs style setup. e.g
  # markets_rsp = GetAllMarkets.new(parsed_response)
  module ResponseParser

    # TODO - handle timezones, return local & utc time
    # tz = TZInfo::Timezone.get(new_time_zone)
    # race_time = tz.utc_to_local(race_time)

    # TODO - return values as proper types rather than strings

    def login xml
      {"currency" => xml.xpath("//currency").text}
    end

    # @param xml Nokogiri XML object
    # @return hash of get_all_markets response
    def get_all_markets xml
      market_data = xml.xpath("//marketData").text
      all_markets_hash = {"market_data" => {}}
      market_data.split(":").each do |market|
        market_fields = market.split("~")
        next unless market_fields.size >= 16 #incase they append more fields
        market_hash = {}
        market_hash["id"] = market_fields[0]
        market_hash["name"] = market_fields[1]
        market_hash["type"] = market_fields[2]
        market_hash["status"] = market_fields[3]
        market_hash["date"] = Time.at(market_fields[4].to_i/1000).utc #Epoc time
        market_hash["menu_path"] = market_fields[5]
        market_hash["event_hierarchy"] = market_fields[6]
        market_hash["bet_delay"] = market_fields[7]
        market_hash["exchange_id"] = market_fields[8]
        market_hash["country_code"] = market_fields[9]
        market_hash["last_refresh"] = Time.at(market_fields[10].to_i/1000).utc #Epoc time
        market_hash["num_runners"] = market_fields[11]
        market_hash["num_winners"] = market_fields[12]
        market_hash["total_amount_matched"] = market_fields[13]
        market_hash["bsp_market"] = market_fields[14] == "Y"
        market_hash["turning_in_play"] = market_fields[15] == "Y"

        all_markets_hash["market_data"][market_fields[0]] = market_hash
      end
      all_markets_hash
    end

    # @param xml Nokogiri XML object
    # @return hash of get_market response
    def get_market xml
      market_hash = {}
      market_hash["id"] = xml.xpath("//market/marketId").text
      market_hash["status"] = xml.xpath("//market/marketStatus").text
      market_hash["parent_id"] = xml.xpath("//market/parentEventId").text
      market_hash["country_code"] = xml.xpath("//market/countryISO3").text
      market_hash["event_type"] = xml.xpath("//market/eventTypeId").text
      market_hash["base_rate"] = xml.xpath("//market/marketBaseRate").text
      market_hash["market_name"] = xml.xpath("//market/name").text
      market_hash["num_winners"] = xml.xpath("//market/numberOfWinners").text
      market_hash["market_time"] = xml.xpath("//market/marketTime").text

      market_hash["runners"] = []

      xml.xpath("//runners").children.each do |xml_runner|
        name = xml_runner.xpath("name").text
        selection_id = xml_runner.xpath("selectionId").text
        market_hash["runners"].push({"selection_id" => selection_id, "name" => name})
      end

      market_hash
    end

    def get_silks_v2 xml
      markets = {}
      n2 = "http://www.betfair.com/publicapi/types/exchange/v5/"
      xml.xpath("//marketDisplayDetails/n2:MarketDisplayDetail", "n2" => n2).each do |market_xml|
        market_id = market_xml.xpath("marketId").text
        markets[market_id] = {"runners" => {} }
        market_xml.xpath("racingSilks/n2:RacingSilk","n2" => n2).each do |xml_racing_silk|
          selection_id = xml_racing_silk.xpath("selectionId").text
          runner_hash = {}
          markets[market_id]["runners"][selection_id] = runner_hash

          runner_hash["silks_url"] = xml_racing_silk.xpath("silksURL").text
          runner_hash["silks_text"] = xml_racing_silk.xpath("silksText").text

          runner_hash["trainer_name"] = xml_racing_silk.xpath("trainerName").text
          runner_hash["age_weight"] = xml_racing_silk.xpath("ageWeight").text
          runner_hash["form"] = xml_racing_silk.xpath("form").text
          runner_hash["days_since"] = xml_racing_silk.xpath("daysSince").text
          runner_hash["jockey_claim"] = xml_racing_silk.xpath("jockeyClaim").text
          runner_hash["wearing"] = xml_racing_silk.xpath("wearing").text
          runner_hash["saddle_cloth"] = xml_racing_silk.xpath("saddleCloth").text
          runner_hash["stall_draw"] = xml_racing_silk.xpath("stallDraw").text
          runner_hash["owner_name"] = xml_racing_silk.xpath("ownerName").text
          runner_hash["jockey_name"] = xml_racing_silk.xpath("jockeyName").text
          runner_hash["colour"] = xml_racing_silk.xpath("colour").text
          runner_hash["sex"] = xml_racing_silk.xpath("sex").text
          runner_hash["bred"] = xml_racing_silk.xpath("bred").text
          forecast_numerator = xml_racing_silk.xpath("forecastPriceNumerator").text
          forecast_denominator = xml_racing_silk.xpath("forecastPriceDenominator").text
          runner_hash["forecast_price"] = "#{forecast_numerator}/#{forecast_denominator}"
          runner_hash["official_rating"] = xml_racing_silk.xpath("officialRating").text
          
          runner_hash["sire"] = {}
          runner_hash["sire"]["name"] = xml_racing_silk.xpath("sire/name").text
          runner_hash["sire"]["bred"] = xml_racing_silk.xpath("sire/bred").text
          runner_hash["sire"]["year_born"] = xml_racing_silk.xpath("sire/yearBorn").text

          runner_hash["dam"] = {}
          runner_hash["dam"]["name"] = xml_racing_silk.xpath("dam/name").text
          runner_hash["dam"]["bred"] = xml_racing_silk.xpath("dam/bred").text
          runner_hash["dam"]["year_born"] = xml_racing_silk.xpath("dam/yearBorn").text
          
          runner_hash["dam_sire"] = {}
          runner_hash["dam_sire"]["name"] = xml_racing_silk.xpath("damSire/name").text
          runner_hash["dam_sire"]["bred"] = xml_racing_silk.xpath("damSire/bred").text
          runner_hash["dam_sire"]["year_born"] = xml_racing_silk.xpath("damSire/yearBorn").text

        end
      end
      markets
    end

    # @param xml Nokogiri XML object
    # @return hash of get_market_prices_compressed response
    def get_market_prices_compressed xml
      prices_hash = {}
      prices = xml.xpath("//marketPrices").text
      # Betfair uses colons as a seperator and escaped colons as a different seperator, grr.
      # [1..-1] removes the first empty string
      prices_data = prices.gsub('\:', 'ECSCOLON')[1..-1].split(":")

      header_data = prices_data.slice!(0).gsub("ECSCOLON",":").split("~")

      # TODO - parse removed runners properly
      ["market_id","currency","status","in_play_delay","num_winners","market_info","discount_allowed","market_base_rate","refresh_time","removed_runners","bsp_market"].each_with_index do |field,index|
        prices_hash[field] = header_data.at(index)
      end

      prices_data.each do |runner|
        runner_hash = {}
        runner_info, lay_prices, back_prices = runner.split("|")
        runner_data = runner_info.split("~")

        ["selection_id","order_index","total_matched","last_price_matched","handicap","reduction_factor","vacant","asian_line_id","far_sp_price","near_sp_price","actual_sp_price"].each_with_index do |field,index|
          runner_hash[field] = runner_data.at(index)
        end

        runner_hash["lay_prices"] = []
        lay_prices.split("~").each_slice(4) do |prices|
          runner_hash["lay_prices"].push({"odds" => prices[0], "amount" => prices[1], "type" => prices[2], "depth" => prices[3]})
        end

        runner_hash["back_prices"] = []
        back_prices.split("~").each_slice(4) do |prices|
          runner_hash["back_prices"].push({"odds" => prices[0], "amount" => prices[1], "type" => prices[2], "depth" => prices[3]})
        end

        prices_hash[runner_hash["selection_id"]] = runner_hash
      end
      prices_hash
    end

    # @param xml Nokogiri XML object
    # @return hash of get_market_traded_volume_compressed response
    def get_market_traded_volume_compressed xml
      traded_volumne_hash = {}
      traded = xml.xpath("//tradedVolume").text
      market_id = xml.xpath("//marketId").text
      currency = xml.xpath("//currencyCode").text
      # Betfair uses colons as a seperator and escaped colons as a different seperator, grr.
      # [1..-1] removes the first empty string
      traded_data = traded.gsub(/\\:/, "ECSCOLON")[1..-1].split(":")
      traded_data.each do |runner|
        # TODO - replace ECSCOLON with : 
        runner_hash = {"traded_amounts" => []}
        runner_data = runner.split("|")
        header_data = runner_data.slice!(0).split("~")
        ["selection_id", "asian_line_id", "bsp", "total_bsp_back_matched", "total_bsp_liability_matched"].each_with_index do |field,index|
          runner_hash[field] = header_data.at(index)
        end
        runner_data.each do |traded_amount|
          odds, total_matched = traded_amount.split("~")
          runner_hash["traded_amounts"].push({"odds" => odds, "total_matched" => total_matched})
        end
        traded_volumne_hash[runner_hash["selection_id"]] = runner_hash
      end
      traded_volumne_hash
    end

    def place_bets xml
      place_bets_array = []
      # TODO do the bets come back in the same order of the request ?
      xml.xpath("//betResults/n2:PlaceBetsResult","n2" => "http://www.betfair.com/publicapi/types/exchange/v5/").each do |bet_xml|
        bet_respose = {}
        bet_respose["average_price_matched"] = bet_xml.xpath("averagePriceMatched").text
        bet_respose["bet_id"] = bet_xml.xpath("betId").text
        bet_respose["result_code"] = bet_xml.xpath("resultCode").text
        bet_respose["size_matched"] = bet_xml.xpath("sizeMatched").text
        bet_respose["success"] = bet_xml.xpath("success").text
        place_bets_array << bet_respose
      end
      place_bets_array
    end

  end

end