





// var TodoList = React.createClass({
//   render: function() {
//     var createItem = function(item) {
//       return <li key={item.id}>{item.text}</li>;
//     };
//     return <ul>{this.props.items.map(createItem)}</ul>;
//   }
// });
// var TodoApp = React.createClass({
//   getInitialState: function() {
//     return {items: [], text: ''};
//   },
//   onChange: function(e) {
//     this.setState({text: e.target.value});
//   },
//   handleSubmit: function(e) {
//     e.preventDefault();
//     var nextItems = this.state.items.concat([{text: this.state.text, id: Date.now()}]);
//     var nextText = '';
//     this.setState({items: nextItems, text: nextText});
//   },
//   render: function() {
//     return (
//       <div>
//         <h3>TODO</h3>
//         <TodoList items={this.state.items} />
//         <form onSubmit={this.handleSubmit}>
//           <input onChange={this.onChange} value={this.state.text} />
//           <button>{'Add #' + (this.state.items.length + 1)}</button>
//         </form>
//       </div>
//     );
//   }
// });

// ReactDOM.render(<TodoApp />, document.getElementById('container'));




Lobby = React.createClass({
  getInitialState: function() {
    return {username: null};
  },
  onChange: function(e) {
    this.setState({username: e.target.value});
  },
  submitUsername: function(e) {
    e.preventDefault();

    if (this.state.username){
      Store.dispatch({type: "MAKE_REQUEST", payload: {action: "JOIN", username: this.state.username}});
    }
  },
  start: function(e) {
    e.preventDefault();
    Store.dispatch({type: "MAKE_REQUEST", payload: {action: "START_GAME"}});
  },
  render: function() {
    var store = this.context.store.getState();

    if (!store.username){
      return (
        <section id="lobby">
          <h3>Enter your name to join:</h3>
          <form onSubmit={this.submitUsername}>
            <input type="text" onChange={this.onChange} value={this.state.username} />
            <button>Join</button>
          </form>
        </section>
      );
    }

    return (
      <section id="lobby">
        <h3>Waiting for others to join...</h3>
        <form onSubmit={this.start}>
          <button>Start</button>
        </form>
      </section>
    );
  }
});
Lobby.contextTypes = {
  store: React.PropTypes.object
}



Header = React.createClass({
  render: function() {
    var store = this.context.store.getState();

    var usernameContent;
    if (store.username){
      usernameContent = <h2>Username: {store.username}</h2>;
    }

    return (
      <section id="header">
        <h1>Pixel Party!</h1>
        {usernameContent}
      </section>
    );
  }
});
Header.contextTypes = {
  store: React.PropTypes.object
}




window.App = React.createClass({
  componentDidMount: function() {
    document.title = this.context.store.getState().title;
  },
  render: function() {
    var store = this.context.store.getState();

    // If we're not connected yet, show a waiting screen
    if (!store.socket || store.currentScreen == {}){
      return (
        <section id="connecting">
          Connecting...
        </section>
      );
    }

    if (store.currentScreen.screenType == "LOBBY"){
      return (
        <div>
          <Header />
          <Lobby />
        </div>
      );
    }

    if (store.currentScreen.screenType == "STATIC"){
      return (
        <div>
          <Header />
          <section dangerouslySetInnerHTML={{__html: store.currentScreen.content}} />
        </div>
      );
    }

    return (
      <div>
        Unknown screen :(
      </div>
    );
  }
});
App.contextTypes = {
  store: React.PropTypes.object
}




/*

App states
  
- app launches
- app connects to server
- user submits username to server
  - server returns error if name is already taken
  - else, server returns success and client claims this username
- game has not started yet

in general, server tells client what screen to display via currentScreen

{
  screenType: "LOBBY", "STATIC", "TEXT", "DRAWING", "MULTIPLE_CHOICE", "CONFIRM"
  header:
  imageUrl:
  timer:
  choices:
}

*/



// Redux: manage state
window.Store = Redux.createStore(function(state, action){
  if (typeof state === 'undefined') {
    // initial state
    return {
      title: "Pixel Party!",
      socket: null,
      username: null,
      waitingForResponse: false,
      currentScreen: {}
    };
  }

  switch (action.type) {
    case 'SET_SOCKET':
      var updatedState = _.assign({}, state, {socket: action.socket});
      if (!action.socket){
        updatedState.username = null;
        waitingForResponse = false;
        currentScreen = {};
      }
      return updatedState;
    case 'MAKE_REQUEST':
      state.socket.send(JSON.stringify(action.payload));
      return _.assign({}, state, {waitingForResponse: true});
    case 'SERVER_UPDATE':
      return _.assign({}, state, action.data, {waitingForResponse: false});
    default:
      return state;
  }
}, Redux.applyMiddleware(window.ReduxThunk.default));







// Find and keep a connection
SocketManager = {
  init: function(){
    this.connect();
    setInterval(this.connect, 1000);
  },

  connect: function(){
    if (Store.getState().socket){
      // We're already connected, so let's just return
      return;
    }

    var socket = new WebSocket("ws://"+location.host+"/socket");

    socket.onopen = function (event) {
      Store.dispatch({type: "SET_SOCKET", socket: socket});
      console.log("Connection established.");

      // Get initial screen information from the server
      this.send(JSON.stringify({action: "INIT"}));
    };

    socket.onmessage = function (event) {
      console.log(event);
      var json = JSON.parse(event.data);
      Store.dispatch({type: "SERVER_UPDATE", data: json});
    };

    socket.onclose = function (event) {
      if (!Store.getState().socket){
        // We were already disconnected, this isn't new
        return;
      }

      Store.dispatch({type: "SET_SOCKET", socket: null});
      console.log("Connection lost.");
    };
  }
}


var Provider = ReactRedux.Provider;

// Start rendering the app with React + Redux, and start the WebSocket connection
var render = function(){
  ReactDOM.render(
    <Provider store={Store}>
      <App />
    </Provider>,
    document.getElementById('container')
  )
}
Store.subscribe(render);
SocketManager.init();






















/*


var App = {
  socket: null,
  username: null,

  // Establish a connection to the server
  init: function() {
    if (App.socket) {
      return;
    }

    var newSocket = new WebSocket("ws://"+location.host+"/socket");
    newSocket.onopen = function (event) {
      App.socket = newSocket;
      App.socket.onmessage = App.onmessage;
      console.log("Connection established.");
    }
    newSocket.onclose = function (event) {
      App.socket = null;
      console.log("Connection lost.");
    }
  },

  // Submit the user's username
  join: function(name) {
    App.username = name;
    App.socket.send(JSON.stringify({action: "join", name: App.username}));
  },

  // Send a text message to the server
  // TODO

  // Handle incoming messages from the server
  onmessage: function(event) {
    var json = event.data
    if (json.action == "join" && json.success){
      console.log("Joined as "+App.username);
    }

    console.log(event.data);
  },

  onerror: function(event) {
    alert("An error occurred: "+event.data);
  },
}


$(document).ready(function() {
  App.init();

  // If we lose our connection, try to reconnect every 3 seconds
  setInterval(App.init, 3000);
})


*/
