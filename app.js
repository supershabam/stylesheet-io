
/**
 * Module dependencies.
 */

var cheerio = require('cheerio')
  , express = require('express')
  , http = require('http')
  , path = require('path')
  , CSS = require('css')
  , Pusher = require('pusher')
  , html = '<html><body><h1>hi</h1></body></html>'
  ;

var app = express();
var pusher = new Pusher({
  appId: '39833',
  key: 'b28ca06b63f61a108fc1',
  secret: 'a169409a4a59e1c9488c'
});

app.configure(function(){
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.static(path.join(__dirname, 'public')));
});

app.configure('development', function(){
  app.use(express.errorHandler());
});

app.get('/', function(req, res) {
  res.render('index');
});

app.get('/edit', function(req, res) {
  res.render('edit', {html: html});
});

app.get('/view', function(req, res, next) {
  res.render('_viewscripts', function(err, raw) {
    if (err) {
      return next(err);
    }
    $ = cheerio.load(html);
    if (!$('head').length) {
      $('html').prepend('<head/>');
    }
    $('head').find('#stylesheet-io').remove();
    $('head').append('<style id="stylesheet-io"></style>');
    $('body').append(raw);
    res.end($.html());
  });
});

app.post('/css', function(req, res, next) {
  var css = null;
  try {
    css = CSS.stringify(CSS.parse(req.body.css || ''));
  } catch (err) {
    return next(err);
  }
  pusher.trigger('change', 'css', {css: css});
  res.json({success: true, css: css});
});

app.post('/html', function(req, res, next) {
  var $ = cheerio.load(req.body.html);
  if (!$('html').length) {
    return next(new Error("Expected html... to have html"));
  }
  if (!$('body').length) {
    return next(new Error("Expected html to have body"));
  }
  html = req.body.html; // save original
  pusher.trigger('change', 'html', '');
  res.json({success: true});
});

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
