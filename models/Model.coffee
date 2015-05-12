client = require("./redisClient").client

class Model
  constructor: (@fromUser, @toUser, @date, @content) ->

  @get: (username, callback) ->
    user = new User username
    user.load (success) ->
      callback user

  @exist: (username, callback) ->
    user = new User username
    user.load callback

  @key: (username) ->
    "user:#{username}"

  key: ->
    User.key @username

  load: (callback) ->
    client.get @key, (err, reply) =>
      if reply
        stored = JSON.parse reply.toString()
        for key, value of stored
          @[key] = value
        callback(true)
      else
        callback(false)

  save: ->
    jsonObj = {}
    for key in ["username", "email", "password", "devices"]
      jsonObj[key] = this[key]
    jsonString = JSON.stringify jsonObj
    client.set @key, jsonString


module.exports = Message