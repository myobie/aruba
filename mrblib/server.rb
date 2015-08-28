module Aruba
  class Server
    def initialize(opts = {}, &blk)
      ip       = opts.fetch(:ip) { '127.0.0.1' }
      port     = opts.fetch(:port, 8888)
      @backlog = opts.fetch(:backlog, 128)

      @parser  = HTTP::Parser.new
      @addr    = UV.ip4_addr(ip, port)
      @tcp     = UV::TCP.new

      @tcp.bind(@addr)

      @log_mutex = UV::Mutex.new
    end

    def log(obj)
      @log_mutex.lock
      puts "#{obj}\n"
    ensure
      @log_mutex.unlock
    end

    def format_request_log(req)
      "#{req.request_method} #{req.path} #{req.params.inspect}"
    end

    def format_response_log(res, time)
      "#{time} #{res.status} #{res.length} #{res.content_type}"
    end

    CannotConnect = Class.new StandardError

    def process(req, res, blk)
      scope = Scope.new req, res

      begin
        catch(:complete) do
          scope.instance_exec(req, res, &blk)
        end
      rescue StandardError => e
        res.status = 500
        res.reset_body!
        res.write_json internal_server_error: true

        log e.inspect
        log e.message
        log e.backtrace.join("\n")
      end

      res.finalize
    end

    def now
      UV.hrtime / 1_000_000.0
    end

    def handle(orig_time, bytes, conn, blk)
      req = Request.from bytes
      log format_request_log(req)

      res = Response.new keep_alive: req.keep_alive?

      work = -> { process(req, res, blk) }

      after = -> {
        res.write_to(conn) do
          time = now - orig_time
          log format_response_log(res, time)
          unless res.keep_alive?
            log "shutting down conn"
            conn.shutdown
            log "shut it down"
          end
        end
      }

      UV::Work.new(work, after)
    end

    def serve(&blk)
      log "Starting server on #{@addr}..."
      @tcp.listen(@backlog) do |x|
        raise CannotConnect if x != 0

        conn = @tcp.accept
        orig_time = now
        conn.read_start do |bytes|
          next unless bytes
          handle(orig_time, bytes, conn, blk)
        end
      end

      timer = UV::Timer.new
      timer.start(3000, 3000) do |x|
        UV.gc
        GC.start
      end

      UV.run # sleep until server dies
    end
  end
end
