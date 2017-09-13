require "./spec_helper"

module Yeager
  describe Yeager do
    it "should provide default aliases" do
      Yeager::Routes.should eq(Hash(String, Array(String)))
      Yeager::Result.should eq(Hash(String | Symbol, String))
    end

    it "should provide seperators for nodes and parameters" do
      Yeager::BLOCK.should eq('/')
      Yeager::PARAM.should eq(':')
    end
  end

  describe Router do
    it "should be able to initialize with no arguments" do
      r = Yeager::Router.new
      r.class.should eq(Yeager::Router)
      r.routes.class.should eq(Yeager::Routes)
    end

    it "should support root handler" do
      r = Yeager::Router.new

      r.add "/"
      r.routes.should eq({"/" => ["/"]})

      r.run("/").should eq({:path => "/"})
      r.run("/foo").should be_nil
    end

    it "should work without root handler" do
      r = Yeager::Router.new

      r.add "/api"
      r.routes.should eq({"/api" => ["api"]})

      r.run("/").should be_nil
      r.run("/api").should eq({:path => "/api"})
      r.run("/foo").should be_nil
    end

    it "should support parameters on root level" do
      r = Yeager::Router.new

      r.add "/:name"
      r.routes.should eq({"/:name" => [":name"]})

      r.run("/").should eq({:path => "/:name", "name" => "/"})
      r.run("/api").should eq({:path => "/:name", "name" => "api"})
      r.run("/api/bar").should be_nil
    end

    it "should support multiple parameters" do
      r = Yeager::Router.new

      r.add "/:name/:surname"
      r.routes.should eq({"/:name/:surname" => [":name", ":surname"]})

      r.run("/").should be_nil
      r.run("/api").should be_nil
      r.run("/api/bar").should eq({
        :path     => "/:name/:surname",
        "name"    => "api",
        "surname" => "bar",
      })
      r.run("/api/bar/baz").should be_nil
    end

    it "should support parameters under other paths" do
      r = Yeager::Router.new

      r.add "/foo/:name"
      r.routes.should eq({"/foo/:name" => ["foo", ":name"]})

      r.run("/").should be_nil
      r.run("/api").should be_nil
      r.run("/api/bar").should be_nil
      r.run("/foo/bar").should eq({
        :path  => "/foo/:name",
        "name" => "bar",
      })
      r.run("/foo/bar/baz").should be_nil
    end

    it "should support parameters in between paths" do
      r = Yeager::Router.new

      r.add "/foo/:name/bar"
      r.routes.should eq({"/foo/:name/bar" => ["foo", ":name", "bar"]})

      r.run("/").should be_nil
      r.run("/api").should be_nil
      r.run("/api/bar").should be_nil
      r.run("/foo/bar").should be_nil
      r.run("/foo/test/bar").should eq({
        :path  => "/foo/:name/bar",
        "name" => "test",
      })
      r.run("/foo/bar/baz").should be_nil
    end

    it "should support multiple routes" do
      r = Yeager::Router.new

      r.add "/foo/bar"
      r.add "/foo/:name"
      r.add "/api"
      r.add "/api/:id/:test"
      r.add "/api/:id/:test/disable"

      r.routes.should eq({
        "/foo/bar"               => ["foo", "bar"],
        "/foo/:name"             => ["foo", ":name"],
        "/api"                   => ["api"],
        "/api/:id/:test"         => ["api", ":id", ":test"],
        "/api/:id/:test/disable" => ["api", ":id", ":test", "disable"],
      })

      r.run("/").should be_nil
      r.run("/api").should eq({
        :path => "/api",
      })
      r.run("/api/bar").should be_nil
      r.run("/api/12/tea").should eq({
        :path  => "/api/:id/:test",
        "id"   => "12",
        "test" => "tea",
      })
      r.run("/foo/bar").should eq({
        :path => "/foo/bar",
      })
      r.run("/foo/baz").should eq({
        :path  => "/foo/:name",
        "name" => "baz",
      })
      r.run("/api/12/tea/enable").should be_nil
      r.run("/api/12/tea/disable").should eq({
        :path  => "/api/:id/:test/disable",
        "id"   => "12",
        "test" => "tea",
      })
      r.run("/foo/bar/baz").should be_nil
    end

    it "should respect route orders" do
      r = Yeager::Router.new

      r.add "/foo/bar"
      r.add "/foo/:name"
      r.add "/foo/baz"

      r.routes.should eq({
        "/foo/bar"   => ["foo", "bar"],
        "/foo/:name" => ["foo", ":name"],
        "/foo/baz"   => ["foo", "baz"],
      })

      r.run("/foo/bar").should eq({
        :path => "/foo/bar",
      })
      r.run("/foo/baz").should eq({
        :path  => "/foo/:name",
        "name" => "baz",
      })
    end

    it "should support named parameters to support at any level" do
      r = Yeager::Router.new

      r.add "/"
      r.add "/:post"
      r.add "/:category/:post"

      r.routes.should eq({
        "/"                => ["/"],
        "/:post"           => [":post"],
        "/:category/:post" => [":category", ":post"],
      })

      r.run("/").should eq({
        :path => "/",
      })
      r.run("/foo").should eq({
        :path  => "/:post",
        "post" => "foo",
      })
      r.run("/foo/bar").should eq({
        :path      => "/:category/:post",
        "category" => "foo",
        "post"     => "bar",
      })
    end
  end
end
