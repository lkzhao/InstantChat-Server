
mongoose = require('mongoose')

Schema = mongoose.Schema

MessageSchema = new Schema
  fromUser: {type : Schema.ObjectId, ref : 'User'},
  toUser: {type : Schema.ObjectId, ref : 'User'},
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

mongoose.model 'Message', MessageSchema