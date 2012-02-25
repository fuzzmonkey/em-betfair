require 'haml'

module Betfair

  # Utility class to render a SOAP request from a haml file, embedding data
  # elements as necessary
  class SOAPRenderer

    def initialize service, soap_name
      base = Pathname.new(__FILE__).realpath.parent
      file = "#{base}/views/#{service}/#{soap_name}.haml"
      unless File.exists?( file )
        $log.error "Cannot find HAML: #{file}" unless $log.nil?
        raise "Cannot find HAML: #{file}"
      end
      @engine = Haml::Engine.new( File.read( file ) ) # this is quite expensive, might be better to keep a hash of renderers
    end

    def render content
      content.each do |key,value|
        self.instance_variable_set( "@#{key}", value )
      end
      @engine.render( self )
    end

  end

end