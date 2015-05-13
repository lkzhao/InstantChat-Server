
express = require 'express'
jwt = require 'jsonwebtoken'
mongoose = require 'mongoose'
User = mongoose.model 'User'
router = express.Router()

jwtSecret = process.env.JWT_SECRET

# POST /login
router.post '/', (req, res) ->
  username = req.param("username")
  options =
    criteria:
      username: username
    select: "hashed_password salt"

  profile =
    username: username

  User.load options, (err, user) ->
    if (err)
      res.json {success:false, error: "Failed to load user"}
    else
      if user.authenticate req.param("password")
        token = jwt.sign profile, jwtSecret, { expiresInMinutes: 60*5 }
        res.json {success:true, token: token}
      else
        res.json {success:false, error: "wrong password"}

module.exports = router