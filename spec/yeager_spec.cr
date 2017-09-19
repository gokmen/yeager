require "./spec_helper"

module Yeager
  describe Yeager do
    it "should provide default aliases" do
      Yeager::Routes.should eq(Hash(String, Array(String)))
      Yeager::Result.should eq(Hash(String | Symbol, String | Nil))
    end

    it "should provide seperators for nodes and parameters" do
      Yeager::BLOCK.should eq('/')
      Yeager::PARAM.should eq(':')
    end
  end
end
