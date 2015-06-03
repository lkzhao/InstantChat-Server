
React = require "react/addons"
auth = require "./Auth"

RequireLogin =
  contextTypes:
    router: React.PropTypes.func.isRequired

  componentWillMount: ->
    if !auth.loggedIn()
      @context.router.transitionTo "login"


module.exports = RequireLogin