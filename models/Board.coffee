
mongoose = require('mongoose')

Schema = mongoose.Schema

BoardSchema = new Schema
  createAuthor: {type : Schema.ObjectId, ref : 'User'}
  createDate: { type: Date }
  type: { type: String, default: 'text' }
  metaData: { type: String, default: '{}' }

BoardSchema.methods = {}

BoardSchema.statics =
  load: (id, cb) ->
    @findOne({ _id : id })
      .populate('createAuthor', 'username')
      .exec(cb);

BoardSchema.options.toObject = {};
BoardSchema.options.toObject.transform = (doc, ret, options) ->
  ret.createAuthor = ret.createAuthor.username
  ret.id = ret._id
  ret.metaData = JSON.parse ret.metaData
  delete ret._id
  delete ret.__v
  return ret

mongoose.model 'Board', BoardSchema