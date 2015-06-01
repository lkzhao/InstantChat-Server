express = require 'express'
bodyParser = require 'body-parser'
multer  = require 'multer'
module.exports = (app, rclient) ->
  app.use bodyParser.json()
  app.use multer(
    dest: './uploads/'
    limits:
      fieldNameSize: 100
      files: 2
      fields: 5
  )
  app.use (err, req, res, next) ->
      res.status(err.status || 500)
  app.use express.static('public')
  app.use '/signup', require('./signup')
  app.use '/login', require('./login')
  app.use '/user', require('./user')