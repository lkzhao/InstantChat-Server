defaultUsername = "anonymous"
token = localStorage["token"]
username = localStorage["username"]
if !username
  token = null


Auth = 
  username: username
  token: token
  socket: io.connect("", query:"token=#{token}")

  loggedIn: ->
    return @token and @username

  authenticate: (username, password, callback) ->
    console.log username, password
    $.ajax(
      url: "#{window.location.origin}/login"
      type: "POST"
      contentType : "application/json"
      data: JSON.stringify(username: username, password: password)
    ).done((data, textStatus, jqXHR) =>
      if data.success && data.token
        localStorage["username"] = username
        @username = username
        localStorage["token"] = data.token
        @token = localStorage["token"]
        @socket.connect("", query:"token=#{token}")
        callback true
      else
        callback false, data.error
    ).fail((jqXHR, textStatus, errorThrown)=>
      callback false
    )

  logout: ->
    localStorage.removeItem "token"
    localStorage.removeItem "username"
    @username = null
    @token = null


module.exports = Auth