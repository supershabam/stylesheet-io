_ = require "underscore"
express = require "express"
fs = require "fs"
http = require "http"
path = require "path"
socketio = require "socket.io"
compiler = require "./compiler"
{FolderWatcher} = require "./watcher"

app = express()
server = http.createServer(app)
ioOptions =
  transports: ["htmlfile", "xhr-polling", "jsonp-polling"]
io = socketio.listen server, ioOptions
app.set "port", process.env.PORT || 80
app.use app.router
# paths
fontspath = path.resolve process.cwd(), "./run/src/fonts"
imagespath = path.resolve process.cwd(), "./run/src/images"
javascriptspath = path.resolve process.cwd(), "./run/src/javascripts"
stylesheetspath = path.resolve process.cwd(), "./run/src/stylesheets"
markuppath = path.resolve process.cwd(), "./run/src/markup"
# injected js
injectedjs = String(fs.readFileSync(path.resolve(process.cwd(), "./injected.js")))
# serve static contents
app.use "/fonts", express.static(fontspath)
app.use "/images", express.static(imagespath)
app.use "/javascripts", express.static(javascriptspath)
# serve computed content
app.get "/stylesheets/:file", (req, res, next)->
  file = (req.param "file" || "")
  file = path.basename file, ".css"
  file = "#{file}.less"
  compiler.less path.resolve(stylesheetspath, file), (err, css)->
    return next err if err
    res.setHeader "Content-Type", "text/css"
    res.end css
app.get "/:file", (req, res, next)->
  file = (req.param "file" || "")
  file = path.basename file, ".html"
  file = "#{file}.jade"
  compiler.markup path.resolve(markuppath, file), injectedjs, (err, html)->
    return next err if err
    res.end html
# watch files for changes
watchpaths = [fontspath, imagespath, javascriptspath, stylesheetspath, markuppath]
watchpaths.forEach (p) ->
  watcher = new FolderWatcher(p, "*")
  watcher.on "change", -> app.emit "change"
  watcher.start()
# react to change event
debouncedOnChange = ->
  app.emit "change:debounced"
debouncedOnChange = _.debounce debouncedOnChange, 1000
app.on "change", debouncedOnChange
app.on "change:debounced", -> 
  io.sockets.emit "change"
  console.log "change"
# start the server!!
server.listen app.get("port"), (err)->
  return console.error err if err
  console.log "listening on port #{app.get('port')}"
