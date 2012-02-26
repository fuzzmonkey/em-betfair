# Stolen from Rails 3
def underscore(camel_cased_word)
  camel_cased_word.to_s.gsub(/::/, '/').
  gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
  gsub(/([a-z\d])([A-Z])/,'\1_\2').
  tr("-", "_").
  downcase
end

module Betfair

  class Response
    include ResponseParser

    attr_accessor :raw_response # response string
    attr_accessor :parsed_response # response xml
    attr_accessor :successfull
    attr_accessor :error

    def initialize raw, parsed, successfull, error=""
      @raw_response = raw
      @parsed_response = parsed
      @successfull = successfull
      @error = error
    end

    # lazy loaded
    def hash_response
      method = get_response_type
      self.send method.to_sym, self.parsed_response if method && self.respond_to?(method)
    end

    def get_response_type
      return nil unless self.parsed_response.respond_to?(:xpath)
      response_type = self.parsed_response.xpath("//ns:Envelope/ns:Body", "ns" => "http://schemas.xmlsoap.org/soap/envelope/").first.elements.first.name
      underscore(response_type.gsub("Response",""))
    end

  end

end