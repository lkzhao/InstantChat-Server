

express = require 'express'
router = express.Router()
User = require '../models/User'

router.post '/', (req, res) ->

  user = new User req.param("username")

  # TODO: encode password
  user.password = req.param("password")
  user.email = req.param("email")

  # TODO: Validate
  User.exist user.username, (exist)->
    if exist
      res.json {success: false, error: "username exist"}
    else
      user.save()
      res.json {success: true}

module.exports = router