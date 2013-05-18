_ = require "underscore"
async = require "async"
fs = require "fs"
glob = require "glob"
lucidjs = require "lucidjs"
path = require "path"
##
# Watches a folder and reports when a file matching the glob changes and gives you
# the contents of that file.
exports.FolderWatcher = class FolderWatcher
  constructor: (@folder, @glob = "*.json")->
    @files = Object.create(null)
    lucidjs.emitter(@)
    @once "terminated", =>
      process.nextTick =>
        @listeners.clear()
    @once "error", =>
      @stop()
  start: =>
    work =
      exists: @_exists
      isDir: ["exists", @_isDir]
      refresh: ["isDir", @_fetch]
      watch: ["isDir", @_watch]
    async.auto work, (err)=>
      return @trigger "error", err if err
      @set "ready"
  stop: =>
    @set "terminated"
  _add: (file)=>
    watcher = fs.watch file
    watcher.on "error", @trigger.bind(@, "error") # pass along errors
    watcher.on "change", =>
      fs.exists file, (exists)=>
        return unless exists
        fs.readFile file, {encoding: "utf8"}, (err, data)=>
          return @trigger "error", err if err
          @trigger "change", path.basename(file, path.extname(file)), data
    @files[file] = watcher
  _remove: (file)=>
    watcher = @files[file]
    watcher.removeAllListeners()
    watcher.close()
    delete @files[file]
  _exists: (cb)=>
    fs.exists @folder, (exists)=>
      return cb(new Error("#{@folder} does not exist")) unless exists
      cb()
  _fetch: (cb)=>
    @_refresh()
    cb()
  _isDir: (cb)=>
    fs.stat @folder, (err, stats)=>
      return cb(err) if err
      return cb(new Error("expected #{@folder} to be a directory")) unless stats.isDirectory()
      cb()
  _refresh: =>
    glob "#{@folder}/#{@glob}", (err, files)=>
      return @trigger "error", err if err
      added = _.difference(files, Object.keys(@files))
      deleted = _.difference(Object.keys(@files), files)
      for file in added
        @_add(file)
      for file in deleted
        @_remove(file)
  _watch: (cb)=>
    watcher = fs.watch @folder
    @watcher = watcher
    @watcher.once "error", @trigger.bind(@, "error") # pass along errors
    @watcher.on "change", (e, filename)=>
      @_refresh()
    @once "terminated", =>
      @watcher.close()
    cb()
