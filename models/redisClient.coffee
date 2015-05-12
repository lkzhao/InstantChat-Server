
redis = require "redis"

client = redis.createClient()
pub = redis.createClient()
sub = redis.createClient()
lock = require("redis-lock")(client)

client.on "error", (err) ->
  console.log "Error #{err}"

module.exports = 
  lock: lock
  client: client
  pub: pub
  sub: sub