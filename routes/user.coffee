express = require 'express'
router = express.Router()
mongoose = require 'mongoose'
User = mongoose.model 'User'
jwt = require 'jsonwebtoken'


jwtSecret = process.env.JWT_SECRET

router.use (req, res, next) ->
  if !req.param("token")
    return next new Error "No Token Provided"
  try
    decoded = jwt.verify req.param("token") , jwtSecret
    User.loadWithUsername decoded.username, (err, user) ->
      if err
        next(err)
      else if !user
        next new Error "No User"
      else
        req.user = user
        next()
  catch err
    next(err)



router.post '/upload', (req, res, next) ->
  req.user.attach 'image', req.files.image, (err) ->
    if err 
      return next(err)
    req.user.save (err) ->
      if err
        return next(err);
      res.send 'Upload image success!'

module.exports = router