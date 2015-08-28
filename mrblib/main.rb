def __main__(argv)
  Aruba::Server.new.serve do |req, res|
    on "hello" do
      res.write_json hello: "world"
    end

    on "foo" do
      res.write_json foo: "bar"
    end

    on "exception" do
      raise "this should 500"
    end

    on "timeout" do
      res.write_json timeout: true
      sleep 10
      res.write_json timeout: false
    end

    on "error" do
      # will raise, there is no nested
      on nested do
      end
    end

    on root do
      res.write_json root: true
    end

    on "tasks" do
      type = "task"

      on root do
        res.write_json([])
      end

      only ":id" do |id|
        id = id.to_i
        # only means that /tasks/123/edit will 404
        res.write_json type: type, id: id, title: "hello"
      end
    end

    on "lists" do
      on root do
        res.write_json([])
      end

      # the other way to do only
      on ":id" do |id|
        on root do
          res.write_json type: :list, id: id, title: "hello"
        end

        only "edit" do
          res.write_json edit: true
        end

        anything_else do
          res.status = 404
          res.write_json not_found: true
        end
      end
    end

    on "api/v1" do
      res.write_json api: true, version: 1, path: path
    end

    on "api/v2" do
      res.status = 204
    end

    on "verb_test" do
      %i(head get post patch put delete).each do |verb|
        on send(verb) do
          res.write_json verb: verb, path: req.path
        end
      end
    end
  end
end

if __FILE__ == $0
  __main__(ARGV)
end
