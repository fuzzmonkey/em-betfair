# Response object used to return different formats of responses from the Betfair API.

module Betfair

  class Response
    include ResponseParser

    attr_accessor :raw_response # raw response body (String)
    attr_accessor :parsed_response # response xml (Nokogiri::XML object)
    attr_accessor :successfull # boolean
    attr_accessor :error # String error message

    # @param [String] raw raw request body from EM::Http request
    # @param [String] parsed Nokogiri XML object
    # @param [Boolean] successfull boolean for status of request
    # @param [String] error error message
    def initialize raw, parsed, successfull, error=""
      @raw_response = raw
      @parsed_response = parsed
      @successfull = successfull
      @error = error
    end

    # @return Hash of response parsed using the Betfair::ResponseParser
    def hash_response
      method = get_response_type
      self.send method.to_sym, self.parsed_response if method && self.respond_to?(method)
    end

    # Gets the response method based on the parsed response object
    def get_response_type
      return nil unless self.parsed_response.respond_to?(:xpath)
      response_type = self.parsed_response.xpath("//ns:Envelope/ns:Body", "ns" => "http://schemas.xmlsoap.org/soap/envelope/").first.elements.first.name
      underscore(response_type.gsub("Response",""))
    end

    # Stolen from active support
    # @param [String] camel_cased_word Camel cased method name
    # @return [String] underscored method name
    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

  end

end