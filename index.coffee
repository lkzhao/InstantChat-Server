fs = require 'fs'
app = require('express')()
mongoose = require 'mongoose'
http = require('http').Server(app)
io = require('socket.io')(http)

connect = () ->
  options = { server: { socketOptions: { keepAlive: 1 } } }
  mongoose.connect("mongodb://localhost/test", options)
connect()

mongoose.connection.on 'error', console.log
mongoose.connection.on 'disconnected', connect

for file in fs.readdirSync("#{__dirname}/models")
  if file.indexOf('.coffee') > 0
    require "#{__dirname}/models/#{file}"

router = require('./routes')(app)
socket = require('./socket')(io)

http.listen 80, ->
  console.log 'listening on *:80'
