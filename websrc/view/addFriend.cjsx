
mui = require "material-ui"
AppBar =  mui.AppBar
RaisedButton = mui.RaisedButton
FlatButton = mui.FlatButton
TextField = mui.TextField
Paper = mui.Paper
DialogWindow = mui.DialogWindow

Router = require "react-router"
Navigation = Router.Navigation

auth = require "../util/Auth"

React = require "react/addons"

module.exports = React.createClass
  mixins:[Navigation]

  getInitialState: ->
    message: ""

  handleChange: (e)->
    @setState message:e.target.value

  handleSend: ->
    $.ajax(
      url: "/user/add/#{@props.userProfile.username}?token=#{auth.token}",
      contentType : "application/json"
      data: JSON.stringify(message: @state.message),
      type: 'PUT'
    ).done( (data) =>
      if !data.success
        #TODO display error
        return
    ).fail( ->
      #TODO display error
      return
    )

  render: ->
    name = @props.userProfile.name || @props.userProfile.username
    <div className="dialogContent">
      <img src={@props.userProfile.image} />
      <h1>{name} <small>{if @props.userProfile.name then " (#{@props.userProfile.username})"}</small></h1>
      <h3>Send {name} a friend request?</h3>
      <TextField key="chatInput" ref="chatInput" style={width:"100%"} floatingLabelText="Message" className="input" hintText="Hi, I would like to add you as friend!"
        multiLine={true} value={@state.message} onChange={@handleChange} disabled={@state.loading}/>
      <FlatButton style={float:"right"} label="Send" primary={true} onClick={@handleSend}/>
    </div>