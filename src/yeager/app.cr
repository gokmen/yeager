require "json"
require "http"

module Yeager
  private alias Handler = HTTP::Request | HTTP::Request, HTTP::Server::Response -> Void
  private alias Handlers = Hash(String, Handler)

  private alias HTTPRouters = Hash(String, Router)
  private alias HTTPHandlers = Hash(String, Handlers)

  private alias CallbackType = HTTP::Request, HTTP::Server::Response -> Void

  HTTP_METHODS    = %w(get post put head patch delete)
  DEFAULT_PORT    = 3000
  DEFAULT_HOST    = "0.0.0.0"
  NOT_FOUND_TEXT  = "404 - Not found :("
  NOT_IMPLEMENTED = "501 - Not implemented :("

  class HTTP::Server
    getter host
  end

  class HTTP::Request
    setter params : Yeager::Result = Yeager::Result.new
    getter params
  end

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

  class HTTPHandler
    include HTTP::Handler

    def initialize(@routers : HTTPRouters, @handlers : HTTPHandlers)
    end

    def call(ctx)
      path, method = parse_request ctx

      if !@handlers.has_key? method
        ctx.response.status(501).send(NOT_IMPLEMENTED)
      elsif path && (params = @routers[method].run path)
        ctx.request.params = params
        @handlers[method][params[:path]].call ctx.request, ctx.response
      else
        ctx.response.status(404).send(NOT_FOUND_TEXT)
      end

      ctx
    end

    private def parse_request(ctx)
      return ctx.request.path.to_s, ctx.request.method
    end
  end

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

      def {{name.id}}(path : String, &cb : CallbackType)
        register {{ name.upcase }}, path, &cb
      end
    {% end %}

    private def register(method : String, path : String, &cb : CallbackType)
      @handlers[method][path] = cb
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
