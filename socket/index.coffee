

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
      socket.username = username
      next()
    else
      next new Error('Authentication error')

  io.on "connection", (socket) ->
    username = socket.decoded_token.username
    console.log "#{username} connected"
    manager.addSocket socket

    socket.on "disconnect", ->
      manager.removeSocket socket
      console.log "#{username} disconnected"

    socket.on "error", (err) ->
      console.log "Error: #{err}"

    # view message
    socket.on "VIEW", (data) ->
      Message.load data.messageId, (err, msg)->
        if err
          return

        for soc in manager.allSocketsForUser(msg.fromUser.username)
          soc.emit "VIEW", data

        for soc in manager.allSocketsForUser(msg.toUser.username)
          soc.emit "VIEW", data

        msg.remove()

    # send message
    socket.on "SEND", (data, fn) ->
      sendTo = data.sendTo
      message = new Message
        date: data.date
        content: data.content

      User.loadWithUsername username, (ferr, user) ->
        User.loadWithUsername sendTo, (terr, toUser) ->
          if ferr || terr
            fn { error: "Failed to load user" }
            return
          message.fromUser = user
          message.toUser = toUser

          console.log user.contacts
          if user.contacts.indexOf(toUser.id) > -1
            console.log "User has contact"
          else
            user.contacts.push toUser
            user.save()

          message.save (err, message) ->
            if err
              fn { error: "Failed to save message" }
              return
            fn { messageId: message.id }
            for soc in manager.allSocketsForUser(sendTo)
              soc.emit "RECEIVE", message.toObject()
            for soc in manager.allSocketsForUser(username)
              soc.emit "RECEIVE", message.toObject()


    User.findOne({ username:username })
      .populate('contacts', 'username')
      .exec (ferr, user) ->
        Message.find().or([{ toUser: user }, { fromUser: user }])
          .populate('fromUser toUser','username')
          .exec (err, messages)->
            if err
              return
            contacts = []
            messages = []
            for contact in user.contacts
              contacts.push contact.username
            for msg in messages
              messages.push msg.toObject()
            socket.emit "RELOAD",
              contacts: contacts
              messages: messages


