
mongoose = require('mongoose')
crate = require('mongoose-crate')
S3 = require('mongoose-crate-s3')
GraphicsMagic = require('mongoose-crate-gm')

Schema = mongoose.Schema

MessageSchema = new Schema
  fromUser: {type : Schema.ObjectId, ref : 'User'},
  toUser: {type : Schema.ObjectId, ref : 'User'},
  toBoard: {type : Schema.ObjectId, ref : 'Board'},
  date: { type: Date }
  type: { type: String, default: 'text' }
  content: { type: String, default: '' }
  binaryContent: { type: Buffer }
  metaData: { type: String, default: '{}' }


MessageSchema.methods = {}

MessageSchema.statics =
  load: (id, cb) ->
    @findOne({ _id : id })
      .populate('fromUser', 'username')
      .populate('toUser', 'username')
      .exec(cb);

MessageSchema.options.toObject = {};
MessageSchema.options.toObject.transform = (doc, ret, options) ->
  ret.fromUser = ret.fromUser.username
  ret.toUser = ret.toUser.username
  ret.id = ret._id
  ret.metaData = JSON.parse ret.metaData
  delete ret._id
  delete ret.__v
  return ret

MessageSchema.plugin crate,
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
            resize: '300x300'
            format: '.jpg'
          original:{}

mongoose.model 'Message', MessageSchema