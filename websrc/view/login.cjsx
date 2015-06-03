React = require "react/addons"
auth = require "../util/Auth"
Router = require "react-router"
Navigation = Router.Navigation

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
FontIcon = mui.FontIcon
RaisedButton = mui.RaisedButton

repeat = (str, n) ->
  res = ''
  while n > 0
    res += str if n & 1
    n >>>= 1
    str += str
  res

module.exports = React.createClass  
  mixins:[Navigation, React.addons.LinkedStateMixin]

  getInitialState: ->
    username: ""
    password: ""
    usernameError: null
    passwordError: null
    globalError: null
    loading: false

  handlePasswordChange: (e) ->
    @setState password:e.target.value

  componentWillMount: ->
    if auth.loggedIn()
      @transitionTo "app"

  handleLogin: ->
    if !@state.username
      @setState usernameError:"Username cannot be empty"
    if !@state.password
      @setState passwordError:"Password cannot be empty"
    if !@state.password || !@state.username
      return
    @setState loading: true
    auth.authenticate @state.username, @state.password, (success, error)=>
      if success
        @transitionTo "app"
      else
        @setState 
          globalError:"Failed to login"
          loading: false

  render: ->
    <Paper className="center" zDepth={5}>
      <div>{@state.globalError}</div>
      <TextField
        style={width:"100%"}
        hintText="johnappleseed"
        floatingLabelText="Username" valueLink={@linkState('username')} errorText={@state.usernameError} />
      <TextField
        style={width:"100%"}
        type="password"
        floatingLabelText="Password" valueLink={@linkState('password')} errorText={@state.passwordError} />
      <RaisedButton style={width:"100%"} onClick={@handleLogin} secondary={true} label="">
        
        {if @state.loading then <FontIcon style={color:"white"} className="fa fa-spinner fa-pulse"/> else <span style={color:"white"}>Login</span>}
      </RaisedButton>
    </Paper>