
mui = require "material-ui"
AppBar =  mui.AppBar
RaisedButton = mui.RaisedButton
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
      <DialogWindow
        ref="dialogWindow"
        title={name}
        contentClassName="profileDialog"
        actions={standardActions}
        actionFocus="logout"
        modal={true}>
        <div className="dialogHeader">
        </div>
        <img src={@state.profile.image}/>
        <div className="name">{name}</div>
        <div className="dialogContent">
          <Menu menuItems={filterMenuItems} autoWidth={false}/>
        </div>
        
      </DialogWindow>
    </header>