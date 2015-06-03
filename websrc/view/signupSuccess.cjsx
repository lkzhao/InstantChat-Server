React = require "react/addons"

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
FontIcon = mui.FontIcon
FlatButton = mui.FlatButton
Tabs = mui.Tabs
Tab = mui.Tab

auth = require "../util/Auth"
RequireAuth = require "../util/requireLogin"
RequireProfile = require "../util/requireProfile"
socket = auth.socket

Router = require "react-router"
Navigation = Router.Navigation

module.exports = React.createClass  
  mixins:[Navigation, RequireAuth, RequireProfile]

  getInitialState: ->
    uploaded: false

  handleUpload: ->
    auth.uploadImage $('#imageUpload')[0].files[0], (success) =>
      if success
        @setState uploaded:true
      else
        return
        # TODO show error

  handleImageClick: ->
    $("#imageUpload").click()

  handleSkip: ->
    @transitionTo "app"

  render: ->
    <Paper className="center signupSucess" zDepth={2}>
      <div className="dialogHeader">
      </div>
      <input type="file" id="imageUpload"  style={display:"none"} onChange={@handleUpload}/>
      <div className="profileImage" onClick={@handleImageClick}>
        <img src={@state.profile.image} />
      </div>
      <p>Welcome <em>{@state.profile.name || @state.profile.username}</em>!<br/><br/>Please upload a display picture for your account, so people can recognize you.</p>
      <FlatButton style={width:"100%"} onClick={@handleSkip} secondary={true} >
        {if @state.uploaded then "Done" else "Skip"}
      </FlatButton>
    </Paper>