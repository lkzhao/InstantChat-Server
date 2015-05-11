
redis = require "redis"

client = redis.createClient()
pub = redis.createClient()
sub = redis.createClient()

client.on "error", (err) ->
  console.log "Error #{err}"

module.exports = 
  client: client
  pub: pub
  sub: sub