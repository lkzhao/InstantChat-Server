

socketioJwt = require "socketio-jwt"
jwtSecret = process.env.JWT_SECRET

mongoose = require 'mongoose'
User = mongoose.model 'User'
Message = mongoose.model 'Message'

manager = require "./manager"
apn = require 'apn'
options = 
  passphrase: "S0ySauc3"
apnConnection = new apn.Connection(options)

Array.prototype.remove = (args...) ->
  output = []
  for arg in args
    index = @indexOf arg
    output.push @splice(index, 1) if index isnt -1
  output = output[0] if args.length is 1
  output

saveDeviceID = (user, deviceId) ->
  console.log "deviceId: #{deviceId}"
  if deviceId and user
    if user.deviceIds.indexOf(deviceId) == -1
      user.deviceIds.push(deviceId)
      user.save()

module.exports = (io, rclient) ->
  io.use socketioJwt.authorize(
    secret: jwtSecret,
    handshake: true
  )

  io.use (socket, next) ->
    req = socket.request || socket
    if req._query && req._query.deviceToken
      socket.deviceId = req._query.deviceToken

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
    socket.on "UPDATE_DEVICE_TOKEN", (data) ->
      socket.deviceId = data[deviceToken]
      User.loadWithUsername username, (ferr, user) ->
        saveDeviceID(user, socket.deviceId)

    # view message
    socket.on "VIEW", (data) ->
      Message.find({_id: {$in: [data.messageIds]}})
      .populate('fromUser', 'username')
      .populate('toUser', 'username')
      .exec (err, msgs)->
        if err || !msgs || msgs.length == 0
          return
        msg = msgs[0]
        for soc in manager.allSocketsForUser(msg.fromUser.username)
          soc.emit "VIEW", data
        for soc in manager.allSocketsForUser(msg.toUser.username)
          soc.emit "VIEW", data
        for m in msgs
          m.remove()

    # view message
    socket.on "BINARY", (data, fn) ->
      console.log data.messageId
      Message.findOne({ _id : data.messageId })
        .select("id binaryContent")
        .populate('fromUser', 'username')
        .populate('toUser', 'username')
        .exec (err, msg)->
          if err || !msg
            return fn()
          # console.log msg
          fn msg.binaryContent

    # send message
    socket.on "SEND", (data, fn) ->
      if !fn
        fn = ->
      sendTo = data.sendTo

      messageData = 
        date: data.date
        content: data.content
        type: data.type

      if data.binaryContent
        messageData.binaryContent = data.binaryContent
      if data.metaData
        messageData.metaData = JSON.stringify data.metaData

      message = new Message messageData

      User.loadWithUsername username, (ferr, user) ->
        User.loadWithUsername sendTo, (terr, toUser) ->
          if ferr || terr || !toUser
            fn { error: "Failed to load user" }
            return
          message.fromUser = user
          message.toUser = toUser

          if user.hasContact toUser.username
            console.log "User has contact"
          else
            user.contacts.push toUser.id
            user.save()

          message.save (err, message) ->
            if err
              fn { error: "Failed to save message" }
              return
            console.log "saved", message.toObject()
            fn { messageId: message.id }
            toUserDevices = toUser.deviceIds.slice()

            for soc in manager.allSocketsForUser(sendTo)
              # uncomment the following line to disable notification to connected clients
              # toUserDevices.remove(soc.deviceId)
              soc.emit "RECEIVE", message.toObject()
            Message.find({toUser: toUser, fromUser: user}).exec (err, messages) ->
              for deviceId in toUserDevices
                device = new apn.Device(deviceId)
                note = new apn.Notification()
                note.expiry = Math.floor(Date.now() / 1000) + 3600 # Expires 1 hour from now.
                if messages
                  note.badge = messages.length
                note.sound = "ping.aiff"
                note.alert = "#{username} send you a message."
                note.payload = {'messageFrom': username}
                apnConnection.pushNotification(note, device)
            for soc in manager.allSocketsForUser(username)
              soc.emit "RECEIVE", message.toObject()

    User.findOne({ username:username })
      .select('deviceIds contacts')
      .populate('contacts', 'username image.large')
      .exec (ferr, user) ->
        saveDeviceID(user, socket.deviceId)
        Message.find().or([{ toUser: user }, { fromUser: user }])
          .populate('fromUser toUser','username')
          .exec (err, messages)->
            if err
              return
            contactDatas = []
            messageDatas = []
            if user.contacts
              for contact in user.contacts
                contactDatas.push 
                  username:contact.username
                  image:contact.image.large.url
            if messages
              for msg in messages
                messageDatas.push msg.toObject()
            socket.emit "RELOAD",
              contacts: contactDatas
              messages: messageDatas


