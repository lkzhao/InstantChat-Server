
express = require 'express'
jwt = require 'jsonwebtoken'
mongoose = require 'mongoose'
User = mongoose.model 'User'
router = express.Router()

jwtSecret = process.env.JWT_SECRET


# POST /login
router.post '/', (req, res) ->
  console.log req.body
  username = req.param("username")
  options =
    criteria:
      username: username
    select: "hashed_password salt"

  profile =
    username: username

  User.load options, (err, user) ->
    if err || !user
      res.send {success:false, error: "Failed to load user"}
    else
      if user.authenticate req.param("password")
        token = jwt.sign profile, jwtSecret, { expiresInMinutes: 60*24*30 }
        res.send {success:true, token: token}
      else
        res.send {success:false, error: "wrong password"}

module.exports = router