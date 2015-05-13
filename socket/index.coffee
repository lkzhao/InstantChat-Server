

socketioJwt = require "socketio-jwt"
jwtSecret = process.env.JWT_SECRET

mongoose = require 'mongoose'
User = mongoose.model 'User'
Message = mongoose.model 'Message'
lock = require("../redis/redisClient").lock

manager = require "./manager"

module.exports = (io, rclient) ->
  io.use socketioJwt.authorize(
    secret: jwtSecret,
    handshake: true
  )
  io.use (socket, next) ->
    username = socket.decoded_token.username
    if username
      User.loadWithUsername username, (err, user) ->
        if (err)
          next new Error('Database error')
        else
          socket.user = user
          socket.username = username
          next()
    else
      next new Error('Authentication error')

  io.on "connection", (socket) ->
    user = socket.user
    username = socket.username
    console.log "#{username} connected"
    manager.addSocket socket

    socket.on "disconnect", ->
      manager.removeSocket socket
      console.log "#{username} disconnected"

    socket.on "error", (err) ->
      console.log "Error: #{err}"

    # view message
    socket.on "ChatViewMessage", (msgId, viewTime) ->
      console.log "viewed #{msgId}"
      Message.load msgId, (err, msg)->
        if err
          return

        for soc in manager.allSocketsForUser(msg.fromUser.username)
          soc.emit "ChatViewMessage", msgId, viewTime

        for soc in manager.allSocketsForUser(msg.toUser.username)
          soc.emit "ChatViewMessage", msgId, viewTime

        msg.remove()

    # send message
    socket.on "ChatSendNewUserMessage", (sendTo, date, content, fn) ->
      message = new Message 
        date:date
        content:content
      User.loadWithUsername sendTo, (err, toUser) ->
        if (err)
          fn false, 1, "Failed to load user"
          return
        message.fromUser = socket.user
        message.toUser = toUser

        message.save (err, message) ->
          if err
            fn false, 2, "Failed to save message"
            return
          for soc in manager.allSocketsForUser(sendTo)
            soc.emit "ChatReceiveNewUserMessage", message.toObject()
          for soc in manager.allSocketsForUser(username)
            soc.emit "ChatReceiveNewUserMessage", message.toObject()
          fn true, message.id, "Success"


    Message.find().or([{ toUser: user }, { fromUser: user }])
      .populate('fromUser toUser','username')
      .exec (err, messages)->
        if err
          return
        for msg in messages
          socket.emit "ChatReceiveNewUserMessage", msg.toObject()


