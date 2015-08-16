module Aruba
  class Request
    def self.parser
      @parser ||= HTTP::Parser.new
    end

    def self.from(bytes)
      new(parser.parse_request(bytes))
    end

    attr_reader :headers, :params, :query, :path

    def initialize(joyent = HTTP::Request.new)
      @joyent = joyent
      @headers = Headers.new(joyent.headers)
      @query = joyent.query || ""
      @path = joyent.path || "/"
      @params = query.split("&").compact.each_with_object({}) do |combos, h|
        next if combos.nil?
        key, value = combos.split("=").map { |c| HTTP::URL.decode(c) }
        h[key] = value
      end
    end

    def components
      path.split("/").compact
    end

    def request_method
      @joyent.method
    end

    def body?
      !@joyent.body.nil?
    end

    def body
      @joyent.body
    end

    def [](key)
      @headers[key]
    end

    def []=(key, value)
      @headers[key] = value
    end

    def keep_alive?
      @headers.key?('Connection') && @headers['Connection'] == 'keep-alive'
    end
  end
end
