express = require 'express'
router = express.Router()
mongoose = require 'mongoose'
User = mongoose.model 'User'
Message = mongoose.model 'Message'
jwt = require 'jsonwebtoken'


jwtSecret = process.env.JWT_SECRET

router.use (req, res, next) ->
  if !req.query.token
    return next new Error "No Token Provided"
  try
    decoded = jwt.verify req.query.token , jwtSecret
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
  console.log "upload"
  req.user.attach 'image', req.files.image, (err) ->
    if err 
      return next(err)
    req.user.save (err) ->
      console.log "save failed #{err}"
      if err
        return next(err);
      res.send 'Upload image success!'

router.get '/conversation/:username', (req, res) ->
  username = req.params.username
  before = if req.query.before then new Date(req.query.before) else Date.now()
  User.loadWithUsername username, (err, user)->
    if err || !user
      next new Error "Failed to load user"
    else
      Message.find(
          $and: [
            { $or: [
              { $and: [{toUser: req.user}, {fromUser: user}] }
              { $and: [{toUser: user}, {fromUser: req.user}] }
            ]}
            {date: { $lt: before }}
          ]
        ).populate('fromUser toUser','username')
        .sort(date: -1)
        .limit(20)
        .exec (err, messages)->
          messageDatas = []
          if messages
            for msg in messages.reverse()
              messageDatas.push msg.toObject()
          res.send messageDatas

router.get '/contacts', (req, res) ->
  User.findOne({ username:req.user.username })
    .select('contacts')
    .populate('contacts', 'username image.large')
    .exec (ferr, user) ->
      contactDatas = []
      if user.contacts
        for contact in user.contacts
          contactDatas.push 
            username:contact.username
            image:contact.image.large.url

      res.send contactDatas

router.get '/profile/:username', (req, res) ->
  username = req.params.username
  User.findOne({username: username})
  .select("name username image.large")
  .populate('contacts')
  .exec (err, user)->
    if err || !user
      return next new Error "Failed to load user"
    res.send user.toObject()


module.exports = router