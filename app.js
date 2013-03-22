
/**
 * Module dependencies.
 */

var cheerio = require('cheerio')
  , express = require('express')
  , http = require('http')
  , socketio = require('socket.io')
  , path = require('path')
  , CSS = require('css')
  , MemoryStore = express.session.MemoryStore
  , html = '<html><body><h1>hi</h1></body></html>'
  , css = ''
  ;

var app = express();
var sessionStore = new MemoryStore();
var server = http.createServer(app);
var io = socketio.listen(server, {
  transports: ['htmlfile', 'xhr-polling', 'jsonp-polling']
});
var sockets = {};

app.configure(function(){
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser());
  app.use(express.session({
    store: sessionStore,
    secret: 'sekret',
    key: 'i'
  }));
  app.use(app.router);
  app.use(express.static(path.join(__dirname, 'public')));
});

app.configure('development', function(){
  app.use(express.errorHandler());
});

app.get('/sekret', function(req, res) {
  req.session.loggedIn = true;
  res.redirect('/');
});

app.get('/', function(req, res) {
  res.render('index');
});

app.get('/edit', function(req, res) {
  if (!req.session.loggedIn) {
    return res.redirect('/');
  }
  res.render('edit', {html: html});
});

app.get('/view', function(req, res, next) {
  if (!req.session.loggedIn) {
    return res.redirect('/');
  }
  res.render('_viewscripts', function(err, raw) {
    if (err) {
      return next(err);
    }
    $ = cheerio.load(html);
    if (!$('head').length) {
      $('html').prepend('<head/>');
    }
    $('head').find('#stylesheet-io').remove();
    $('head').append('<style id="stylesheet-io">' + css + '</style>');
    $('body').append(raw);
    res.end($.html());
  });
});

app.post('/css', function(req, res, next) {
  if (!req.session.loggedIn) {
    return res.json(403, {err: 'plz no hax, lulz'});
  }
  var _css = null;
  try {
    _css = CSS.stringify(CSS.parse(req.body.css || ''));
  } catch (err) {
    return res.json(400, {err: String(err)});
  }
  css = _css;
  io.sockets.emit('change:css', {css: css});
  res.json({success: true, css: css});
});

app.post('/html', function(req, res, next) {
  if (!req.session.loggedIn) {
    return res.json(403, {err: 'plz no hax, lulz'});
  }
  var $ = cheerio.load(req.body.html);
  if (!$('html').length) {
    return res.json(400, {err: 'Expected html... to have html'});
  }
  if (!$('body').length) {
    return res.json(400, {err: 'Expected html to have body'});
  }
  html = req.body.html; // save original
  io.sockets.emit('change:html', {html: html});
  res.json({success: true});
});

server.listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
