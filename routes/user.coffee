express = require 'express'
router = express.Router()
mongoose = require 'mongoose'
User = mongoose.model 'User'
Message = mongoose.model 'Message'
jwt = require 'jsonwebtoken'
manager = require "../socket/manager"

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


broadcastProfileChange = (userObj) ->
  for soc in manager.allSocketsForUser(userObj.username)
    soc.emit "profileChange", userObj

getUserProfile = (username, callback) ->
  User.findOne({username: username})
    .select("name username image.large contacts")
    .populate('contacts', 'username image.large')
    .exec (err, user) ->
      if err || !user
        return callback()
      callback user.toObject()


router.post '/upload', (req, res, next) ->
  console.log "upload"
  req.user.attach 'image', req.files.image, (err) ->
    if err 
      return next(err)
    req.user.save (err) ->
      if err
        return next(err);
      getUserProfile req.user.username, (userProfile)->
        if !userProfile
          return next new Error "Failed to load user"
        res.send userProfile
        broadcastProfileChange userProfile


router.get '/conversation/:username', (req, res, next) ->
  username = req.params.username
  before = if req.query.before then new Date(req.query.before) else Date.now()

  User.findOne({username: username})
  .select("name username image.large")
  .exec (err, user)->
    if err || !user
      res.send 
        messages: []
        userProfile: false
    else if !req.user.hasContact(username)
      res.send 
        messages: []
        userProfile: user.toObject()
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
          res.send 
            messages: messageDatas
            userProfile: user.toObject()

router.put '/add/:username', (req, res, next) ->
  username = req.params.username
  message = req.body.message || ""
  if username == req.user.username
    return res.send success: false
  User.loadWithUsername username, (err, toUser) ->
    if err || !toUser
      return res.send success: false
    if req.user.hasContact username
      return res.send success: true
    req.user.contacts.push toUser.id
    req.user.save (ferr)->
      if ferr
        return res.send success: false
      getUserProfile req.user.username, broadcastProfileChange
      if toUser.hasContact req.user.username
        return res.send success: true
      toUser.contacts.push req.user.id
      toUser.save (terr)->
        if terr
          return res.send success: false
        res.send success: true
        getUserProfile username, broadcastProfileChange

router.get '/profile/:username', (req, res, next) ->
  username = req.params.username
  getUserProfile username, (userProfile)->
    if !userProfile
      return next new Error "Failed to load user"
    res.send userProfile


module.exports = router