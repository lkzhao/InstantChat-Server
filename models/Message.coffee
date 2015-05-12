client = require("./redisClient").client

class Message
  constructor: (@fromUser, @toUser, @date, @content) ->

  @get: (id, callback) ->
    message = new Message 
    message.id = id
    message.load (success) ->
      if success
        callback message
      else
        callback null

  @exist: (id, callback) ->
    message = new Message 
    message.id = id
    message.load callback

  @key: (id) ->
    "message:#{id}"

  key: ->
    Message.key @id

  load: (callback) ->
    client.get @key(), (err, reply) =>
      if reply
        stored = JSON.parse reply.toString()
        for key, value of stored
          @[key] = value
        callback(true)
      else
        callback(false)

  toData: =>
    jsonObj = {}
    for key in ["id", "fromUser", "toUser", "date", "content"]
      jsonObj[key] = @[key]
    jsonObj

  save: (callback = ->) ->
    jsonString = JSON.stringify @toData()
    if @id
      client.set @key(), jsonString, (err) ->
        callback(!err)
    else
      client.incr "id:messages", (err, reply) =>
        if err
          callback(!err)
          return
        @id = reply
        client.set @key(), jsonString, (err) ->
          callback(!err)

  remove: ->
    if @id
      client.del @key


module.exports = Message