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
          if (param = block[0] == PARAM) || block == blocks[index]
            params[block.lchop PARAM] = blocks[index] if param

            if index == block_end
              params[:path] = k_path
              return params
            end

            next
          else
            break
          end

          if k_index == routes_end
            return
          end
        end
      end
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

      routes.each do |ro_block|
        r_path, r_block = ro_block

        res = Yeager::Result.new

        merged = r_block.zip? blocks
        merged.each do |block|
          match = false
          key, value = block

          is_nil = value.nil?
          optional = key[-1] == OPTIONAL

          break if is_nil && !optional

          param = key[0] == PARAM
          is_same = key == value

          break if !param && !is_same || merged.size < blocks.size

          res[key.lchop(PARAM).rchop(OPTIONAL)] = value if param
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
