module BetFair

  # TODO - version this to handle changes in the API
  module ResponseParser

    # TODO - handle timezones, return local & utc time
    # tz = TZInfo::Timezone.get(new_time_zone)
    # race_time = tz.utc_to_local(race_time)

    def login xml
      {"currency" => xml.xpath("//currency").text}
    end

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

    def get_market xml
      market_hash = {}
      market_hash["id"] = xml.xpath("//market/marketId").text
      market_hash["parent_id"] = xml.xpath("//market/parentEventId").text
      market_hash["country_code"] = xml.xpath("//market/countryISO3").text
      market_hash["event_type"] = xml.xpath("//market/eventTypeId").text
      market_hash["base_rate"] = xml.xpath("//market/marketBaseRate").text
      market_hash["market_name"] = xml.xpath("//market/name").text
      market_hash["num_winners"] = xml.xpath("//market/numberOfWinners").text
      market_hash["runners"] = []

      xml.xpath("//runners").children.each do |xml_runner|
        name = xml_runner.xpath("name").text
        selection_id = xml_runner.xpath("selectionId").text
        market_hash["runners"].push({:selection_id => selection_id, :name => name})
      end

      market_hash
    end

  end

end