var app = require('express')();
var jwt = require('jsonwebtoken');
var http = require('http').Server(app);
var io = require('socket.io')(http);
var socketioJwt = require("socketio-jwt");
var bodyParser = require('body-parser');


app.get('/', function(req, res){
  res.sendfile('index.html');
});

var jwtSecret = "S0ySauc3"
app.use(bodyParser.json());
app.post('/login', function (req, res) {
  // TODO: validate the actual user user
  var profile = {
  	username: req.param("username"),
    first_name: 'John',
    last_name: 'Doe',
    email: 'john@doe.com',
    id: 123
  };

  // we are sending the profile in the token
  var token = jwt.sign(profile, jwtSecret, { expiresInMinutes: 60*5 });

  res.json({token: token});
});

io.use(socketioJwt.authorize({
  secret: jwtSecret,
  handshake: true
}));


var users = {}
io.on('connection', function(socket){
  var username = socket.decoded_token.username
  console.log(username+' connected');
  if (username in users) {
    users[username].push(socket)
  }else{
    users[username] = [socket]
  }

  socket.on('disconnect', function(){
    if (users[username].length == 1){
      delete users[username]
    }else{
      users[username].splice(users[username].indexOf(socket), 1);
    }
    console.log(username+' disconnected');
  });

  socket.on('error', function(err){
    console.log('Error: '+err);
  });

  // view message
  socket.on('ChatViewMessage', function(fromUser, msgHash, viewTime){
    if (fromUser in users){
      console.log(fromUser+" read "+viewTime)
      users[fromUser].forEach(function(soc){
        soc.emit('ChatViewMessage', msgHash, viewTime);
      })
    }else{
      console.log(fromUser+" not online")
    }
  })

  // send message
  socket.on('ChatSendNewUserMessage', function(sendTo, date, content, fn){
    var message = {
      fromUser: username,
      toUser: sendTo,
      date: date,
      content: content
    };
    if (sendTo in users){
      users[sendTo].forEach(function(soc){
        soc.emit('ChatReceiveNewUserMessage', message);
      })
      users[username].forEach(function(soc){
        soc.emit('ChatReceiveNewUserMessage', message);
      })
      fn(true, 0, "Success")
    }else{
      fn(false, 1, "User not online")
      console.log(sendTo+" is not online")
    }
    console.log(username+'->'+sendTo+': '+content);
  });
});

http.listen(3000, function(){
  console.log('listening on *:3000');
});
