
bodyParser = require 'body-parser'

module.exports = (app, rclient) ->
	app.use bodyParser.json()
	app.use (err, req, res, next) ->
	    res.status(err.status || 500)
  app.use '/signup', require('./signup')
  app.use '/login', require('./login')

	app.get '/', (req, res) ->
	  res.sendfile 'index.html'