require "./spec_helper"

module Yeager
  private alias ProcType = String -> Nil

  describe RouterHandler do
    it "should be able to initialize with provided generic type" do
      r = Yeager::RouterHandler(ProcType).new
      r.class.should eq(Yeager::RouterHandler(ProcType))
      r.routes.class.should eq(Yeager::Routes)
      r.handlers.class.should eq(Hash(String, ProcType))
    end

    it "should call actions with no arguments" do
      r = Yeager::RouterHandler(-> Nil).new

      called = false

      r.add "/", ->{ called = true }
      r.routes.should eq({"/" => ["/"]})

      r.handle("/").should eq({:path => "/"})
      called.should be_true

      called = false

      r.handle("/foo").should be_nil
      called.should be_false
    end

    it "should call actions with provided arguments" do
      r = Yeager::RouterHandler(ProcType).new

      called = false

      r.add "/", ->(name : String) {
        called = true
        name.should eq("test")
      }

      r.routes.should eq({"/" => ["/"]})

      r.handle("/", "test").should eq({:path => "/"})

      called.should be_true
    end

    it "should support multiple arguments with union types" do
      r = Yeager::RouterHandler(String, Int32 -> Nil).new

      called = false

      r.add "/", ->(name : String, id : Int32) {
        called = true
        name.should eq("test")
        id.should eq(123)
      }

      r.routes.should eq({"/" => ["/"]})

      r.handle("/", "test", 123).should eq({:path => "/"})

      called.should be_true
    end

    it "should pass parameter values if requested" do
      r = Yeager::RouterHandler(Yeager::Result -> Nil).new

      called = false

      r.add "/:name", ->(params : Yeager::Result) {
        called = true
        params["name"].should eq("test")
      }

      r.routes.should eq({"/:name" => [":name"]})

      r.handle("/test", params = true).should eq({:path => "/:name", "name" => "test"})

      called.should be_true
    end

    it "should pass emptied parameters if requested" do
      r = Yeager::RouterHandler(Yeager::Result -> Nil).new

      called = false

      r.add "/:name", ->(params : Yeager::Result) {
        called = true
        params.empty?.should be_true
      }

      r.routes.should eq({"/:name" => [":name"]})

      r.handle("/test", params = false).should eq({:path => "/:name", "name" => "test"})

      called.should be_true
    end

    it "should pass parameter values with arguments if requested" do
      r = Yeager::RouterHandler(Yeager::Result, String -> Nil).new

      called = false

      r.add "/:name", ->(params : Yeager::Result, test : String) {
        called = true
        params.should eq({
          :path  => "/:name",
          "name" => "test",
        })
        test.should eq("Hello")
      }

      r.routes.should eq({
        "/:name" => [":name"],
      })

      r.handle("/test", params = true, "Hello").should eq({
        :path  => "/:name",
        "name" => "test",
      })

      called.should be_true
    end

    it "should pass emptied parameter values with arguments if requested" do
      r = Yeager::RouterHandler(Yeager::Result, String -> Nil).new

      called = false

      r.add "/:name", ->(params : Yeager::Result, test : String) {
        called = true
        params.empty?.should be_true
        test.should eq("Hello")
      }

      r.routes.should eq({
        "/:name" => [":name"],
      })

      r.handle("/test", params = false, "Hello").should eq({
        :path  => "/:name",
        "name" => "test",
      })

      called.should be_true
    end
  end
end
