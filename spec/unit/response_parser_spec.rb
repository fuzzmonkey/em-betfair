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
    parsed = @parser.login login_xml#login_xml.xpath("//currency").text
    parsed.should == {"currency" => "GBP"}
  end

  it "should parse get_all_markets reponse" do
    get_all_markets_xml = load_xml_response("get_all_markets.xml")
    parsed = @parser.get_all_markets get_all_markets_xml
    parsed["market_data"].keys.size.should eq 246
    parsed["market_data"]["104968448"].should == {"id"=>"104968448", "name"=>"To Be Placed", "type"=>"O", "status"=>"ACTIVE", "date"=> Time.parse("2012-02-25 14:00:00 UTC"), "menu_path"=>"Horse RacingGBKemp 25th Feb", "event_hierarchy"=>"/7/298251/26813087/104968448", "bet_delay"=>"0", "exchange_id"=>"1", "country_code"=>"GBR", "last_refresh"=> Time.parse("2012-02-25 13:53:30 UTC"), "num_runners"=>"8", "num_winners"=>"3", "total_amount_matched"=>"33339.18", "bsp_market"=>true, "turning_in_play"=>true}
  end

  it "should parse get_market reponse" do
    get_market_xml = load_xml_response("get_market.xml")
    parsed = @parser.get_market get_market_xml
    parsed.should == {"id"=>"104968439", "parent_id"=>"26813086", "country_code"=>"GBR", "event_type"=>"7", "base_rate"=>"5.0", "market_name"=>"2m Hcap Chs", "num_winners"=>"1", "runners"=>[{:selection_id=>"3043342", :name=>"Arctic Ben"}, {:selection_id=>"4493849", :name=>"Educated Evans"}, {:selection_id=>"2795387", :name=>"Buffalo Bob"}, {:selection_id=>"3687553", :name=>"Rileyev"}, {:selection_id=>"2610448", :name=>"Oh Crick"}, {:selection_id=>"2406110", :name=>"Oscar Gogo"}, {:selection_id=>"2446696", :name=>"Dinarius"}, {:selection_id=>"1381307", :name=>"Moon Over Miami"}, {:selection_id=>"2810086", :name=>"Super Formen"}]}
  end

end