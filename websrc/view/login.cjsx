React = require "react/addons"
auth = require "../util/Auth"
Router = require "react-router"
Navigation = Router.Navigation

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
FontIcon = mui.FontIcon
FlatButton = mui.FlatButton
Tabs = mui.Tabs
Tab = mui.Tab

module.exports = React.createClass  
  mixins:[Navigation, React.addons.LinkedStateMixin]

  getInitialState: ->
    name: ""
    email: ""
    username: ""
    password: ""

    usernameError: null
    passwordError: null
    emailError: null

    globalError: null
    loading: false

  handleUsernameChange: (e) ->
    @setState 
      username:e.target.value
      usernameError: null

  handlePasswordChange: (e) ->
    @setState 
      password:e.target.value
      passwordError: null

  handleEmailChange: (e) ->
    @setState 
      email:e.target.value
      emailError: null

  componentWillMount: ->
    if auth.loggedIn()
      @transitionTo "app"

  handleLogin: ->
    console.log "login"
    if @state.loading
      return
    if !@state.username
      @setState usernameError:"Username cannot be blank"
    if !@state.password
      @setState passwordError:"Password cannot be blank"
    if !@state.password || !@state.username
      return
    @setState loading: true
    auth.authenticate @state.username, @state.password, (success, error)=>
      if success
        @transitionTo "app"
      else
        @setState 
          globalError: error
          loading: false

  handleSignup: ->
    if @state.loading
      return
    @setState loading: true
    auth.signup @state.username, @state.password, @state.email, @state.name, (success, error) =>
      if success
        @transitionTo "signupSuccess"
      else
        errors = 
          loading: false
          usernameError: null
          passwordError: null
          emailError: null
          globalError: null
        for field, info of error
          if field == "error"
            errors.globalError = info
          if field == "email"
            errors.emailError = info.message
          else if field == "hashed_password"
            errors.passwordError = info.message
          else if field == "username"
            errors.usernameError = info.message
        @setState errors

  goToRoute: (tab) ->
    @setState globalError:null
    @transitionTo tab.props.route

  render: ->
    <Paper className="center" zDepth={2}>
      <Tabs initialSelectedIndex={if @props.pathname=="/login" then 0 else 1}> 
        <Tab label="Login" onActive={@goToRoute} route="login">
          <div className="inner">
            <div className="error">{@state.globalError}</div>
            <TextField
              key="username"
              style={width:"100%"}
              hintText="johnappleseed"
              floatingLabelText="Username" value={@state.username} onChange={@handleUsernameChange} errorText={@state.usernameError}
              disabled={@state.loading} />
            <TextField
              key="password"
              style={width:"100%"}
              type="password"
              floatingLabelText="Password" value={@state.password} onChange={@handlePasswordChange} errorText={@state.passwordError}
              disabled={@state.loading} />
            <FlatButton style={width:"100%"} onClick={@handleLogin} secondary={true}>
              {if @state.loading then <FontIcon className="fa fa-spinner fa-pulse"/> else <span>Login</span>}
            </FlatButton>
          </div>
        </Tab>
        <Tab label="Signup" onActive={@goToRoute} route="signup">
          <div className="inner">
            <div className="error">{@state.globalError}</div>
            <TextField
              key="name"
              style={width:"100%"}
              hintText="John Appleseed"
              floatingLabelText="Name" valueLink={@linkState('name')}
              disabled={@state.loading} />
            <TextField
              key="username"
              style={width:"100%"}
              hintText="johnappleseed"
              floatingLabelText="Username" value={@state.username} onChange={@handleUsernameChange} errorText={@state.usernameError}
              disabled={@state.loading} />
            <TextField
              key="email"
              style={width:"100%"}
              hintText="example@instantchat.com"
              floatingLabelText="Email" value={@state.email} onChange={@handleEmailChange} errorText={@state.emailError}
              disabled={@state.loading} />
            <TextField
              key="password"
              style={width:"100%"}
              type="password"
              floatingLabelText="Password" value={@state.password} onChange={@handlePasswordChange} errorText={@state.passwordError}
              disabled={@state.loading} />
            <FlatButton style={width:"100%"} disabled={@state.loading} onClick={@handleSignup} secondary={true}>
              {if @state.loading then <FontIcon className="fa fa-spinner fa-pulse"/> else <span>Sign up</span>}
            </FlatButton>
          </div>
        </Tab> 
      </Tabs>
    </Paper>