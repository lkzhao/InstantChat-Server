React = require "react/addons"
Router = require "react-router"
auth = require "../util/Auth"
Link = Router.Link

Router = require "react-router"
Navigation = Router.Navigation

Header = require "./header"
SideBar = require "./sideBar"

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
FontIcon = mui.FontIcon
RaisedButton = mui.RaisedButton

module.exports = React.createClass
  mixins:[Navigation]
  componentWillMount: ->
    if !auth.loggedIn()
      @transitionTo "login"

  render: ->
    <div>
      <Header />
      <SideBar {...this.props}/>
    </div>