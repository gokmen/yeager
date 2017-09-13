# Yeager

Simple router implementation for Crystal, named after "Router Man" -
[William Yeager](https://en.wikipedia.org/wiki/William_Yeager). It supports
basic router requirements with speed but not battle-tested.

[![Build Status](https://img.shields.io/travis/gokmen/yeager/master.svg)](https://travis-ci.org/gokmen/yeager)


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  yeager:
    github: gokmen/yeager
```

## Usage

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

You can checkout [tests](https://github.com/gokmen/yeager/blob/master/spec/yeager_spec.cr)
for more examples and documentation can be accessed from [here](https://yeager.now.sh).

## Todo

 - Add optional argument support like `/foo/:bar?`
 - Add glob support like `/foo/*`

## Contributing

 1. Fork it ( https://github.com/gokmen/yeager/fork )
 2. Create your feature branch (`git checkout -b my-new-feature`)
 3. Commit your changes (`git commit -am 'Add some feature'`)
 4. Push to the branch (`git push origin my-new-feature`)
 5. Create a new Pull Request

## Contributors

- [Gokmen Goksel](https://github.com/gokmen) - creator, maintainer
