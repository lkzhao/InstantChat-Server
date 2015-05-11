
express = require 'express'
jwt = require 'jsonwebtoken'
User = require '../models/User'

router = express.Router();

jwtSecret = process.env.JWT_SECRET

# POST /login
router.post '/', (req, res) ->
  
  user = new User req.param("username")
  user.load (success) ->
    if success
      console.log user.password, req.param("password")
      if user.password == req.param("password")
        profile = 
          username: user.username
        token = jwt.sign profile, jwtSecret, { expiresInMinutes: 60*5 }
        res.json {success:true, token: token}
      else
        res.json {success:false, error: "wrong password"}
    else
      res.json {success:false, error: "username exist"}

module.exports = router