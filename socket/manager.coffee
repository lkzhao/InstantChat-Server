
users = {}

module.exports = 

  addSocket: (socket) ->
    username = socket.username

    if username of users
      users[username].push socket
    else
      users[username] = [socket]

  removeSocket: (socket)->
    username = socket.username

    if users[username].length == 1
      delete users[username]
    else
      users[username].splice users[username].indexOf(socket), 1

  allSocketsForUser: (username)->
    if username of users
      users[username]
    else
      []