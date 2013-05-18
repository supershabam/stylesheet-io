cheerio = require "cheerio"
fs = require "fs"
jade = require "jade"
less = require "less"
path = require "path"
sass = require "node-sass"

exports.makeErrHtml = (err)->
  return "<html><head><title>stylesheet.io</title></head><body><h1>Error: #{err}</h1></body></html>"
##
# given a jade file and some arbitrary js to add, return the resulting
# html. If jade fails to compile, then return html that shows the
# error and includes the injectedjs
exports.markup = (file, injectedjs, cb)->
  # intercept cb to do js injection and error html
  cb = do (cb)->
    (err, html)->
      html = exports.makeErrHtml err if err
      $ = cheerio.load(html)
      $("body").append injectedjs
      cb null, $.html()
  fs.readFile file, "utf8", (err, raw)->
    return cb err if err
    options =
      filename: path
    fn = jade.compile raw, options
    try
      html = fn()
      return cb null, html
    catch err
      return cb err

exports.less = (file, cb)->
  fs.readFile file, "utf8", (err, data)->
    return cb err if err
    options =
      paths: path.dirname(file)
      filename: file
    parser = new(less.Parser)(options)
    parser.parse data, (err, tree)->
      return cb err if err
      try
        css = tree.toCSS()
      catch err
        return cb err if err
      cb null, css

exports.sass = (file, cb)->
  sass.render({
    file: file
    success: (css)->
      cb null, css
    error: (err)->
      cb err
  })
