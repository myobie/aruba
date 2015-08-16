module Aruba
  class Server
    def initialize(opts = {}, &blk)
      ip       = opts.fetch(:ip) { '127.0.0.1' }
      port     = opts.fetch(:port, 8888)
      @backlog = opts.fetch(:backlog, 1024)

      @parser  = HTTP::Parser.new
      @addr    = UV.ip4_addr(ip, port)
      @tcp     = UV::TCP.new

      @tcp.bind(@addr)
    end

    CannotConnect = Class.new StandardError

    def serve(&blk)
      puts "Starting server on #{@addr}..."
      @tcp.listen(@backlog) do |x|
        raise CannotConnect if x != 0

        conn = @tcp.accept
        conn.read_start do |bytes|
          next unless bytes

          req = Request.from bytes
          puts req.inspect
          res = Response.new keep_alive: req.keep_alive?
          scope = Scope.new req, res

          catch(:complete) do
            scope.instance_exec(req, res, &blk)
          end

          res.finalize

          puts res.inspect
          res.write_to(conn)

          unless res.keep_alive?
            conn.close if conn
            conn = nil
          end
        end
      end

      UV.run # sleep until server dies
    end
  end
end
