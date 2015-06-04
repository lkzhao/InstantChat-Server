
React = require "react/addons"


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
FloatingActionButton = mui.FloatingActionButton


Header = require "./header"
SideBar = require "./sideBar"

Message = React.createClass
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

      return <Paper zDepth={1} style={style} className={className+" message"}>
        <div className="topStatus">{topStatus}</div>
        <div className="bubble">{content}</div>
      </Paper>
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
        date: Date.now().toString()
        type: "text"
        viewTime: null
        messageId: null

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
    data.date = new Date(data.date)
    @setState messages: @state.messages.concat([data])
    @handleScroll()

  handleTyping: (data) ->
    @setState
      typing: @state.typing.concat [data.username]

  handleStopTyping: (data) ->
    @setState
      typing: @state.typing.filter ->
        @ != data.username


  componentWillReceiveProps: (nextProps) ->
    if nextProps.params.roomId != @props.params.roomId
      if @timer
        clearTimeout @timer
      @getInitialMessages nextProps.params.roomId
      @setState transitioning: true

  componentWillUpdate: (nextProps, nextState) ->
    if @state.messages.length < nextState.messages.length
      @previousHeight = $(".roomView").height()

  componentDidUpdate: (prevProps, prevState) ->
    if prevState.messages[prevState.messages.length - 1] != @state.messages[@state.messages.length - 1]
      window.scrollTo(0, $(window).scrollTop() + ($(".roomView").height() - @previousHeight))

  componentDidMount: ->
    $(window).on 'scroll', @handleScroll
    socket.on 'RECEIVE', @handleNewMessage
    socket.on 'typing', @handleTyping
    socket.on 'stop typing', @handleStopTyping
    console.log auth.username, @props.params.roomId

    @getInitialMessages @props.params.roomId

  componentWillUnmount: ->
    $(window).off 'scroll', @handleScroll
    socket.removeListener 'RECEIVE', @handleNewMessage
    socket.removeListener 'typing', @handleTyping
    socket.removeListener 'stop typing', @handleStopTyping

  getInitialMessages: (user) ->
    @setState loading:true
    $.get("/user/conversation/#{user}?token=#{auth.token}")
      .done( (data)=>
        @setState 
          messages: data.messages || []
          transitioning: false
          loading: false
          nomore: data.messages.length == 0
          userProfile: data.userProfile
      ).fail( =>
        @setState loading:false
      )

  handleTabChange: (index) ->
    @setState tab:index

  loadPrevious: ->
    before = @state.messages[0].date || Date.now()
    before = before.toString()
    @setState loading:true
    $.get("/user/conversation/#{@props.params.roomId}?token=#{auth.token}&before=#{before}")
      .done( (data)=>
        @setState 
          messages: data.messages.concat(@state.messages)
          transitioning: false
          loading: false
          nomore: data.messages.length == 0
      ).fail( =>
        @setState loading:false
      )

  render: ->
    messages = @state.messages.map (message) =>
      <Message key={"message"+message.id} message={message} username={auth.username}/>

    className = "roomView"
    if @state.transitioning
      className += " transitioning"


    sendButtonClassName = "sendButton "+(if @state.message.length>0 then "animated bounceIn" else "")

    topControl = null
    if @state.loading || !@state.profile
      topControl = <FontIcon className="fa fa-spinner fa-pulse"/>
    else if !@state.nomore
      topControl = <RaisedButton  onClick={@loadPrevious} primary={true} label="Load Previous" />

    isFriend = false
    if @state.profile.contacts && @state.userProfile.username
      for c in @state.profile.contacts
        if c.username == @state.userProfile.username
          isFriend = true

    <div className="container">
      <div className={className}>
        {if isFriend
          <div>
            <div className="messages tabContent">
              <div className="loadPrevious">
                {topControl}
              </div>
              {messages}
            </div>
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