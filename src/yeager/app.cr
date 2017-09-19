require "json"
require "http"

module Yeager
  private alias NextCallback = Proc(Nil)
  private alias Handler = Proc(HTTP::Request, HTTP::Server::Response, NextCallback, Nil)
  private alias Handlers = Hash(String, Array(Handler))

  private alias HTTPRouters = Hash(String, Yeager::Router)
  private alias HTTPHandlers = Hash(String, Handlers)

  # Supported HTTP methods of `Yeager::HTTPHandler`
  HTTP_METHODS = %w(get post put head patch delete)

  # Default settings for `Yeager::App`s HTTP::Server
  DEFAULT_PORT    = 3000
  DEFAULT_HOST    = "0.0.0.0"
  NOT_FOUND_TEXT  = "404 - Not found :("
  NOT_IMPLEMENTED = "501 - Not implemented :("
  NEXT_HANDLER    = ->{}

  # Extend HTTP::Server to add getter for `#host`
  class HTTP::Server
    getter host
  end

  # Extend HTTP::Request to add {s,g}etter for `#params`
  # and add @env property to hold sharable data between handlers
  class HTTP::Request
    property env = {} of String => String

    setter params : Yeager::Result = Yeager::Result.new
    getter params

    forward_missing_to @env
  end

  # Extend HTTP::Server::Response to add following methods;
  #
  #   - `#send`   : alias to `IO#print`
  #   - `#json`   : sets content type to `application/json`
  #                 and converts provided hash to json before sending
  #   - `#status` : setter for status_code
  class HTTP::Server::Response
    def send(data : String)
      print data
    end

    def json(data : JSON::Type)
      self.content_type = "application/json"
      print data.to_json
    end

    def status(code : Int32)
      self.status_code = code
      self
    end
  end

  # HTTP handler for `Yeager::App` which will use the provided
  # routers (for each HTTP method there is a separate `HTTPRouters` instance)
  # and handlers which are holding the handler functions for related
  # paths for a given HTTP method.
  #
  # on `#call` if there is a match with the provided path and the method
  # this will invoke the provided handler with `request, response`
  # which are in order HTTP::Request and HTTP::Server::Response
  #
  # Handlers can be defined to handle non of the arguments or only
  # the request or both of them.
  #
  # If the requested method is not supported yet response `NOT_IMPLEMENTED`
  # will be returned with status_code `501`
  #
  # If there is no match in the router for given path and the method then
  # `NOT_FOUND_TEXT` will be send as body with status_code `404`
  #
  # This handler uses HTTP::Handler which can be used as a handler in an
  # already existing HTTP::Server instance.
  #
  class HTTPHandler
    include HTTP::Handler

    def initialize(@routers : HTTPRouters, @handlers : HTTPHandlers)
    end

    def call(ctx, index = 0)
      path, method = parse_request ctx

      if !@handlers.has_key? method
        ctx.response.status(501).send(NOT_IMPLEMENTED)
        return ctx
      end

      if path && (params = @routers[method].run path)
        ctx.request.params = params
        handler = @handlers[method][params[:path]]
        next_handler = NEXT_HANDLER
        if handler.size > index + 1
          next_handler = ->{
            self.call(ctx, index + 1)
            return
          }
        end
        handler[index].call ctx.request, ctx.response, next_handler
        return ctx
      end

      ctx.response.status(404).send(NOT_FOUND_TEXT)
      ctx
    end

    private def parse_request(ctx)
      return ctx.request.path.to_s, ctx.request.method
    end
  end

  # `Yeager::App` uses `Yeager::Router` to handle HTTP requests
  # on a given (or created) HTTP::Server instance
  #
  # App mimics the Express.js but not feature complete
  # which only provides basic functionality with sugar helpers
  #
  # It holds provided routes and handlers in separate hashes with
  # requested method (defined in `HTTP_METHODS`)
  #
  # It can create an HTTP::Server and attach the created
  # `Yeager::HTTPHandler` with `#listen` method but also the `#handler`
  # can be used on an existing HTTP::Server
  #
  # Simple example would be;
  #
  # ```
  # app = Yeager::App.new
  #
  # app.get "/" do |req, res|
  #   res.send "Hello world!"
  # end
  #
  # app.listen
  # ```
  #
  # which will create a HTTP::Server and start listening on port `3000`
  # defined in `DEFAULT_PORT` and will response with `Hello world!` for
  # requests coming to `/` with status_code `200`
  #
  # Router part supports the same feature set of `Yeager::Router` also extends
  # `req` and `res` to provide similar functionalities of Express.js
  #
  # ```
  # app = Yeager::App.new
  #
  # app.get "/json" do |req, res|
  #   res.json({"foo" => "bar"})
  # end
  #
  # app.get "/:name" do |req, res|
  #   res.send "Hello #{req.params["name"]}"
  # end
  #
  # app.listen
  # ```
  #
  # - `/test` renders `Hello test`
  # - `/json` renders `{"foo": "bar"}` with content type of `json`
  #
  class App
    protected property handlers = HTTPHandlers.new
    getter handler, routers

    def initialize
      @routers = HTTPRouters.new
      @handler = HTTPHandler.new(@routers, @handlers)

      {% for name in HTTP_METHODS %}
        @routers[{{ name.upcase }}] = Yeager::Router.new
        @handlers[{{ name.upcase }}] = Handlers.new
      {% end %}
    end

    {% for name in HTTP_METHODS %}
      def {{name.id}}(path : String, &cb : Proc(Void))
        register {{ name.upcase }}, path, &cb
      end

      def {{name.id}}(path : String, &cb : HTTP::Request -> _)
        register {{ name.upcase }}, path, &cb
      end

      def {{name.id}}(path : String, &cb : Handler)
        register {{ name.upcase }}, path, &cb
      end
    {% end %}

    private def register(method : String, path : String, &cb : Handler)
      @handlers[method][path] ||= [] of Handler
      @handlers[method][path] << cb
      @routers[method].add path
    end

    def listen(port = DEFAULT_PORT, host = DEFAULT_HOST)
      server = HTTP::Server.new(host, port, [@handler])

      {% if !flag?(:without_openssl) %}
      server.tls = nil
      {% end %}

      server.listen
    end

    def listen(port = DEFAULT_PORT, host = DEFAULT_HOST, &cb : -> _)
      cb.call
      listen port, host
    end
  end
end
