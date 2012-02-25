module BetFair

  class Response
    include ResponseParser

    attr_accessor :raw_response # response string
    attr_accessor :parsed_response # response xml
    #attr_accessor :hash_response # response hash
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
      #p @parsed_response.root
      #
    end

  end

end