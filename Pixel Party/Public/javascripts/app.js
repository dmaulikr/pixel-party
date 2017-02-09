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
      metadata: {}
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
      resizeImage(url, maxWidth, maxHeight, callback) {
        var sourceImage = new Image();

        sourceImage.onload = function() {
          // Create a canvas with the desired dimensions
          var canvas = document.createElement("canvas");
          var scaling = Math.min(maxWidth / sourceImage.width, maxHeight / sourceImage.width);
          canvas.width = Math.round(sourceImage.width * scaling);
          canvas.height = Math.round(sourceImage.height * scaling);

          // Scale and draw the source image to the canvas
          canvas.getContext("2d").drawImage(sourceImage, 0, 0, canvas.width, canvas.height);

          // Convert the canvas to a data URL in PNG format
          callback(canvas.toDataURL());
        }

        sourceImage.src = url;
      },
      submit: function(){
        if (App.disabled){
          return;
        }

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
      },
      submitPicture: function(e){
        // based on http://codepen.io/Atinux/pen/qOvawK/
        var files = document.getElementById('picturePicker').files;
        if (!files.length)
          return;

        // Read the file as a data URL, then submit to the server
        var fileReader = new FileReader();
        var that = this;
        fileReader.onload = function(e){
          // resize the image to a maximum size
          App.resizeImage(e.target.result, 200, 200, function(dataUrl){
            App.currentScreen.value = dataUrl;
            App.submit();
          })
        };
        fileReader.readAsDataURL(files[0]);
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
