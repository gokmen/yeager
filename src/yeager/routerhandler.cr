require "./router"

module Yeager
  class RouterHandler(T) < Router
    protected property handlers : Hash(String, T) = Hash(String, T).new
    protected property empty_result : Yeager::Result = Yeager::Result.new

    def add(path : String, callback : T) : Nil
      super path
      handlers[path] = callback
    end

    def run(url : String, *args) : Nil | Result
      if res = super url
        handlers[res[:path]].call *args
      end
      res
    end

    def run(url : String, params : Bool) : Nil | Result
      if res = super url
        handlers[res[:path]].call (params == true ? res : empty_result)
      end
      res
    end

    def run(url : String, params : Bool, *args) : Nil | Result
      if res = super url
        handlers[res[:path]].call (params == true ? res : empty_result), *args
      end
      res
    end
  end
end
