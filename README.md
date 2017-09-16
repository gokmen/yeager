# Yeager

Simple router implementation w/ http server for Crystal, named after
"Router Man" - [William Yeager](https://en.wikipedia.org/wiki/William_Yeager).
It supports basic router requirements with speed but not battle-tested.

[![Build Status](https://img.shields.io/travis/gokmen/yeager/master.svg)](https://travis-ci.org/gokmen/yeager)


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  yeager:
    github: gokmen/yeager
```

## Usage

### Router only

```crystal
require "yeager"

# Create router instance
router = Yeager::Router.new

# Define your routes
router.add "/foo"
router.add "/foo/:hello"

# Run a route on router which will return nil or an
# Hash(Symbol | String => String) if there is a match
router.run "/foo"       # -> {:path => "/foo"}
router.run "/foo/world" # -> {"hello" => "world", :path => "/foo/:hello"}
router.run "/bar"       # -> nil

```

### WebServer with Yeager::App

```crystal
require "yeager"

# Create the app
app = Yeager::App.new

# Add GET handler for "/" to response back with "Hello world!"
app.get "/" do |req, res|
  res.send "Hello world!"
end

# Add another GET handler for "/:user"
# which will render "Hello yeager!" for "/yeager" route
app.get "/:user" do |req, res|
  res.send "Hello #{req.params["user"]}!"
end

# Start the app on port 3000
app.listen 3000 do
  print "Example app listening on 0.0.0.0:3000!"
end
```

You can checkout [specs](https://github.com/gokmen/yeager/blob/master/spec)
for more examples and documentation can be accessed from [here](https://yeager.now.sh).

## Todo

### Router

 - Add optional argument support like `/foo/:bar?`
 - Add glob support like `/foo/*`

### App

 - Add middleware support
 - Add chain handlers support with a.k.a `next`
 - Add parse form data support
 - Handle WebSocket requests

## Contributing

 1. Fork it ( https://github.com/gokmen/yeager/fork )
 2. Create your feature branch (`git checkout -b my-new-feature`)
 3. Commit your changes (`git commit -am 'Add some feature'`)
 4. Push to the branch (`git push origin my-new-feature`)
 5. Create a new Pull Request

## Contributors

- [Gokmen Goksel](https://github.com/gokmen) - creator, maintainer
