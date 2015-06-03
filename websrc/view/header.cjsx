
mui = require "material-ui"
AppBar =  mui.AppBar
RaisedButton = mui.RaisedButton
FlatButton = mui.FlatButton
Paper = mui.Paper
DialogWindow = mui.DialogWindow
Menu = mui.Menu


Router = require "react-router"
Navigation = Router.Navigation

auth = require "../util/Auth"

React = require "react/addons"

module.exports = React.createClass
  mixins:[Navigation]
  getInitialState: ->
    profile:{}

  componentDidMount: ->
    $.get("/user/profile/#{auth.username}?token=#{auth.token}")
      .done( (data)=>
        @setState 
          profile: data
      ).fail( =>
      )
  handleUpload: ->
    data = new FormData()
    imageFile = $('#imageUpload')[0].files[0]
    if !imageFile
      return
    data.append "image", imageFile
    $.ajax(
      url: "/user/upload?token=#{auth.token}",
      data: data,
      cache: false,
      contentType: false,
      processData: false,
      type: 'POST'
    ).done( (data) =>
      @componentDidMount()
    ).fail( ->

    )
  handleImageClick: ->
    $("#imageUpload").click()

  handleProfileOpen: ->
    @refs.dialogWindow.show()

  handleLogout: ->
    @refs.dialogWindow.dismiss()
    auth.logout()
    @transitionTo "login"

  handleCancel: ->
    @refs.dialogWindow.dismiss()

  render: ->
    name = @state.profile.name || @state.profile.username
    standardActions = [
      { text: 'Cancel', onClick: @handleCancel, ref: 'cancel' }
      { text: 'Logout', onClick: @handleLogout, ref: 'logout' }
    ]
    filterMenuItems = [
       { payload: '1', text: 'Name', data: @state.profile.name}
       { payload: '2', text: 'InstantChat Username', data: @state.profile.username}
       { payload: '3', text: 'Gender', data: 'Male' }
       { payload: '4', text: 'Allow to Receive Messages From Unknown People', toggle: true, disabled: true}
    ]

    <header className="header">
      <div className="profile" onClick={@handleProfileOpen}>
        <img src={@state.profile.image}/>
      </div>
      <input type="file" id="imageUpload"  style={display:"none"} onChange={@handleUpload}/>
      <DialogWindow
        ref="dialogWindow"
        title={name}
        contentClassName="profileDialog"
        actions={standardActions}
        actionFocus="logout"
        modal={true}>
        <div className="dialogHeader">
        </div>
        <div className="profileImage">
          <img src={@state.profile.image} />
          <div id="editImageButton">
            <FlatButton style={width:"100%"} label="Edit" primary={true} onClick={@handleImageClick}/>
          </div>
        </div>
        <div className="name">{name}</div>
        <div className="dialogContent">
          <Menu menuItems={filterMenuItems} autoWidth={false}/>
        </div>
        
      </DialogWindow>
    </header>