function initScoreboard(){
  window.App = new Vue({
    el: '#scoreboard',
    data: {
      debug: null,
      loading: true,
      users: null
    },
    computed: {
      gameUrl: function() {
        return "http://" + location.hostname + ":" + location.port;
      }
    },
  });

  initializeSocket("scoreboard");

  App.onmessage = function(data) {
    App.loading = false;
    App.debug = JSON.stringify(data);

    if (data.users){
      App.users = data.users;
    }
  }
}

function initPlayer(){
  window.App = new Vue({
    el: '#app',
    data: {
      debug: null,
      loading: true,
      message: null,
      username: null
    },
    computed: {
      randomUsername: function() {
        return _.sample("Scrooge McDuck", "Abigail Adams", "The Yellow Dart");
      }
    },
    methods: {
      join: function(){
        App.socket.send(JSON.stringify({
          action: "JOIN",
          username: App.username
        }));
      }
    }
  });

  initializeSocket("player");
}

function initializeSocket(clientType){
  App.socket = new WebSocket("ws://"+location.host+"/socket");

  App.socket.onopen = function (event) {
      console.log("Connection established.");

      // Get initial screen information from the server
      this.send(JSON.stringify({action: "INIT", clientType: clientType}));
  };

  App.socket.onmessage = function (event) {
      console.log("Message received.");
      console.log(event);
      var json = JSON.parse(event.data);
      if (App.onmessage){
          App.onmessage(json);
      }
  };

  App.socket.onclose = function (event) {
      console.log("Connection lost.");
  };

  App.onmessage = function(data) {
    App.loading = false;
    App.debug = JSON.stringify(data);
  }
}
