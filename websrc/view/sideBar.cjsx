
React = require "react/addons"
Router = require "react-router"
Link = Router.Link

mui = require "material-ui"
TextField = mui.TextField
FlatButton = mui.FlatButton
FontIcon = mui.FontIcon
auth = require "../util/Auth"
RequireProfile = require "../util/requireProfile"

module.exports = React.createClass
  mixins:[RequireProfile]
  getInitialState: ->
    searchQuery: ""

  componentDidMount: ->
    return

  handleChange: (e)->
    @setState searchQuery:e.target.value.toUpperCase()


  render: ->
    generateRowFn = (user)=>
      username = user.username
      displayName = user.username
      className = if username==@props.params.roomId then "selected conversation" else "conversation"
      if @state.searchQuery
        parts = displayName.split "(?i)#{@state.searchQuery}"
        displayName = []
        count = 0
        console.log parts
        for part in parts
          displayName.push <span key={"search#{count}"}>{part}</span>
          displayName.push <em key={"search#{count+1}"}>{@state.searchQuery}</em>
          count = count + 2
        displayName.pop()
      <Link key={"contact-#{username}"} to="chat" className={className} params={roomId:username}>
        <img src={user.image}/>
          {displayName}
      </Link>

    filterFn = (user)=>
      !@state.searchQuery || user.username.toUpperCase().indexOf(@state.searchQuery) > -1
    matchedUsers = (@state.profile.contacts || []).filter filterFn
    userViews = matchedUsers.slice(0,5).map generateRowFn
    <div className="sideBar">
      <header>
        <TextField key="searchContact" style={width:"100%"} className="search" floatingLabelText="Search" hintText="CS350" onChange={@handleChange}  value={@state.searchQuery} />
      </header>
      {if !@state.searchQuery then <Link to="app" className={if !@props.params.roomId then "selected conversation" else "conversation"}>
        <FontIcon className="fa fa-home"/>
        Nearby
      </Link>}
      <div key="contacts">
        {userViews}
      </div>
      <div key="people">
      </div>
    </div>