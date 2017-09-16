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

    # Splits the provided url, finds same sized routes
    # and walks over them until find a match and will return
    # the parameters (if defined in the route) in the first match
    # with the `:path` in a `Result` instance, if not found a match
    # will return `nil` instead.
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
      blocks = split url
      params = Yeager::Result.new

      routes_end = routes.size - 1
      routes.each_with_index do |ke_block, k_index|
        k_path, k_block = ke_block
        next if k_block.size != blocks.size

        block_end = blocks.size - 1
        k_block.each_with_index do |block, index|
          if block == blocks[index] || (param = block[0] == PARAM)
            params[block.lchop PARAM] = blocks[index] if param

            if index == block_end
              params[:path] = k_path
              return params
            end

            next
          end

          if k_index == routes_end
            return
          else
            break
          end
        end
      end
    end

    # Alias for #run
    def handle(url : String) : Nil | Yeager::Result
      run url
    end
  end
end
