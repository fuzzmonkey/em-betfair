require 'haml'

module Betfair

  # Utility class to render a SOAP request from a haml file, embedding data
  # elements as necessary
  class SOAPRenderer
    # Constructs a new renderer
    #
    # Parameters:
    # * soap_name - the name of the haml file, which is expected to reside
    #               in either views/requests/, views/responses or
    #               views/push. The file name does not include the .haml
    #               part
    # Exceptions:
    # * RuntimeError if we cannot find or read the haml file
    def initialize service, soap_name
      base = Pathname.new(__FILE__).realpath.parent
      file = "#{base}/views/#{service}/#{soap_name}.haml"
      unless File.exists?( file )
        $log.error "Cannot find HAML: #{file}" unless $log.nil?
        raise "Cannot find HAML: #{file}"
      end
      @engine = Haml::Engine.new( File.read( file ) ) # this is quite expensive, might be better to keep a hash of renderers
    end

    # Renders the SOAP output
    #
    # Parameters:
    # * content - a Hash of objects, as required by the HAML. So, if the
    #             haml references a hash called "data", you could call this
    #             method thus:
    #
    #             render :data => { label1 => 'value', label2 => 'value' }
    # * Returns - String
    def render content
      content.each do |key,value|
        self.instance_variable_set( "@#{key}", value )
      end
      @engine.render( self )
    end

  end

end