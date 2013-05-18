express = require "express"
http = require "http"
path = require "path"
socketio = require "socket.io"
compiler = require "./compiler"

app = express()
server = http.createServer(app)
ioOptions =
  transports: ["htmlfile", "xhr-polling", "jsonp-polling"]
io = socketio.listen server, ioOptions
app.set "port", process.env.PORT || 3000
app.use app.router
# serve static contents
app.use "/fonts", express.static(path.join(process.cwd(), "./run/src/fonts"))
app.use "/images", express.static(path.join(process.cwd(), "./run/src/images"))
app.use "/javascripts", express.static(path.join(process.cwd(), "./run/src/javascripts"))
# serve computed content
app.get "/stylesheets/:file", (req, res, next)->
  file = (req.param "file" || "")
  file = path.basename file, ".css"
  file = "#{file}.less"
  compiler.less path.resolve(process.cwd(), "./run/src/stylesheets/#{file}"), (err, css)->
    return next err if err
    res.end css
app.get "/:file", (req, res, next)->
  file = (req.param "file" || "")
  file = path.basename file, ".html"
  file = "#{file}.jade"
  compiler.markup path.resolve(process.cwd(), "./run/src/markup/#{file}"), "injectme", (err, html)->
    return next err if err
    res.end html
# start the server!!
server.listen app.get("port"), (err)->
  return console.error err if err
  console.log "listening on port #{app.get('port')}"
