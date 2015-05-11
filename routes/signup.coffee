

express = require 'express'
router = express.Router()
client = require('../redisClient').client

router.post '/', (req, res) ->
  
  # TODO: encode password
  profile =
    username: req.param("username")
    password: req.param("password")
    email: req.param("email")

  # TODO: Validate

module.exports = router