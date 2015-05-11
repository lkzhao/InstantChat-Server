

socketioJwt = require "socketio-jwt"
jwtSecret = process.env.JWT_SECRET

module.exports = (io, rclient) ->
  io.use socketioJwt.authorize(
    secret: jwtSecret,
    handshake: true
  )

  users = {}
  io.on 'connection', (socket) ->
    username = socket.decoded_token.username
    console.log '#{username} connected'
    if username in users
      users[username].push socket
    else
      users[username] = [socket]

    socket.on 'disconnect', ->
      if users[username].length == 1
        delete users[username]
      else
        users[username].splice users[username].indexOf(socket), 1
      console.log '#{username} disconnected'

    socket.on 'error', (err) ->
      console.log 'Error: #{err}'

    # view message
    socket.on 'ChatViewMessage', (fromUser, msgHash, viewTime) ->
      if fromUser in users
        console.log "#{fromUser} read #{viewTime}"
        for soc in users[fromUser]
          soc.emit 'ChatViewMessage', msgHash, viewTime
      else
        console.log "#{fromUser} not online"

    # send message
    socket.on 'ChatSendNewUserMessage', (sendTo, date, content, fn) ->
      message = 
        fromUser: username
        toUser: sendTo
        date: date
        content: content
      if sendTo in users
        for soc in users[fromUser]
          soc.emit 'ChatReceiveNewUserMessage', message
        for soc in users[username]
          soc.emit 'ChatReceiveNewUserMessage', message
        fn true, 0, "Success"
      else
        fn false, 1, "User not online"
        console.log "#{sendTo} is not online"

      console.log '#{username}->#{sendTo}: #{content}'