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
      it "should support send" do
        app = Yeager::App.new

        app.get "/" do |req, res|
          res.send TEXT
        end

        server = HTTP::Server.new(HOST, PORT, [app.handler])
        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT
        response.body.should eq(TEXT)

        server.close
      end

      it "should support json" do
        app = Yeager::App.new

        app.get "/" do |req, res|
          res.status(200).json({"Hello" => "world!"})
        end

        server = HTTP::Server.new(HOST, PORT, [app.handler])
        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT
        response.body.should eq("{\"Hello\":\"world!\"}")
        response.status_code.should eq(200)

        server.close
      end

      it "should support chain calls" do
        app = Yeager::App.new

        app.get "/200" do |req, res|
          res.status(200).send TEXT
        end

        app.get "/404" do |req, res|
          res.status(404).send TEXT
        end

        app.handler.class.should eq(Yeager::HTTPHandler)
        app.routers["GET"].class.should eq(Yeager::Router)
        app.routers["GET"].routes.should eq({
          "/200" => ["200"], "/404" => ["404"],
        })

        server = HTTP::Server.new(HOST, PORT, [app.handler])
        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get "#{ROOT}/200"
        response.body.should eq(TEXT)
        response.status_code.should eq(200)

        response = HTTP::Client.get "#{ROOT}/404"
        response.body.should eq(TEXT)
        response.status_code.should eq(404)

        server.close
      end
    end

    describe "Request" do
      it "should provide params" do
        app = Yeager::App.new

        app.get "/:name" do |req, res|
          res.send TEXT + req.params["name"]
        end

        server = HTTP::Server.new(HOST, PORT, [app.handler])
        spawn do
          server.listen
        end

        Fiber.yield

        response = HTTP::Client.get ROOT + "/Yeager"
        response.body.should eq(TEXT + "Yeager")

        server.close
      end
    end
  end
end
