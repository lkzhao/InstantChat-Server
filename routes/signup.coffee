express = require 'express'
router = express.Router()
mongoose = require 'mongoose'
User = mongoose.model 'User'

router.post '/', (req, res) ->
  user = new User req.body
  user.save (err) ->
    if err
      allErrors = (info.message for field, info of err.errors)
      res.json {success: false, error: allErrors.join(", ")}
    else
      res.json {success: true}

module.exports = router