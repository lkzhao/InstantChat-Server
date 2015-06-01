defaultUsername = "anonymous"
token = localStorage["token"]
username = localStorage["username"]
if !username
  token = null

Auth = 
  username: username
  token: token
  socket: io.connect(window.location.origin, token:token)

  loggedIn: ->
    @token && @username

  authenticate: (username, password, callback) ->
    console.log username, password
    $.ajax(
      url: "#{window.location.origin}/login"
      type: "POST"
      contentType : "application/json"
      data: JSON.stringify(username: username, password: password)
    ).done((data, textStatus, jqXHR) ->
      console.log data
      if data.success && data.token
        localStorage["username"] = username
        @username = username
        localStorage["token"] = data.token
        @token = localStorage["token"]
        io.connect(window.location.origin, token:token)
        callback true
      else
        callback false, data.error
    ).fail((jqXHR, textStatus, errorThrown)->
      callback true
    )

  logout: ->
    localStorage["token"] = null
    localStorage["username"] = null
    @username = null
    @token = null


module.exports = Auth