require "../src/yeager"

app = Yeager::App.new

app.get "/" do |req, res|
  res.send "Hello world!"
end

app.get "/google" do |req, res|
  res.redirect "https://google.com"
end

app.post "/" do |_, res|
  res.status(200).json({"Hello" => "world!"})
end

app.get "/:name" do |req, res|
  res.send "Hello sub world! #{req.params["name"]}"
end

# Enable CORS
# Even though it's defined at the end this handler will be
# called before all the handlers. Multiple use handlers
# can be defined which will be called sequentially.
app.use do |req, res, continue|
  res.headers.add "Access-Control-Allow-Origin", "*"
  continue.call
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
