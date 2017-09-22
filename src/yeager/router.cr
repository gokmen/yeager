require "logger"

module Yeager
  # Simple router implementation for Crystal, named after "Router Man" -
  # [William Yeager](https://en.wikipedia.org/wiki/William_Yeager). It supports
  # basic router requirements with speed but not battle-tested.
  #
  # Usage:
  #
  # ```
  # require "yeager"
  #
  # # Create router instance
  # router = Yeager::Router.new
  #
  # # Define your routes
  # router.add "/foo"
  # router.add "/foo/:hello"
  #
  # # Run a route on router which will return nil or an
  # # Hash(Symbol | String => String) if there is a match
  # router.run "/foo"       # -> {:path => "/foo"}
  # router.run "/foo/world" # -> {"hello" => "world", :path => "/foo/:hello"}
  # router.run "/bar"       # -> nil
  # ```
  #
  class Router
    # Holds the defined routes in Hash like;
    # { "/foo/:bar" => ["foo", ":bar"] }
    protected property routes : Routes = Routes.new
    private getter log : Logger

    def initialize
      @log = Logger.new(STDOUT)
      @log.progname = "Yeager::Router"
      @log.level = ENV["YEAGER_DEBUG"]? ? Logger::DEBUG : Logger::INFO
      @log.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
        label = severity.unknown? ? "ANY" : severity.to_s
        io << "(" << progname << ") " << label.rjust(5) << " [ " << datetime.to_s("%T") << " #" << Process.pid << " ] "
        io << message
      end
    end

    private def split(s : String) : Array(String)
      return [s] if s.size == 1 && s[0] == BLOCK
      s.lchop(BLOCK).rchop(BLOCK).split BLOCK
    end

    # Adds provided path into the `routes`
    #
    # For given example;
    #
    # ```
    # require "yeager"
    # router = Yeager::Router.new
    # router.add "/foo/:hello"
    # router.add "/bar"
    # ```
    #
    # Routes will be;
    #
    # ```
    # {
    #   "/foo/:hello" => ["foo", ":hello"],
    #   "/bar"        => ["bar"],
    # }
    # ```
    #
    def add(path : String) : Nil
      routes[path] = split path
    end

    # By using the run_multiple splits the provided url, and walks over
    # routes until find a match and will return the parameters (if defined
    # in the route) in the first match with the `:path` in a `Result`
    # instance, if not found a match will return `nil` instead.
    #
    # `Result` will include the matched `:path` and the parameters.
    #
    # For given example;
    #
    # ```
    # require "yeager"
    # router = Yeager::Router.new
    # router.add "/foo/:hello"
    # router.run "/foo/world"
    # ```
    #
    # will return a `Result` instance with following content;
    #
    # ```
    # {
    #   "hello" => "world",
    #   :path   => "/foo/:hello",
    # }
    # ```
    #
    def run(url : String) : Nil | Yeager::Result
      res = run_multiple url, once = true
      res ? res[0] : nil
    end

    # Splits the provided url, finds same sized routes and walks over all
    # of them. Will keep matched ones in an Array, which will include the
    # parameters (if defined in the route) in the first match with the
    # `:path` in a `Result` instance, if not found any match will return
    # `nil` instead.
    #
    # For given example;
    #
    # ```
    # require "yeager"
    # router = Yeager::Router.new
    # router.add "/foo/:hello"
    # router.add "/foo/:bar"
    # router.run_multiple "/foo/world"
    # ```
    #
    # will return an `Array` of `Result` instance with following content;
    #
    # ```
    # [
    #   {
    #     "hello" => "world",
    #     :path   => "/foo/:hello",
    #   },
    #   {
    #     "bar" => "world",
    #     :path => "/foo/:bar",
    #   },
    # ]
    # ```
    #
    def run_multiple(url : String, once : Bool = false) : Nil | Array(Yeager::Result)
      blocks = split url
      params = [] of Yeager::Result
      match = Bool

      log.debug "testing #{url}"
      routes.each do |ro_block|
        r_path, r_block = ro_block
        log.debug "  on route #{r_path}:"

        res = Yeager::Result.new

        r_block.size.times do |index|
          match = false
          key, value = r_block[index], blocks[index]?
          log.debug "    - key: #{key} value: #{value}"

          is_nil = value.nil?
          is_optional = key[-1] == OPTIONAL
          log.debug "    - is_nil? #{is_nil} : is_optional? #{is_optional}"

          break if is_nil && !is_optional

          head = key[0]
          is_param = head == PARAM
          is_glob = head == GLOB
          is_same = key == value
          log.debug "    - is_same? #{is_same} : is_param? #{is_param} : is_glob? #{is_glob}"

          break if !is_glob && !is_param && !is_same
          break if index == r_block.size - 1 &&
                   !is_glob && r_block.size < blocks.size

          res[key.lchop(PARAM).rchop(OPTIONAL)] = value if is_param

          log.debug "    = -- -match!- -- #{r_path} "
          match = true
        end

        if match
          res[:path] = r_path
          params << res
          return params if once
        end
      end

      params.size > 0 ? params : nil
    end

    # Alias for #run
    def handle(url : String) : Nil | Yeager::Result
      run url
    end

    # Alias for #run_multiple
    def handle_multiple(url : String) : Nil | Yeager::Result
      run_multiple url
    end
  end
end
