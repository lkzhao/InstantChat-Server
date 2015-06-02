
mui = require "material-ui"
AppBar =  mui.AppBar

auth = require "../util/Auth"

React = require "react/addons"
module.exports = React.createClass
  getInitialState: ->
    profile:{}

  componentDidMount: ->
    $.get("/user/profile/#{auth.username}?token=#{auth.token}")
      .done( (data)=>
        @setState 
          profile: data
      ).fail( =>
      )
  render: ->
    <header className="header">
      <div className="profile">
        {@state.profile.name || @state.profile.username}
        <img src={@state.profile.image}/>
      </div>
    </header>