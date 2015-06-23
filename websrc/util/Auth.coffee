defaultUsername = "anonymous"
token = localStorage["token"]
username = localStorage["username"]
if !username
  token = null

initialSocket = io.connect("", query:"token=#{token}")

initialSocket.on "connect", ->
  console.log "socket connected"
  $.get("/user/profile/#{auth.username}?token=#{auth.token}")
    .done( (data)=>
      console.log "load initial profile"
      auth.profile = data
      auth._onProfileChange()
    ).fail( =>

    )

initialSocket.on "profileChange", (data) ->
  console.log "received profileChange from socket"
  auth.profile = data
  auth._onProfileChange()

window.auth = 
  username: username
  token: token
  socket: initialSocket
  callbacks: {}
  onceCallbacks: {}
  profile: {}

  _onProfileChange: ->
    if @onceCallbacks.profileChange
      for cb in @onceCallbacks.profileChange
        console.log cb
        cb(@profile)
      @onceCallbacks.profileChange = []
    if @callbacks.profileChange
      for cb in @callbacks.profileChange
        console.log cb
        cb(@profile)

  once: (key, cb)->
    if @onceCallbacks[key]
      @onceCallbacks[key].push cb
    else
      @onceCallbacks[key] = [cb]

  on: (key, cb)->
    if @callbacks[key]
      @callbacks[key].push cb
    else
      @callbacks[key] = [cb]

  off: (key, cb)->
    if @callbacks[key]
      index = @callbacks[key].indexOf(cb)
      @callbacks[key].splice(index, 1);
    
  loggedIn: ->
    return @token and @username

  _saveTokenAndUsername: (token, username) ->
    @socket.disconnect()
    localStorage["username"] = username
    @username = username
    localStorage["token"] = token
    @token = localStorage["token"]
    @socket.connect("", query:"token=#{token}")

  uploadImage: (imageFile, callback) ->
    if !@loggedIn()
      return
    if !imageFile
      return
    data = new FormData()
    data.append "image", imageFile
    $.ajax(
      url: "/user/upload?token=#{auth.token}",
      data: data,
      cache: false,
      contentType: false,
      processData: false,
      type: 'POST'
    ).done( (data) =>
      callback true
    ).fail( ->
      callback false
    )

  authenticate: (username, password, callback) ->
    console.log username, password
    $.ajax(
      url: "#{window.location.origin}/login"
      type: "POST"
      contentType : "application/json"
      data: JSON.stringify(username: username, password: password)
    ).done((data, textStatus, jqXHR) =>
      if data.success && data.token
        @_saveTokenAndUsername data.token, username
        @once 'profileChange', callback
      else
        callback false, data.error
    ).fail((jqXHR, textStatus, errorThrown)=>
      callback false, {error: "Cannot connect to server"}
    )

  signup: (username, password, email, name, callback) ->
    $.ajax(
      url: "#{window.location.origin}/signup"
      type: "POST"
      contentType : "application/json"
      data: JSON.stringify(
        username: username
        password: password
        email: email
        name: name
      )
    ).done((data, textStatus, jqXHR) =>
      if data.success and data.token
        @profile = {}
        # wait for profilechange before calling the callback
        @once 'profileChange', callback
        @_saveTokenAndUsername data.token, username
      else if data.error
        callback false, data.error
    ).fail((jqXHR, textStatus, errorThrown)=>
      callback false, {error: "Cannot connect to server"}
    )

  logout: ->
    localStorage.removeItem "token"
    localStorage.removeItem "username"
    @username = null
    @token = null

module.exports = auth