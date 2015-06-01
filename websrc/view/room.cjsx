getTimeStamp = ->
  date = new Date(Date.now())
  date.toString()

socket = require "../util/socket"
React = require "react/addons"

RightSideBar = require "./rightSideBar"
auth = require "../util/Auth"

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
Tabs = mui.Tabs
Tab = mui.Tab
IconButton = mui.IconButton
FontIcon = mui.FontIcon
RaisedButton = mui.RaisedButton

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
        bottomStatus = message.date
        style = 
          color: "white"
          background: Colors.red400
      else
        className = "incoming"
        topStatus = <em>{message.username}</em>
        bottomStatus = message.date

      return <Paper zDepth={1} style={style} className={className+" message"}>
        <div className="topStatus">{topStatus}</div>
        <div className="bubble">{content}</div>
        <div className="bottomStatus">{bottomStatus}</div>
      </Paper>
    <div className={className+" message"}>{content}</div>

module.exports = React.createClass
  getInitialState: ->
    typing: []
    fixedBar: false
    fixedHeader: false
    message: ""
    transitioning: false
    tab: 0
    messages:[]

  handleEnterKeyDown: (e) ->
    @sendMessage()
    e.preventDefault()

  handleChange: (e) ->
    @setState
      message: e.target.value

  sendMessage: ->
    time = getTimeStamp()
    # if there is a non-empty message and a socket connection
    if @state.message
      message =
        sendTo: @props.params.roomId
        content: @state.message
        date: time

      # tell server to execute 'new message' and send along one parameter
      socket.emit 'SEND', message, (data) ->
        console.log "SEND", data

      @setState message:""

  componentWillReceiveProps: (nextProps) ->
    if nextProps.params.roomId != @props.params.roomId
      if @timer
        clearTimeout @timer
      @timer = setTimeout =>
        socket.emit 'change room', nextProps.params.roomId
        rectBottom = $(".roomView").offset().top + $(".roomView").height() - $(window).height()
        window.scrollTo(0, if rectBottom > 0 then rectBottom else 0)
        @setState transitioning: false
      , 1000
      @setState transitioning: true

  componentWillUpdate: (nextProps, nextState) ->
    if @state.messages.length < nextState.messages.length
      @previousHeight = $(".roomView").height()

  componentDidUpdate: (prevProps, prevState) ->
    if prevState.messages.length < @state.messages.length
      window.scrollTo(0, $(window).scrollTop() + ($(".roomView").height() - @previousHeight))
    if @state.fixedHeader == prevState.fixedHeader and @state.fixedBar == prevState.fixedBar
      @handleScroll()

  handleScroll: ->
    scrollTop = $(window).scrollTop()
    scrollBottom = scrollTop + $(window).height()
    rectTop = $(".roomView").offset().top
    rectBottom = rectTop + $(".roomView").height()

    if scrollTop >= rectTop+150 && !@state.fixedHeader
      @setState fixedHeader: true
    else if scrollTop < rectTop+150 && @state.fixedHeader
      @setState fixedHeader: false

    if scrollBottom > rectBottom && @state.fixedBar
      @setState fixedBar: false
    else if scrollBottom <= rectBottom && !@state.fixedBar
      @setState fixedBar: true

  handleEnterRoom: (data) ->
    message = 
      announcement: "Welcome to Socket.IO Chat – #{data.room}"
    @setState 
      messages: @state.messages.concat([message])

  handleNewMessage: (data) ->
    @setState messages: @state.messages.concat([data])
    @handleScroll()

  handleTyping: (data) ->
    @setState
      typing: @state.typing.concat [data.username]

  handleStopTyping: (data) ->
    @setState
      typing: @state.typing.filter ->
        @ != data.username

  componentDidMount: ->
    $(window).on 'scroll', @handleScroll
    socket.on 'RECEIVE', @handleNewMessage
    socket.on 'typing', @handleTyping
    socket.on 'stop typing', @handleStopTyping
    console.log auth.username, @props.params.roomId
    #TODO check if logged in

  componentWillUnmount: ->
    $(window).off 'scroll', @handleScroll
    socket.removeListener 'RECEIVE', @handleNewMessage
    socket.removeListener 'typing', @handleTyping
    socket.removeListener 'stop typing', @handleStopTyping

  handleTabChange: (index) ->
    @setState tab:index

  render: ->
    messages = @state.messages.map (message) =>
      <Message key={"message"+message.id} message={message} username={auth.username}/>

    className = "roomView"
    if @state.transitioning
      className += " transitioning"
    if @state.fixedHeader
      className += " fixed"
    barClassName = if @state.fixedBar then "fixed chatInput" else "chatInput"

    tabContent = null
    if @state.tab == 0
      tabContent = <div>
        <div className="messages tabContent">
          {messages}
        </div>
        <div className="typing">
        </div>
        <div className={barClassName}>
          <TextField style={width:"100%"} className="input" hintText="Type your message"
            multiLine={true} value={@state.message} onChange={@handleChange} onEnterKeyDown={@handleEnterKeyDown} />
        </div>
      </div>
    else if @state.tab == 1
      tabContent = <div className="tabContent">
        <p> 
          This is another example of a tab template! 
        </p> 
        <p> 
          Fair warning - the next tab routes to home! 
        </p> 
      </div>
    else if @state.tab == 2
      tabContent = <div className="tabContent">
        <p> 
          This is another example of a tab template! 
        </p> 
        <p> 
          Fair warning - the next tab routes to home! 
        </p> 
      </div>

    <div className="container">
      <RightSideBar {...this.props}/>

      <Paper zDepth={2} className={className}>
        <header style={background:Colors.red400}>
          <div className="roomName">{@props.params.roomId}</div>
          <div className="headerBar" style={background:Colors.red400}>
            <div className="roomName">{@props.params.roomId}</div>
            <div className="tabs">
              <Tabs onChange={@handleTabChange}> 
                  <Tab label="Chat">
                  </Tab> 
                  <Tab label="Files">
                  </Tab>
                  <Tab label="Users">
                  </Tab>
              </Tabs>
            </div>
            <div className="menuButtons">
              <IconButton tooltip="Add to favorite">
                <FontIcon style={color:"white"} className="fa fa-heart"/>
              </IconButton>
            </div>
          </div>
        </header>
        {tabContent}
      </Paper>
    </div>