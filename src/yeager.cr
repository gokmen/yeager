require "./yeager/*"

module Yeager
  # Holds the defined routes with `Yeager::Router.add`
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
  alias Routes = Hash(String, Array(String))

  # Result Hash will include the matched `:path` and the parameters.
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
  alias Result = Hash(String | Symbol, String | Nil)

  GLOB     = '*'
  BLOCK    = '/'
  PARAM    = ':'
  OPTIONAL = '?'
end
