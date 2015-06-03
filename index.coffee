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

nodeEnv = process.env.NODE_ENV
port = (if nodeEnv=="production" then 80 else 3000)
http.listen port, ->
  console.log "listening on *:#{port}"
