
mongoose = require('mongoose')
crypto = require('crypto')
crate = require('mongoose-crate')
S3 = require('mongoose-crate-s3')
GraphicsMagic = require('mongoose-crate-gm')

Schema = mongoose.Schema

UserSchema = new Schema
  name: { type: String, default: '' }
  email: { type: String, default: '' }
  username: { type: String, default: '' }
  hashed_password: { type: String, default: '' }
  salt: { type: String, default: '' }
  contacts: [{type: Schema.ObjectId, ref : 'User'}]
  deviceIds: [String]


UserSchema
  .virtual('password')
  .set((password) ->
    @_password = password
    @salt = @makeSalt()
    @hashed_password = @encryptPassword(password)
  )
  .get( -> @_password )


validatePresenceOf = (value) ->
  return value && value.length

UserSchema.path('email').validate((email) ->
  return email.length
, 'Email cannot be blank')

UserSchema.path('email').validate((email, fn) ->
  User = mongoose.model('User')
  # Check only when it is a new user or when email field is modified
  if @isNew || @isModified('email')
    User.find({ email: email }).exec((err, users) ->
      fn !err && users.length == 0
    )
  else 
    fn(true)
, 'Email already exists')

UserSchema.path('username').validate((username, fn) ->
  User = mongoose.model('User')
  # Check only when it is a new user or when email field is modified
  if @isNew || @isModified('username')
    User.find({ username: username }).exec((err, users) ->
      fn !err && users.length == 0
    )
  else 
    fn(true)
, 'Username already exists')

UserSchema.path('username').validate((username) ->
  return username.length
, 'Username cannot be blank')

UserSchema.path('hashed_password').validate((hashed_password) ->
  return hashed_password.length
, 'Password cannot be blank')



UserSchema.pre('save', (next) ->
  if !@isNew
    return next()

  if !validatePresenceOf(@password)
    next(new Error('Invalid password'))
  else
    next()
)


UserSchema.methods = 
  ###
   * Authenticate - check if the passwords are the same
   *
   * @param {String} plainText
   * @return {Boolean}
   * @api public
  ###

  authenticate: (plainText) ->
    return @encryptPassword(plainText) == @hashed_password

  ###
   * Make salt
   *
   * @return {String}
   * @api public
  ###

  makeSalt: () ->
    return Math.round((new Date().valueOf() * Math.random())) + ''

  ###
   * Encrypt password
   *
   * @param {String} password
   * @return {String}
   * @api public
  ###

  encryptPassword: (password) ->
    if !password 
      return ''
    try 
      return crypto
        .createHmac('sha1', @salt)
        .update(password)
        .digest('hex')
    catch err
      return ''

###
 * Statics
###

UserSchema.statics =

  ###
   * Load
   *
   * @param {Object} options
   * @param {Function} cb
   * @api private
  ###
  load: (options, cb) ->
    options.select = options.select || 'name username'
    @findOne(options.criteria)
      .select(options.select)
      .exec(cb)

  loadWithUsername: (username, cb) ->
    @findOne({username: username})
      .select("name username deviceIds contacts")
      .populate('contacts')
      .exec(cb)

UserSchema.options.toObject = {}
UserSchema.options.toObject.transform = (doc, ret, options) ->
  ret.id = ret._id
  if ret.image && ret.image.large
    ret.image = ret.image.large.url
  delete ret._id
  return ret

UserSchema.plugin crate,
  storage:
    new S3
      key: 'AKIAJPH7WDSTFTOXAK7Q'
      secret: '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'
      bucket: 'instantchat'
  fields:
    image:
      processor: new GraphicsMagic
        transforms:
          small:
            resize: '150x150'
            format: '.jpg'
          medium:
            resize: '250x250'
            format: '.jpg'
          large:
            resize: '512x512'
            format: '.jpg'

mongoose.model 'User', UserSchema