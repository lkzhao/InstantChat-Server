
mongoose = require('mongoose')

Schema = mongoose.Schema

MessageSchema = new Schema
  fromUser: {type : Schema.ObjectId, ref : 'User'},
  toUser: {type : Schema.ObjectId, ref : 'User'},
  date: { type: String, default: '' }
  content: { type: String, default: '' }


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
  delete ret._id
  delete ret.__v
  return ret

mongoose.model 'Message', MessageSchema