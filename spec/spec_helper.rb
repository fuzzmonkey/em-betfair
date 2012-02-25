require 'pathname'
require Pathname.new(__FILE__).realpath.parent.parent + 'lib' + 'em-betfair'
require 'eventmachine'

RSpec.configure do |config|
  config.color_enabled = true
end

CANNED_RSP_DIR = Pathname.new(__FILE__).realpath.parent + "support" + "canned_responses"

def load_response response_file
  File.open(CANNED_RSP_DIR+response_file).read
end

def load_xml_response response_file
  Nokogiri::XML File.open(CANNED_RSP_DIR+response_file).read
end