
React = require "react/addons"
Router = require "react-router"
Link = Router.Link

mui = require "material-ui"
TextField = mui.TextField

module.exports = React.createClass
  getInitialState: ->
    courses: []
    classrooms: []
    searchQuery: ""

  componentDidMount: ->
    return

  handleChange: (e)->
    @setState searchQuery:e.target.value.toUpperCase()

  render: ->
    generateRowFn = (room)=>
      roomName = room
      className = if room==@props.params.roomId then "selected room" else "room"
      if @state.searchQuery
        parts = room.split @state.searchQuery
        room = []
        for part in parts
          room.push <span>{part}</span>
          room.push <em>{@state.searchQuery}</em>
        room.pop()
      <Link className={className} to="room" params={roomId:roomName}>
        {room}
      </Link>
    filterFn = (room)=>
      !@state.searchQuery || room.toUpperCase().indexOf(@state.searchQuery) > -1
    matchedCourses = @state.courses.filter filterFn
    matchedClassrooms = @state.classrooms.filter filterFn
    courses = matchedCourses.slice(0,5).map generateRowFn
    classrooms = matchedClassrooms.slice(0,5).map generateRowFn
    roomList = []
    if courses.length
      roomList = [<div className="title">Courses</div>].concat courses
    if classrooms.length
      roomList = roomList.concat [<div className="title">Classrooms</div>].concat classrooms
    <div className="rightSideBar">
      <a href="/#/" className="brand"><em>UW</em>Chat</a>
      <TextField style={width:"100%"} className="search" floatingLabelText="Search" hintText="CS350" onChange={@handleChange}  value={@state.searchQuery} />
      {roomList}
    </div>