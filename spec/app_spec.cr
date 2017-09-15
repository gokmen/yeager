require "./spec_helper"

module Yeager
  describe App do
    it "should be able to initialize with no arguments" do
      app = Yeager::App.new
      app.class.should eq(Yeager::App)
    end
    describe "get" do
      it "should create a get handler" do
        app = Yeager::App.new

        app.get "/" do
          p "called /"
        end

        app.get "/" do |req|
          p req
        end

        app.get "/" do |req, res|
          p req, res
        end
      end
    end
  end
end
