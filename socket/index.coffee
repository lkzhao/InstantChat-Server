

socketioJwt = require "socketio-jwt"
jwtSecret = process.env.JWT_SECRET
User = require "../models/User"
Message = require "../models/Message"

lock = require("../models/redisClient").lock

module.exports = (io, rclient) ->
  io.use socketioJwt.authorize(
    secret: jwtSecret,
    handshake: true
  )

  users = {}
  io.on "connection", (socket) ->
    username = socket.decoded_token.username
    console.log "#{username} connected"

    if username of users
      users[username].push socket
    else
      users[username] = [socket]


    socket.on "disconnect", ->
      if users[username].length == 1
        delete users[username]
      else
        users[username].splice users[username].indexOf(socket), 1
      console.log "#{username} disconnected"

    socket.on "error", (err) ->
      console.log "Error: #{err}"

    # view message
    socket.on "ChatViewMessage", (msgId, viewTime) ->
      Message.get msgId, (msg)->
        if msg
          console.log "#{msg.toUser} read #{viewTime}"
          msg.remove()

          lock User.key(msg.fromUser), (done) ->
            User.get msg.fromUser, (fromUser)->
              fromUser.removeMessage msgId, done
              if fromUser.username of users
                for soc in users[fromUser.username]
                  soc.emit "ChatViewMessage", msgId, viewTime

          lock User.key(msg.toUser), (done) ->
            User.get msg.toUser, (toUser)->
              toUser.removeMessage msgId, done

    socket.on "RequestUserData", (fn) ->
      fn username

    # send message
    socket.on "ChatSendNewUserMessage", (sendTo, date, content, fn) ->
      message = new Message username, sendTo, date, content
      fromUser = new User username
      toUser = new User sendTo
      fromUser.load (fromUserLoadSuccess) ->
        toUser.load (toUserLoadSuccess) ->
          if fromUserLoadSuccess and toUserLoadSuccess
            message.save (msgSaveSuccess) ->
              if msgSaveSuccess
                fromUser.outgoingMessages.push message.id
                toUser.incomingMessages.push message.id
                fromUser.save (fromUserSaveSuccess) ->
                  toUser.save (toUserSaveSuccess) ->
                    if fromUserSaveSuccess and toUserSaveSuccess
                      if sendTo of users
                        for soc in users[sendTo]
                          soc.emit "ChatReceiveNewUserMessage", message.toData()
                      if username of users
                        for soc in users[username]
                          soc.emit "ChatReceiveNewUserMessage", message.toData()
                      fn true, message.id, "Success"
                      console.log "#{username}->#{sendTo}: #{content}"
                    else
                      fn false, 2, "Failed to save users"
              else
                fn false, 2, "Failed to save message"
          else
            fn false, 1, "Failed to load user"


    User.get username, (user) ->
      if user
        for msgId in user.incomingMessages.concat(user.outgoingMessages)
          Message.get msgId, (msg)->
            socket.emit "ChatReceiveNewUserMessage", msg.toData()


