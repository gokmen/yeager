require "./router"

module Yeager
  # Yeager::Router with handler support which will call the provided block
  # if there is a match with the route processed. Takes Type argument for
  # the block arguments, it must be a Proc with required argument types.
  # Return value is not used so passing Nil would be enough.
  #
  # Usage:
  #
  # ```
  # require "yeager"
  #
  # # Create router handler instance with (-> Nil) block type
  # router = Yeager::RouterHandler(-> Nil).new
  #
  # # Define your routes with paths and blocks to call (a.k.a callback)
  # router.add "/foo", ->{ print "Hello from /foo!" }
  #
  # # Run a route on router handler which will return nil or an
  # # Hash(Symbol | String => String) if there is a match and will call
  # # the provided block for the path
  # router.run "/foo" # -> {:path => "/foo"} and prints "Hello from /foo!"
  # router.run "/bar" # -> nil
  # ```
  #
  class RouterHandler(T) < Router
    # Holds the handlers in an Hash like;
    # { "/foo/:bar" => Proc(T) }
    protected property handlers : Hash(String, T) = Hash(String, T).new
    protected property empty_result : Yeager::Result = Yeager::Result.new

    # Adds provided path into the `routes`
    # and the `callback` to handlers
    #
    # For given example;
    #
    # ```
    # require "yeager"
    # router = Yeager::RouterHandler(String -> Nil).new
    # router.add "/foo/:hello", ->(name : String) {
    #   print "Hello #{name}!"
    # }
    # ```
    #
    # Routes will be;
    #
    # ```
    # {"/foo/:hello" => ["foo", ":hello"]}
    # ```
    #
    # and Handlers;
    #
    # ```
    # {"/foo/:hello" => Proc(String -> Nil)}
    # ```
    #
    def add(path : String, callback : T) : Nil
      super path
      handlers[path] = callback
    end

    # If path found executes the handler with provided arguments
    #
    # ```
    # require "yeager"
    # r = Yeager::RouterHandler(String -> Nil).new
    # called = false
    # r.add "/", ->(name : String) { p "Hello #{name}!" }
    # r.run "/", "user"
    # ```
    #
    # will print `"Hello user!"`
    #
    def run(url : String, *args) : Nil | Result
      if res = super url
        handlers[res[:path]].call *args
      end
      res
    end

    # If path found executes the handler with parameters
    # if `params` value is `false`, `empty_result` will be passed as params
    #
    # ```
    # require "yeager"
    #
    # r = Yeager::RouterHandler(Yeager::Result -> Nil).new
    # r.add "/:name", ->(params : Yeager::Result) {
    #   p "Hello #{params["name"]}!"
    # }
    #
    # r.run("/user", params = true)
    # ```
    #
    # will print `"Hello user!"`
    #
    def run(url : String, params : Bool) : Nil | Result
      if res = super url
        handlers[res[:path]].call (params == true ? res : empty_result)
      end
      res
    end

    # If path found executes the handler with parameters and provided arguments
    # if `params` value is `false`, `empty_result` will be passed as params
    #
    # ```
    # require "yeager"
    #
    # r = Yeager::RouterHandler(Yeager::Result, String -> Nil).new
    # r.add "/:name", ->(params : Yeager::Result, user_type : String) {
    #   p "Hello #{user_type} #{params["name"]}!"
    # }
    #
    # r.run("/user", params = true, "test")
    # ```
    #
    # will print `"Hello test user!"`
    #
    def run(url : String, params : Bool, *args) : Nil | Result
      if res = super url
        handlers[res[:path]].call (params == true ? res : empty_result), *args
      end
      res
    end
  end
end
