app = require('express')()
http = require('http').Server(app)
io = require('socket.io')(http)

router = require('./routes')(app)
socket = require('./socket')(io)

http.listen 3000, ->
  console.log 'listening on *:3000'
