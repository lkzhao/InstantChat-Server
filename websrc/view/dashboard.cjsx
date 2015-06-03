React = require "react/addons"
Router = require "react-router"
auth = require "../util/Auth"
Link = Router.Link

Router = require "react-router"
RequireAuth = require "../util/requireLogin"

Header = require "./header"
SideBar = require "./sideBar"

mui = require "material-ui"
Colors = require 'material-ui/src/styles/colors'
TextField = mui.TextField
Paper = mui.Paper
FontIcon = mui.FontIcon
RaisedButton = mui.RaisedButton

module.exports = React.createClass
  mixins:[RequireAuth]

  render: ->
    <div>
      <Header />
      <SideBar {...this.props}/>
    </div>