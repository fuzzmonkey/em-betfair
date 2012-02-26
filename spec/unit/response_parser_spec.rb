require 'spec_helper'

describe Betfair::ResponseParser do

  # Dummy class to test module
  module Betfair
    class Foo; include ResponseParser; end
  end

  before do
    @parser = Betfair::Foo.new
  end

  it "should parse login response" do
    login_xml = load_xml_response("login_ok.xml")
    parsed = @parser.login login_xml
    parsed.should == {"currency" => "GBP"}
  end

  it "should parse get_all_markets response" do
    get_all_markets_xml = load_xml_response("get_all_markets.xml")
    parsed = @parser.get_all_markets get_all_markets_xml
    parsed["market_data"].keys.size.should eq 246
    parsed["market_data"]["104968448"].should == {"id"=>"104968448", "name"=>"To Be Placed", "type"=>"O", "status"=>"ACTIVE", "date"=> Time.parse("2012-02-25 14:00:00 UTC"), "menu_path"=>"Horse RacingGBKemp 25th Feb", "event_hierarchy"=>"/7/298251/26813087/104968448", "bet_delay"=>"0", "exchange_id"=>"1", "country_code"=>"GBR", "last_refresh"=> Time.parse("2012-02-25 13:53:30 UTC"), "num_runners"=>"8", "num_winners"=>"3", "total_amount_matched"=>"33339.18", "bsp_market"=>true, "turning_in_play"=>true}
  end

  it "should parse get_market response" do
    get_market_xml = load_xml_response("get_market.xml")
    parsed = @parser.get_market get_market_xml
    parsed.should == {"id"=>"104968439", "parent_id"=>"26813086", "country_code"=>"GBR", "event_type"=>"7", "base_rate"=>"5.0", "market_name"=>"2m Hcap Chs", "num_winners"=>"1", "runners"=>[{"selection_id"=>"3043342", "name"=>"Arctic Ben"}, {"selection_id"=>"4493849", "name"=>"Educated Evans"}, {"selection_id"=>"2795387", "name"=>"Buffalo Bob"}, {"selection_id"=>"3687553", "name"=>"Rileyev"}, {"selection_id"=>"2610448", "name"=>"Oh Crick"}, {"selection_id"=>"2406110", "name"=>"Oscar Gogo"}, {"selection_id"=>"2446696", "name"=>"Dinarius"}, {"selection_id"=>"1381307", "name"=>"Moon Over Miami"}, {"selection_id"=>"2810086", "name"=>"Super Formen"}]}
  end

  it "should parse get_market_prices_compressed response" do
    compressed_prices_xml = load_xml_response("get_market_prices_compressed.xml")
    parsed = @parser.get_market_prices_compressed compressed_prices_xml
    parsed.should == {}
  end

  it "should parse get_market_traded_volume_compressed response" do
    compressed_traded_volumes_xml = load_xml_response("get_market_traded_volume_compressed.xml")
    parsed = @parser.get_market_traded_volume_compressed compressed_traded_volumes_xml
    parsed.should == {"2803150"=>{"traded_amounts"=>[{"odds"=>"25.0", "total_matched"=>"2.08"}, {"odds"=>"26.0", "total_matched"=>"3.92"}, {"odds"=>"28.0", "total_matched"=>"4.6"}, {"odds"=>"29.0", "total_matched"=>"3.7"}, {"odds"=>"34.0", "total_matched"=>"18.16"}, {"odds"=>"36.0", "total_matched"=>"0.08"}, {"odds"=>"38.0", "total_matched"=>"58.06"}, {"odds"=>"40.0", "total_matched"=>"27.74"}, {"odds"=>"42.0", "total_matched"=>"12.38"}, {"odds"=>"44.0", "total_matched"=>"63.26"}, {"odds"=>"46.0", "total_matched"=>"55.7"}, {"odds"=>"48.0", "total_matched"=>"29.38"}, {"odds"=>"50.0", "total_matched"=>"37.2"}, {"odds"=>"55.0", "total_matched"=>"17.92"}, {"odds"=>"130.0", "total_matched"=>"0.18"}], "selection_id"=>"2803150", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "4801791"=>{"traded_amounts"=>[{"odds"=>"14.5", "total_matched"=>"10.0"}, {"odds"=>"15.0", "total_matched"=>"14.0"}, {"odds"=>"15.5", "total_matched"=>"33.52"}, {"odds"=>"16.0", "total_matched"=>"23.4"}, {"odds"=>"16.5", "total_matched"=>"47.32"}, {"odds"=>"17.0", "total_matched"=>"42.54"}, {"odds"=>"17.5", "total_matched"=>"18.68"}, {"odds"=>"18.0", "total_matched"=>"31.92"}, {"odds"=>"18.5", "total_matched"=>"30.9"}, {"odds"=>"19.0", "total_matched"=>"45.8"}, {"odds"=>"19.5", "total_matched"=>"59.76"}, {"odds"=>"20.0", "total_matched"=>"137.54"}, {"odds"=>"21.0", "total_matched"=>"10.44"}, {"odds"=>"22.0", "total_matched"=>"31.64"}, {"odds"=>"23.0", "total_matched"=>"30.4"}, {"odds"=>"24.0", "total_matched"=>"4.48"}, {"odds"=>"25.0", "total_matched"=>"15.26"}], "selection_id"=>"4801791", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "5921135"=>{"traded_amounts"=>[{"odds"=>"7.8", "total_matched"=>"152.1"}, {"odds"=>"8.0", "total_matched"=>"116.08"}, {"odds"=>"8.2", "total_matched"=>"183.2"}, {"odds"=>"8.4", "total_matched"=>"262.64"}, {"odds"=>"8.6", "total_matched"=>"267.02"}, {"odds"=>"8.8", "total_matched"=>"276.68"}, {"odds"=>"9.0", "total_matched"=>"248.56"}, {"odds"=>"9.2", "total_matched"=>"172.56"}, {"odds"=>"9.4", "total_matched"=>"67.08"}, {"odds"=>"9.6", "total_matched"=>"109.36"}], "selection_id"=>"5921135", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "5191694"=>{"traded_amounts"=>[{"odds"=>"3.95", "total_matched"=>"44.0"}, {"odds"=>"4.0", "total_matched"=>"94.58"}, {"odds"=>"4.1", "total_matched"=>"633.6"}, {"odds"=>"4.2", "total_matched"=>"820.24"}, {"odds"=>"4.3", "total_matched"=>"115.88"}, {"odds"=>"4.4", "total_matched"=>"317.12"}, {"odds"=>"4.5", "total_matched"=>"108.34"}, {"odds"=>"4.6", "total_matched"=>"102.42"}, {"odds"=>"4.7", "total_matched"=>"197.98"}, {"odds"=>"4.8", "total_matched"=>"197.06"}, {"odds"=>"4.9", "total_matched"=>"166.64"}, {"odds"=>"5.0", "total_matched"=>"417.08"}, {"odds"=>"5.1", "total_matched"=>"339.68"}, {"odds"=>"5.2", "total_matched"=>"596.3"}, {"odds"=>"5.3", "total_matched"=>"259.34"}, {"odds"=>"5.4", "total_matched"=>"251.12"}, {"odds"=>"5.5", "total_matched"=>"75.04"}, {"odds"=>"5.6", "total_matched"=>"4.52"}, {"odds"=>"5.7", "total_matched"=>"15.8"}, {"odds"=>"5.8", "total_matched"=>"11.28"}], "selection_id"=>"5191694", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "5898478"=>{"traded_amounts"=>[{"odds"=>"2.4", "total_matched"=>"0.24"}, {"odds"=>"2.42", "total_matched"=>"3.76"}, {"odds"=>"2.68", "total_matched"=>"2.24"}, {"odds"=>"2.7", "total_matched"=>"3.76"}, {"odds"=>"2.72", "total_matched"=>"7.1"}, {"odds"=>"2.74", "total_matched"=>"59.84"}, {"odds"=>"2.78", "total_matched"=>"8.74"}, {"odds"=>"2.8", "total_matched"=>"3.76"}, {"odds"=>"2.82", "total_matched"=>"0.9"}, {"odds"=>"2.84", "total_matched"=>"30.24"}, {"odds"=>"2.86", "total_matched"=>"149.84"}, {"odds"=>"2.88", "total_matched"=>"739.78"}, {"odds"=>"2.9", "total_matched"=>"936.66"}, {"odds"=>"2.92", "total_matched"=>"988.0"}, {"odds"=>"2.94", "total_matched"=>"1422.04"}, {"odds"=>"2.96", "total_matched"=>"1116.78"}, {"odds"=>"2.98", "total_matched"=>"1292.38"}, {"odds"=>"3.0", "total_matched"=>"748.78"}, {"odds"=>"3.05", "total_matched"=>"290.82"}, {"odds"=>"3.1", "total_matched"=>"227.16"}, {"odds"=>"3.15", "total_matched"=>"379.42"}, {"odds"=>"3.2", "total_matched"=>"226.4"}, {"odds"=>"3.25", "total_matched"=>"228.26"}, {"odds"=>"3.3", "total_matched"=>"155.94"}, {"odds"=>"3.35", "total_matched"=>"183.44"}, {"odds"=>"3.4", "total_matched"=>"81.18"}, {"odds"=>"3.5", "total_matched"=>"80.0"}, {"odds"=>"3.55", "total_matched"=>"18.4"}, {"odds"=>"3.6", "total_matched"=>"12.16"}, {"odds"=>"3.65", "total_matched"=>"3.98"}], "selection_id"=>"5898478", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "6084518"=>{"traded_amounts"=>[{"odds"=>"250.0", "total_matched"=>"0.02"}, {"odds"=>"280.0", "total_matched"=>"3.4"}, {"odds"=>"290.0", "total_matched"=>"0.6"}, {"odds"=>"300.0", "total_matched"=>"7.64"}, {"odds"=>"310.0", "total_matched"=>"0.84"}, {"odds"=>"370.0", "total_matched"=>"1.0"}, {"odds"=>"410.0", "total_matched"=>"0.94"}, {"odds"=>"490.0", "total_matched"=>"0.02"}, {"odds"=>"530.0", "total_matched"=>"0.04"}], "selection_id"=>"6084518", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "5678817"=>{"traded_amounts"=>[{"odds"=>"3.35", "total_matched"=>"4.0"}, {"odds"=>"4.2", "total_matched"=>"18.38"}, {"odds"=>"4.3", "total_matched"=>"78.84"}, {"odds"=>"4.4", "total_matched"=>"26.2"}, {"odds"=>"4.5", "total_matched"=>"192.0"}, {"odds"=>"4.6", "total_matched"=>"232.42"}, {"odds"=>"4.7", "total_matched"=>"217.52"}, {"odds"=>"4.8", "total_matched"=>"277.98"}, {"odds"=>"4.9", "total_matched"=>"496.04"}, {"odds"=>"5.0", "total_matched"=>"361.86"}, {"odds"=>"5.1", "total_matched"=>"377.16"}, {"odds"=>"5.2", "total_matched"=>"234.08"}, {"odds"=>"5.3", "total_matched"=>"62.48"}, {"odds"=>"5.4", "total_matched"=>"52.98"}], "selection_id"=>"5678817", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}, "4509182"=>{"traded_amounts"=>[{"odds"=>"13.5", "total_matched"=>"11.2"}, {"odds"=>"14.0", "total_matched"=>"11.32"}, {"odds"=>"14.5", "total_matched"=>"38.04"}, {"odds"=>"15.0", "total_matched"=>"143.94"}, {"odds"=>"15.5", "total_matched"=>"157.56"}, {"odds"=>"16.0", "total_matched"=>"68.22"}, {"odds"=>"16.5", "total_matched"=>"56.04"}, {"odds"=>"17.0", "total_matched"=>"64.54"}, {"odds"=>"17.5", "total_matched"=>"59.76"}, {"odds"=>"18.0", "total_matched"=>"40.6"}, {"odds"=>"19.5", "total_matched"=>"3.34"}, {"odds"=>"20.0", "total_matched"=>"6.24"}, {"odds"=>"21.0", "total_matched"=>"3.76"}], "selection_id"=>"4509182", "asian_line_id"=>"0", "bsp"=>"0.0", "total_bsp_back_matched"=>"0.0", "total_bsp_liability_matched"=>"0.0"}}
  end

end