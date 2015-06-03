
React = require "react/addons"
auth = require "./Auth"

RequireProfile =
  getInitialState: ->
    profile: {}

  componentDidMount: ->
    auth.on 'profileChange', @handleProfileChange
    @handleProfileChange()

  componentWillUnmount: ->
    auth.off 'profileChange', @handleProfileChange

  handleProfileChange: ->
    @setState profile: auth.profile


module.exports = RequireProfile