client = require("./redisClient").client
Message = require "../models/Message"

class User
  constructor: (@username) ->
    @incomingMessages = []
    @outgoingMessages = []

  @get: (username, callback) ->
    user = new User username
    user.load (success) ->
      if success
        callback user
      else
        callback null

  @exist: (username, callback) ->
    user = new User username
    user.load callback

  @key: (username) ->
    "user:#{username}"

  key: ->
    User.key @username

  load: (callback) ->
    client.get @key(), (err, reply) =>
      if reply
        stored = JSON.parse reply.toString()
        for key, value of stored
          @[key] = value
        callback(true)
      else
        callback(false)

  toData: ->
    jsonObj = {}
    for key in ["username", "email", "password", "devices", "incomingMessages", "outgoingMessages"]
      jsonObj[key] = this[key]
    jsonObj

  save: (callback = ->)->
    jsonString = JSON.stringify @toData()
    client.set @key(), jsonString, (err) ->
      callback(!err)

  removeMessage: (messageId, callback) ->
    filterFn = (msgId) ->
      msgId and msgId != messageId
    @incomingMessages = @incomingMessages.filter filterFn
    @outgoingMessages = @outgoingMessages.filter filterFn
    @save(callback)





module.exports = User