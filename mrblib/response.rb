module Aruba
  class Response
    DEFAULT_CONTENT_TYPE = "applicatin/json; charset=utf-8"

    attr_accessor :status

    attr :body
    attr :headers

    def initialize(opts = {})
      @body         = []
      @length       = 0
      @headers      = Headers.new
      @status       = 0
      @keep_alive   = opts.fetch(:keep_alive, false)
      @content_type = DEFAULT_CONTENT_TYPE
    end

    def [](key)
      @headers[key]
    end

    def []=(key, value)
      @headers[key] = value
    end

    def <<(str)
      write(str)
    end

    def write(str)
      s = str.to_s
      @length += s.bytesize
      @body << s
    end

    def write_json(obj)
      str = JSON.generate(obj)
      write(str)
    end

    def body?
      body.length > 0
    end

    def content_type=(new_content_type)
      @content_type = new_content_type
    end

    def keep_alive?
      @keep_alive
    end

    CODES = {
      200 => "OK",
      404 => "Not Found",
      500 => "Internal Server Error",
      503 => "Service Unavailable"
    }

    def status_string
      "#{@status} #{CODES[@status]}"
    end

    def finalize
      if body? && @status == 0
        @status = 200
      end

      if @status == 0
        @status = 404
        write_json("not found" => true)
      end
    end

    def write_to(c)
      c.write "HTTP/1.1 #{status_string}\r\n"
      if @keep_alive
        c.write "Connection: keep-alive\r\n"
      else
        c.write "Connection: close\r\n"
      end
      c.write "Content-type: #{@content_type}\r\n"
      c.write "Content-Length: #{@length}\r\n"
      @headers.each do |key, value|
        c.write "#{key}: #{value}\r\n"
      end
      c.write "\r\n"
      body.each do |content|
        c.write content
      end
    end
  end
end
