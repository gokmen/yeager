require "./spec_helper"

module Yeager
  private HOST = "0.0.0.0"
  private PORT = 1903
  private ROOT = "#{HOST}:#{PORT}"
  private TEXT = "Hello world!"

  describe App do
    it "should be able to initialize with no arguments" do
      app = Yeager::App.new
      app.class.should eq(Yeager::App)
    end

    describe "HTTP Methods" do
      {% for name in Yeager::HTTP_METHODS %}
        it "should support {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.{{ name.id }} "/" do |req, res|
            res.print TEXT
          end

          app.handler.class.should eq(Yeager::HTTPHandler)
          app.routers[{{ name.upcase }}].class.should eq(Yeager::Router)
          app.routers[{{ name.upcase }}].routes.should eq({"/" => ["/"]})

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT
          response.status_code.should eq(200)

          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}

          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}/non_exist"
          response.status_code.should eq(404)

          {% if name.id != "head" %}
          response.body.should eq(Yeager::NOT_FOUND_TEXT)
          {% end %}

          custom_not_found = "not exists..."
          app.handler.options["not_found"] = custom_not_found
          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}/non_exist"
          response.status_code.should eq(404)

          {% if name.id != "head" %}
          response.body.should eq(custom_not_found)
          {% end %}

          server.close
        end
      {% end %}
    end

    describe "#all handler" do
      {% for name in Yeager::HTTP_METHODS %}
        it "should work for {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.all "/" do |req, res|
            res.print TEXT
          end

          app.handler.class.should eq(Yeager::HTTPHandler)
          app.routers[{{ name.upcase }}].class.should eq(Yeager::Router)
          app.routers[{{ name.upcase }}].routes.should eq({"/" => ["/"]})

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT
          response.status_code.should eq(200)

          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}

          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}/non_exist"
          response.status_code.should eq(404)

          {% if name.id != "head" %}
          response.body.should eq(Yeager::NOT_FOUND_TEXT)
          {% end %}

          server.close
        end
      {% end %}
    end

    describe "Response" do
      {% for name in Yeager::HTTP_METHODS %}

        it "should support send for {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.{{ name.id }} "/" do |req, res|
            res.send TEXT
          end

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT
          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}

          server.close
        end

        it "should support json for {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.{{ name.id }} "/" do |req, res|
            res.status(200).json({"Hello" => "world!"})
          end

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT
          {% if name.id != "head" %}
          response.body.should eq("{\"Hello\":\"world!\"}")
          {% end %}
          response.status_code.should eq(200)

          server.close
        end

        it "should support chain calls for {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.{{ name.id }} "/200" do |req, res|
            res.status(200).send TEXT
          end

          app.{{ name.id }} "/404" do |req, res|
            res.status(404).send TEXT
          end

          app.handler.class.should eq(Yeager::HTTPHandler)
          app.routers[{{ name.upcase }}].class.should eq(Yeager::Router)
          app.routers[{{ name.upcase }}].routes.should eq({
            "/200" => ["200"], "/404" => ["404"],
          })

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}/200"
          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}
          response.status_code.should eq(200)

          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}/404"
          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}
          response.status_code.should eq(404)

          server.close
        end

        it "should support redirect for {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.{{ name.id }} "/" do |req, res|
            res.redirect "/foo"
          end

          app.{{ name.id }} "/foo" do |req, res|
            res.status(200).json({"Hello" => "foo"})
          end

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT
          response.status_code.should eq(302)
          new_location = response.headers["Location"]
          new_location.should eq("/foo")

          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}#{new_location}"
          {% if name.id != "head" %}
          response.body.should eq("{\"Hello\":\"foo\"}")
          {% end %}
          response.status_code.should eq(200)

          server.close
        end

      {% end %}
    end

    describe "Request" do
      {% for name in Yeager::HTTP_METHODS %}

        it "should provide params for {{ name.id.upcase }}" do
          app = Yeager::App.new

          app.{{ name.id }} "/:name" do |req, res|
            res.send TEXT + req.params["name"].as(String)
          end

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT + "/Yeager"
          {% if name.id != "head" %}
          response.body.should eq(TEXT + "Yeager")
          {% end %}
          server.close
        end

      {% end %}
    end

    describe "Next" do
      {% for name in Yeager::HTTP_METHODS %}

        it "should support next callback for {{ name.id.upcase }}" do
          app = Yeager::App.new

          called = 0

          app.{{ name.id }} "/" do |req, res, continue|
            req["foo"] = "bar"
            res.send TEXT
            called += 1
            continue.call
          end

          app.{{ name.id }} "/" do |req, res|
            req["foo"].should eq("bar")
            called += 1
            res.send TEXT
          end

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", ROOT
          {% if name.id != "head" %}
          response.body.should eq(TEXT + TEXT)
          {% end %}
          called.should eq 2
          server.close
        end

        it "should support globs for {{ name.id.upcase }}" do
          app = Yeager::App.new

          called = false
          last_page = String

          app.{{ name.id }} "*" do |req, res, continue|
            req.params["page"]?.should be_nil
            res.send TEXT
            continue.call
          end

          app.{{ name.id }} "*" do |req, res, continue|
            called = true
            continue.call
          end

          app.{{ name.id }} "/:page?" do |req, res|
            last_page = req.params["page"]?
            res.send TEXT
          end

          server = HTTP::Server.new(HOST, PORT, [app.handler])
          spawn do
            server.listen
          end

          Fiber.yield

          response = HTTP::Client.exec "{{ name.id.upcase }}", "#{ROOT}/foo"
          {% if name.id != "head" %}
          response.body.should eq(TEXT + TEXT)
          {% end %}
          last_page.should eq("foo")
          called.should be_true

          server.close
        end

      {% end %}
    end

    describe "Not supported HTTP Methods" do
      it "should handle not supported methods correctly" do
        app1 = Yeager::App.new
        app1.get "/" do |req, res|
          res.send "hello"
        end

        # delete handlers for GET method
        # so, it can continue with app2's handler
        app1.handlers.delete "GET"

        app2 = Yeager::App.new
        app2.get "/" do |req, res|
          res.send "hello from 2"
        end

        server = HTTP::Server.new(HOST, PORT, [
          app1.handler,
          app2.handler,
        ])

        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT
        response.body.should eq("hello from 2")

        app2.handlers.delete "GET"

        response = HTTP::Client.get ROOT
        response.body.should eq(Yeager::NOT_IMPLEMENTED)
        response.status_code.should eq(501)

        server.close
      end
    end

    describe "Multiple Apps" do
      it "should support chained applications" do
        app1 = Yeager::App.new
        app2 = Yeager::App.new

        app1.get "/" do |req, res, continue|
          res.send "1"
          continue.call
        end

        app1.get "/" do |req, res, continue|
          res.send "2"
          continue.call
        end

        app1.get "/" do |req, res, continue|
          res.send "3"
          continue.call
        end

        app2.get "/" do |req, res|
          res.send "4"
        end

        app2.get "/foo" do |req, res|
          res.send "bar"
        end

        server = HTTP::Server.new(HOST, PORT, [
          app1.handler,
          app2.handler,
        ])

        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT
        response.body.should eq("1234")

        response = HTTP::Client.get "#{ROOT}/foo"
        response.body.should eq("bar")

        server.close
      end

      it "should work well with other handlers" do
        app = Yeager::App.new

        app.get "/" do |req, res|
          raise Exception.new "test error"
        end

        server = HTTP::Server.new(HOST, PORT, [
          HTTP::ErrorHandler.new(verbose: true),
          app.handler,
        ])

        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT
        response.status_code.should eq(500)

        title, _ = response.body.split "\n"
        title.should eq("ERROR: test error (Exception)")

        server.close
      end
    end

    describe "Middleware" do
      it "should support #use directive for middleware" do
        app = Yeager::App.new

        called_1 = false
        called_2 = false

        app.use do |req, res, continue|
          req.env["test_1"] = "test_1"
          called_1 = true
          continue.call
        end

        app.get "/" do |req, res|
          res.send "ok"
        end

        app.get "/foo" do |req, res|
          res.send req.env["test_1"] + req.env["test_2"]
        end

        app.use do |req, res, continue|
          req.env["test_2"] = "test_2"
          called_2 = true
          continue.call
        end

        server = HTTP::Server.new(HOST, PORT, [app.handler])
        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT
        response.status_code.should eq(200)

        response = HTTP::Client.get "#{ROOT}/foo"
        response.status_code.should eq(200)
        response.body.should eq("test_1test_2")

        called_1.should be_true
        called_2.should be_true

        server.close
      end

      it "should call each middleware once per route" do
        app = Yeager::App.new

        mw_counter = 0
        ro_counter = 0

        app.use do |req, res, continue|
          mw_counter += 1
          continue.call
        end

        app.get "*" do |req, res, continue|
          ro_counter += 1
          res.send "ok"
          continue.call
        end

        app.get "/bar" do |req, res|
          ro_counter += 1
          res.send "ok"
        end

        server = HTTP::Server.new(HOST, PORT, [app.handler])
        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get "#{ROOT}/bar"
        response.status_code.should eq(200)

        mw_counter.should eq(1)
        ro_counter.should eq(2)

        response = HTTP::Client.get "#{ROOT}/bar"
        response.status_code.should eq(200)

        mw_counter.should eq(2)
        ro_counter.should eq(4)

        server.close
      end
    end
  end
end
