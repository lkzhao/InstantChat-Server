
jwt = require 'jsonwebtoken'

jwtSecret = process.env.JWT_SECRET

express = require 'express'
router = express.Router()
mongoose = require 'mongoose'
User = mongoose.model 'User'

router.post '/', (req, res) ->
  user = new User req.body
  user.save (err) ->
    profile =
      username: user.username
    if err
      res.json {success: false, error: err.errors}
    else
      token = jwt.sign profile, jwtSecret, { expiresInMinutes: 60*24*30 }
      res.send {success:true, token: token}

module.exports = router