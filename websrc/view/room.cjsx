
React = require "react/addons"
ReactCSSTransitionGroup = React.addons.CSSTransitionGroup

Router = require "react-router"
Navigation = Router.Navigation

auth = require "../util/Auth"
RequireAuth = require "../util/requireLogin"
RequireProfile = require "../util/requireProfile"
AddFriend = require "./addFriend"
socket = auth.socket

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
Tabs = mui.Tabs
Tab = mui.Tab
IconButton = mui.IconButton
FontIcon = mui.FontIcon
RaisedButton = mui.RaisedButton
FlatButton = mui.FlatButton
FloatingActionButton = mui.FloatingActionButton


Header = require "./header"
SideBar = require "./sideBar"

Message = React.createClass

  componentWillReceiveProps: (nextProps) ->
    if nextProps.message.viewTime and nextProps.message.metaData.expireTime
      if @timer
        clearInterval @timer
      @timer = setInterval @handleTimerUpdate, 1000

  handleTimerUpdate: ->
    if (new Date() - @props.message.viewTime)/1000 > @props.message.metaData.expireTime
      clearInterval @timer
      @props.onDelete @props.message
    else
      @forceUpdate()

  render: ->
    message = @props.message
    className = ""
    bottomStatus = ""
    topStatus = ""
    content = message.content
    if message.announcement
      content = message.announcement
    else
      style = {}
      if message.fromUser == auth.username
        className = "outgoing"
        style = 
          color: "white"
          background: Colors.green400
      else
        className = "incoming"
        topStatus = <em>{message.username}</em>

      if message.type == "audio"
        l = message.metaData.length.toFixed(1)
        content = "▶   #{l}s"

      if message.viewTime and message.metaData.expireTime
        e = (Math.max(0, message.metaData.expireTime - (new Date() - message.viewTime)/1000)).toFixed(0)
        bottomStatus = "#{e}s"

      return <div className={className+" message"}>
        <div className="topStatus">{topStatus}</div>
        <Paper style={style}>
          {if message.type == "audio"
            <FlatButton onClick={@props.onClick} label={content}/>
          else
            <div className="bubble">{content}</div>}
        </Paper>
        <div className="bottomStatus">{bottomStatus}</div>
      </div>
    <div className={className+" message"}>{content}</div>

ChatView = React.createClass
  mixins:[RequireAuth, RequireProfile]
  getInitialState: ->
    typing: []
    transitioning: false
    loading: false
    nomore: false
    message: ""
    userProfile: {}
    tab: 0
    messages:[]

  handleChange: (e) ->
    @setState
      message: e.target.value

  sendMessage: ->
    if @state.message
      message =
        sendTo: @props.params.roomId
        content: @state.message
        date: (new Date()).toISOString()
        type: "text"
        viewTime: null
        messageId: null
        metaData:
          expireTime: 20

      socket.emit 'SEND', message, (data) ->
        if data.messageId
          console.log "Success"

      @setState message:""

  handleScroll: ->
    scrollTop = $(window).scrollTop()
    scrollBottom = scrollTop + $(window).height()
    rectTop = $(".roomView").offset().top
    rectBottom = rectTop + $(".roomView").height()

  handleEnterRoom: (data) ->
    message = 
      announcement: "Welcome to Socket.IO Chat – #{data.room}"
    @setState 
      messages: @state.messages.concat([message])

  handleNewMessage: (data) ->
    console.log data
    if data.fromUser != @state.profile.username and data.fromUser != @props.params.roomId
      return
    data.date = new Date(data.date)
    @setState messages: @state.messages.concat([data])
    @handleScroll()
    if data.metaData.expireTime and data.fromUser != @state.profile.username and data.type != "audio"
      console.log "VIEW!!"
      socket.emit 'VIEW', {messageIds:[data.id], date:(new Date()).toISOString()}

  handleTyping: (data) ->
    @setState
      typing: @state.typing.concat [data.username]

  handleStopTyping: (data) ->
    @setState
      typing: @state.typing.filter ->
        @ != data.username

  handleViewMessage: (data) ->
    console.log "VIEW", data, @state.messages
    messages = @state.messages
    date = new Date(data.date)
    for message in messages
      for messageId in data.messageIds
        if message.id == messageId
          message.viewTime = date
          break
    @setState messages:messages

  handleDeleteMessage: (message) ->
    messages = @state.messages
    messages.splice(messages.indexOf(message),1)
    @setState messages:messages

  componentWillReceiveProps: (nextProps) ->
    if nextProps.params.roomId != @props.params.roomId
      @setState messages: []
      @getInitialMessages nextProps.params.roomId

  componentWillUpdate: (nextProps, nextState) ->
    if @state.messages.length < nextState.messages.length
      @previousHeight = $(".roomView").height()

  componentDidUpdate: (prevProps, prevState) ->
    if prevState.messages[prevState.messages.length - 1] != @state.messages[@state.messages.length - 1]
      window.scrollTo(0, $(window).scrollTop() + ($(".roomView").height() - @previousHeight))

  componentDidMount: ->
    $(window).on 'scroll', @handleScroll
    socket.on 'RECEIVE', @handleNewMessage
    socket.on 'VIEW', @handleViewMessage
    socket.on 'typing', @handleTyping
    socket.on 'stop typing', @handleStopTyping
    console.log auth.username, @props.params.roomId

    @getInitialMessages @props.params.roomId

  componentWillUnmount: ->
    $(window).off 'scroll', @handleScroll
    socket.removeListener 'RECEIVE', @handleNewMessage
    socket.removeListener 'VIEW', @handleViewMessage
    socket.removeListener 'typing', @handleTyping
    socket.removeListener 'stop typing', @handleStopTyping

  getInitialMessages: (user) ->
    @setState loading:true
    $.get("/user/conversation/#{user}?token=#{auth.token}")
      .done( (data)=>
        messages = data.messages || []
        viewTime = (new Date()).toISOString()
        viewedMessages = []
        for m in messages
          m.date = new Date(m.date)
          if m.metaData.expireTime && m.type != "audio" && m.fromUser!=@state.profile.username
            viewedMessages.push m.id
        @setState
          messages: messages
          transitioning: false
          loading: false
          nomore: messages.length < 20
          userProfile: data.userProfile
        if viewedMessages.length > 0
          socket.emit "VIEW", {messageIds: viewedMessages, date:viewTime}
      ).fail( =>
        @setState loading:false
      )

  handleClick: (message) ->
    if message.type == "audio"
      if message.buffer
        player = AV.Player.fromBuffer(message.buffer)
        player.play()
      else
        auth.socket.emit "BINARY", {messageId:message.id}, (soundBuffer) =>
          message.buffer = soundBuffer
          player = AV.Player.fromBuffer(soundBuffer);
          player.play()
          if message.metaData.expireTime && message.fromUser!=@state.profile.username
            socket.emit "VIEW", {messageIds: [message.id], date:(new Date()).toISOString()}

  loadPrevious: ->
    before = @state.messages[0].date || Date.now()
    before = before.toString()
    @setState loading:true
    $.get("/user/conversation/#{@props.params.roomId}?token=#{auth.token}&before=#{before}")
      .done( (data)=>
        messages = data.messages || []
        viewTime = (new Date()).toISOString()
        viewedMessages = []
        for m in messages
          m.date = new Date(m.date)
          if m.metaData.expireTime && m.type != "audio" && m.fromUser!=@state.profile.username
            viewedMessages.push m.id
        @setState 
          messages: messages.concat(@state.messages)
          transitioning: false
          loading: false
          nomore: messages.length < 20
        if viewedMessages
          socket.emit "VIEW", {messageIds: viewedMessages, date:viewTime}
      ).fail( =>
        @setState loading:false
      )

  render: ->
    messages = @state.messages.map (message) =>
      <Message key={"message"+message.id} message={message} username={auth.username} onDelete={@handleDeleteMessage} onClick={@handleClick.bind(this, message)} />

    className = "roomView"
    if @state.transitioning
      className += " transitioning"


    sendButtonClassName = "sendButton "+(if @state.message.length>0 then "animated bounceIn" else "")

    topControl = null
    if @state.loading || !@state.profile
      topControl = <div className="loadPrevious" key="loadPrevious"><FontIcon className="fa fa-spinner fa-pulse"/></div>
    else if !@state.nomore
      topControl = <div className="loadPrevious" key="loadPrevious"><RaisedButton  onClick={@loadPrevious} primary={true} label="Load Previous" /></div>

    isFriend = false
    if @state.profile.contacts && @state.userProfile.username
      for c in @state.profile.contacts
        if c.username == @state.userProfile.username
          isFriend = true

    <div className="container">
      <div className={className}>
        {if isFriend
          <div>
            <ReactCSSTransitionGroup key={"transitionGroup"+@props.params.roomId} className="messages tabContent" transitionName="message" component="div">
              {topControl}
              {messages}
            </ReactCSSTransitionGroup>
            <div className="typing">
            </div>
            <div className="chatInput">
              <TextField key="chatInput" ref="chatInput" style={width:"100%"} className="input" hintText="Type your message"
                multiLine={true} value={@state.message} onChange={@handleChange} disabled={@state.loading}/>
              
              <div className={sendButtonClassName}>
                <FloatingActionButton secondary=true iconClassName="fa fa-paper-plane-o" onClick={@sendMessage}/>
              </div>
            </div>
          </div>
        else if @state.loading
          <FontIcon className="fa fa-spinner fa-pulse"/>
        else if @state.userProfile
          <AddFriend userProfile={@state.userProfile} />
        else
          <div> User not found </div>
        }
      </div>
    </div>

module.exports = React.createClass
  render: ->
    <div>
      <Header />
      <SideBar {...this.props}/>
      <ChatView {...this.props}/>
    </div>