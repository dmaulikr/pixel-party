var DEBUG = false;

function initScoreboard(){
  window.App = new Vue({
    el: '#scoreboard',
    data: {
      debug: null,
      loading: true,
      users: null,
      colors: ["#140b1c",
               "#452334",
               "#2f346c",
               "#844a32",
               "#366226",
               "#5d7ac9",
               "#d14644",
               "#87949d",
               "#6da72c",
               "#d5a79d",
               "#6ec3ca",
               "#d6d560",
               "#deeed1",
               "#4f4b4d",
               "#736f5c",
               "#d57a25"]
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

    if (DEBUG){
      App.debug = JSON.stringify(data);
    }

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
        return _.sample([
          "Scrooge McDuck",
          "Abigail Adams",
          "The Yellow Dart",
          "Bon Jittner",
          "Ramona Flowers",
          "Stevonnie",
          "Mr. Cool"
        ]);
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

    if (DEBUG){
      App.debug = JSON.stringify(data);
    }
  }
}
