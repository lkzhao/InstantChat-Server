React = require "react/addons"
Router = require "react-router"
Link = Router.Link

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
FontIcon = mui.FontIcon
RaisedButton = mui.RaisedButton

module.exports = React.createClass
  render: ->
    <Paper className="center" zDepth={5}>
      <div>Landing Page</div>
      <div>Nothing here yet</div>
      <RaisedButton linkButton={true} href="/#/room/lobby" primary={true} label="Chat Room Page">
      </RaisedButton>
      <RaisedButton linkButton={true} href="/#/login" secondary={true} label="Login Page">
      </RaisedButton>
    </Paper>