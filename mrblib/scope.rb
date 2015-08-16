module Aruba
  class Scope
    SEGMENT = "([^/]+)"
    EMPTY_STRING = ""
    SLASH = "/"
    PLACEHOLDER = /:\w+/
    BEGINNING_SLASH = /^\//

    attr_reader :path

    def initialize(req, res)
      @req = req
      @res = res
      @path = req.path
      @scoped_path = ""
      @captures = []
    end

    def on(*args)
      puts args.inspect
      try do
        captures = args.map { |arg| match(arg) }.flatten(1)

        return unless captures.all?

        yield(*captures)

        throw(:complete)
      end
    end

    def only(*args, &blk)
      args.push(nothing_else)
      on(*args, &blk)
    end

    def any(&blk)
      on(true, &blk)
    end
    alias anything_else any

    def try
      original_path = @path
      original_scoped_path = @scoped_path
      yield
    ensure
      @path = original_path
      @scoped_path = original_scoped_path
    end
    private :try

    def consume(pattern)
      puts pattern.inspect
      matchdata = @path.match(Regexp.new("^/(#{pattern})(/|$)"))

      return false unless matchdata

      path, *vars = matchdata.captures

      @scoped_path += "/#{path}"
      @path = "#{vars.pop}#{matchdata.post_match}"

      vars
    end
    private :consume

    def match(matcher, segment = SEGMENT)
      case matcher
      when String then consume(matcher.gsub(PLACEHOLDER, segment).gsub(BEGINNING_SLASH, EMPTY_STRING))
      when Regexp then consume(matcher.source)
      when Symbol then consume(segment)
      when Proc   then matcher.call
      else
        matcher
      end
    end

    ### matchers ###

    def root
      @path == SLASH || @path == EMPTY_STRING
    end

    def nothing_else
      ->{ root }
    end

    def head
      @req.request_method == "HEAD"
    end

    def get
      @req.request_method == "GET"
    end

    def post
      @req.request_method == "POST"
    end

    def patch
      @req.request_method == "PATCH"
    end

    def put
      @req.request_method == "PUT"
    end

    def delete
      @req.request_method == "DELETE"
    end
  end
end
