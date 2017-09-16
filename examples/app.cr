require "../src/yeager"

app = Yeager::App.new

app.get "/" do |req, res|
  res.send "Hello world!"
end

app.post "/" do |_, res|
  res.status(200).json({"Hello" => "world!"})
end

app.get "/:name" do |req, res|
  res.send "Hello sub world! #{req.params["name"]}"
end

# If you have a defined HTTP::Server already you can
# use app.handler after this point instead of running
# the server of the app.
app.listen 3000 do
  print "Example app listening on 0.0.0.0:3000!"
end

# Example usage for using the app.handler
# with an existing server
#
# server = HTTP::Server.new("0.0.0.0", 8080, [app.handler])
# puts "Listening on 0.0.0.0:8080..."
# server.listen
