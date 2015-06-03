express = require 'express'
router = express.Router()
mongoose = require 'mongoose'
User = mongoose.model 'User'

router.post '/', (req, res) ->
  user = new User req.body
  user.save (err) ->
    if err
      res.json {success: false, error: err.errors}
    else
      res.json {success: true}

module.exports = router