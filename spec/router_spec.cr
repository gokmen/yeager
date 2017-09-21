require "./spec_helper"

module Yeager
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

    it "should support handling multiple routes" do
      r = Yeager::Router.new

      r.add "/:post"
      r.add "/:category"
      r.add "/baz"
      r.add "/bar/bak"
      r.add "/foo/:post"
      r.add "/foo/:category"
      r.add "/foo/:category/user"

      r.routes.should eq({
        "/:post"              => [":post"],
        "/:category"          => [":category"],
        "/baz"                => ["baz"],
        "/bar/bak"            => ["bar", "bak"],
        "/foo/:post"          => ["foo", ":post"],
        "/foo/:category"      => ["foo", ":category"],
        "/foo/:category/user" => ["foo", ":category", "user"],
      })

      r.run_multiple("/gokmen").should eq([
        {
          :path  => "/:post",
          "post" => "gokmen",
        },
        {
          :path      => "/:category",
          "category" => "gokmen",
        },
      ])

      r.run_multiple("/foo/gokmen").should eq([
        {
          :path  => "/foo/:post",
          "post" => "gokmen",
        },
        {
          :path      => "/foo/:category",
          "category" => "gokmen",
        },
      ])

      r.run_multiple("/bar/baz").should be_nil
      r.run_multiple("/baz").should eq([
        {
          :path  => "/:post",
          "post" => "baz",
        },
        {
          :path      => "/:category",
          "category" => "baz",
        },

        {
          :path => "/baz",
        },
      ])

      r.run_multiple("/bar/bak").should eq([
        {
          :path => "/bar/bak",
        },
      ])

      r.run_multiple("/foo/gokmen/user").should eq([
        {
          :path      => "/foo/:category/user",
          "category" => "gokmen",
        },
      ])

      r.run_multiple("/foo/gokmen/test").should be_nil

      r.run_multiple("/foo/:category/user").should eq([
        {
          :path      => "/foo/:category/user",
          "category" => ":category",
        },
      ])
    end

    it "should support optional parameters" do
      r = Yeager::Router.new

      r.add "/user/:id?"
      r.add "/foo/:page?/bar/:book?"

      r.routes.should eq({
        "/user/:id?"             => ["user", ":id?"],
        "/foo/:page?/bar/:book?" => ["foo", ":page?", "bar", ":book?"],
      })

      r.run_multiple("/user/12").should eq([
        {
          :path => "/user/:id?",
          "id"  => "12",
        },
      ])

      r.run_multiple("/user").should eq([
        {
          :path => "/user/:id?",
          "id"  => nil,
        },
      ])

      r.run_multiple("/users").should be_nil

      r.run_multiple("/foo/123/bar/bttf").should eq([
        {
          :path  => "/foo/:page?/bar/:book?",
          "page" => "123",
          "book" => "bttf",
        },
      ])

      r.run_multiple("/foo/123/bar").should eq([
        {
          :path  => "/foo/:page?/bar/:book?",
          "page" => "123",
          "book" => nil,
        },
      ])

      r.run_multiple("/foo/123").should be_nil
    end

    it "should support * glob pattern" do
      r = Yeager::Router.new

      r.add "/user/*"
      r.add "/user/*/bar"
      r.add "/blank/*/paper/*"

      r.routes.should eq({
        "/user/*"          => ["user", "*"],
        "/user/*/bar"      => ["user", "*", "bar"],
        "/blank/*/paper/*" => ["blank", "*", "paper", "*"],
      })

      r.run_multiple("/user/12").should eq([
        {:path => "/user/*"},
      ])

      r.run_multiple("/user").should be_nil

      r.run_multiple("/user/12/bar").should eq([
        {:path => "/user/*"},
        {:path => "/user/*/bar"},
      ])
      r.run_multiple("/user/foo/bar/baz/test").should eq([
        {:path => "/user/*"},
      ])
      r.run_multiple("/user/foo/bak/bar").should eq([
        {:path => "/user/*"},
      ])

      r.run_multiple("/users").should be_nil
      r.run_multiple("/foo/123").should be_nil

      r.run_multiple("/blank/foo/paper/bar").should eq([
        {:path => "/blank/*/paper/*"},
      ])
      r.run_multiple("/blank/foo/paper").should be_nil
      r.run_multiple("/blank/foo/paper/bar/baz/test").should eq([
        {:path => "/blank/*/paper/*"},
      ])
      r.run_multiple("/blank/paper/bar/baz/test").should be_nil
      r.run_multiple("/blank/paper").should be_nil
    end

    it "should support mixed features" do
      r = Yeager::Router.new

      r.add "/user/:id?"
      r.add "/foo/:page?/*/:book?"
      r.add "/create/*/:type?"

      r.routes.should eq({
        "/user/:id?"           => ["user", ":id?"],
        "/foo/:page?/*/:book?" => ["foo", ":page?", "*", ":book?"],
        "/create/*/:type?"     => ["create", "*", ":type?"],
      })

      r.run_multiple("/user/12").should eq([
        {
          :path => "/user/:id?",
          "id"  => "12",
        },
      ])

      r.run_multiple("/foo/blank/bar/test").should eq([
        {
          :path  => "/foo/:page?/*/:book?",
          "page" => "blank",
          "book" => "test",
        },
      ])

      r.run_multiple("/foo/bar/test").should eq([
        {
          :path  => "/foo/:page?/*/:book?",
          "page" => "bar",
          "book" => nil,
        },
      ])

      r.run_multiple("/create/new/user").should eq([
        {
          :path  => "/create/*/:type?",
          "type" => "user",
        },
      ])

      r.run_multiple("/create/new").should eq([
        {
          :path  => "/create/*/:type?",
          "type" => nil,
        },
      ])

      r.run_multiple("/create/new/user/test").should be_nil
    end
  end
end
