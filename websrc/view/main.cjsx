React = require "react/addons"

Router = require "react-router"

DefaultRoute = Router.DefaultRoute
NotFoundRoute = Router.NotFoundRoute
Link = Router.Link
Route = Router.Route
RouteHandler = Router.RouteHandler
Navigation = Router.Navigation
Redirect = Router.Redirect

Room = require "./room"
Login = require "./login"
Dashboard = require "./dashboard"
SignupSuccess = require "./signupSuccess"

ThemeManager = require("material-ui/lib/styles/theme-manager")()
injectTapEventPlugin = require "react-tap-event-plugin"

Colors = require("material-ui/src/styles/colors")

injectTapEventPlugin()

App = React.createClass
  childContextTypes:
    muiTheme: React.PropTypes.object

  getChildContext: () ->
    muiTheme: ThemeManager.getCurrentTheme()

  componentWillMount: ->
    ThemeManager.setPalette
      primary1Color: Colors.green400,
      primary2Color: Colors.greenA400,
      primary3Color: Colors.greenA200,
      accent1Color: Colors.blueGrey700,
      accent2Color: Colors.blueGrey600,
      accent3Color: Colors.blueGrey800,
      textColor: Colors.blueGrey800,
      canvasColor: Colors.white,
      borderColor: Colors.grey300,
      disabledColor: Colors.grey400

  render: ->
    <div className="main">
      <RouteHandler {...this.props}/>
    </div>


NotFound = React.createClass
  render: ->
    <h1> 404 - Not Found </h1>

# routes =
#   <Route name="app" path="/" handler={App}>
#     <Route name="chat" path="chat/:roomId" handler={Room}/>
#     <DefaultRoute handler={Dashboard}/>
#     <Route name="login" path="login" handler={Login}/>
#     <Route name="signup" path="signup" handler={Login}/>
#     <Route name="signupSuccess" path="signupSuccess" handler={SignupSuccess} />
#     <NotFoundRoute handler={NotFound} />
#   </Route>

# Router.run routes, (Handler, state) ->
#   React.render <Handler {...state}/>, $("#main").get(0)
