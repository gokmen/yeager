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

          response = HTTP::Client.{{ name.id }} ROOT
          response.status_code.should eq(200)

          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}

          response = HTTP::Client.{{ name.id }} "#{ROOT}/non_exist"
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

          response = HTTP::Client.{{ name.id }} ROOT
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

          response = HTTP::Client.{{ name.id }} ROOT
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

          response = HTTP::Client.{{ name.id }} "#{ROOT}/200"
          {% if name.id != "head" %}
          response.body.should eq(TEXT)
          {% end %}
          response.status_code.should eq(200)

          response = HTTP::Client.{{ name.id }} "#{ROOT}/404"
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

          response = HTTP::Client.{{ name.id }} ROOT
          response.status_code.should eq(302)
          new_location = response.headers["Location"]
          new_location.should eq("/foo")

          response = HTTP::Client.{{ name.id }} "#{ROOT}#{new_location}"
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

          response = HTTP::Client.{{ name.id }} ROOT + "/Yeager"
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

          response = HTTP::Client.{{ name.id }} ROOT
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

          response = HTTP::Client.{{ name.id }} "#{ROOT}/foo"
          {% if name.id != "head" %}
          response.body.should eq(TEXT + TEXT)
          {% end %}
          last_page.should eq("foo")
          called.should be_true

          server.close
        end

      {% end %}
    end
  end
end
