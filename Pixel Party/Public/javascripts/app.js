var DEBUG = true;

function initScoreboard(){
  window.App = new Vue({
    el: '#scoreboard',
    data: {
      currentScreen: {
        screenType: "LOBBY"
      },
      debug: null,
      loading: true,
      metadata: {},
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
}

function initPlayer(){
  window.App = new Vue({
    el: '#app',
    data: {
      currentScreen: {
        screenType: "LOBBY",
        value: localStorage ? localStorage.getItem("username") : null
      },
      debug: null,
      disabled: false,
      loading: true,
      metadata: {},
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
        if (!App.currentScreen.value){
          return;
        }

        App.disabled = true;
        App.socket.send(JSON.stringify({
          action: "JOIN",
          username: App.currentScreen.value
        }));
      },
      start_game: function(){
        App.disabled = true;
        App.socket.send(JSON.stringify({
          action: "START_GAME"
        }));
      },
      submit: function(){
        App.disabled = true;
        App.socket.send(JSON.stringify({
          action: "SUBMIT",
          value: App.currentScreen.value
        }));
      },
      submitChoice: function(choice){
        App.disabled = true;
        App.currentScreen.value = choice.value;
        App.submit();
      }
    }
  });

  initializeSocket("player");

  App.onmessage = function(data) {
    if (localStorage && data.metadata.currentPlayer){
      localStorage.setItem("username", data.metadata.currentPlayer.username)
    }
    if (data.joined){
      App.joined = data.joined;
    }
  }
}

function initializeSocket(clientType){
  App.socket = new WebSocket("ws://"+location.host+"/socket");

  App.socket.onopen = function (event) {
      console.log("Connection established.");
      App.loading = false;

      // Get initial screen information from the server
      this.send(JSON.stringify({action: "INIT", clientType: clientType}));
  };

  App.socket.onmessage = function (event) {
      console.log("Message received.");
      console.log(event);
      var json = JSON.parse(event.data);

      if (DEBUG){
        App.debug = event.data;
      }

      if (json.currentScreen){
        App.disabled = false;
        App.currentScreen = json.currentScreen;
      }

      if (json.metadata){
        App.metadata = json.metadata;
      }

      if (App.onmessage){
          App.onmessage(json);
      }
  };

  App.socket.onclose = function (event) {
      console.log("Connection lost.");
      alert("Connection lost. Please try connecting again!")
      location.reload();
  };
}
