var express = require('express'),
    async = require('async'),
    { Pool } = require('pg'),
    path = require('path'), // Added path for resolving index.html
    cookieParser = require('cookie-parser'),
    app = express(),
    server = require('http').Server(app),
    io = require('socket.io')(server);

var port = process.env.PORT || 80;

// Grab environment variables from Kubernetes
const pgUser = process.env.POSTGRES_USER || 'postgres';
const pgPass = process.env.POSTGRES_PASSWORD || 'postgres';
const pgHost = process.env.POSTGRES_HOST || 'db';
const pgPort = process.env.POSTGRES_PORT || '5432';

// Construct the connection string dynamically
const connectionString = `postgres://${pgUser}:${pgPass}@${pgHost}:${pgPort}/postgres`;

var pool = new Pool({
  connectionString: connectionString
});

let isReady = false;

// 1. Readiness Endpoint
app.get('/ready', (req, res) => {
  if (isReady) {
    res.status(200).send('Ready');
  } else {
    res.status(503).send('Not Ready');
  }
});

// 2. Liveness Endpoint
app.get('/live', (req, res) => {
  res.status(200).send('Alive');
});

async.retry(
  {times: 1000, interval: 1000},
  function(callback) {
    pool.connect(function(err, client, done) {
      if (err) {
        console.error("Waiting for db...");
      }
      callback(err, client);
    });
  },
  function(err, client) {
    if (err) {
      return console.error("Giving up");
    }
    console.log("Connected to db");
    isReady = true; // App is only "Ready" once the DB is actually connected
    getVotes(client);
  }
);

function getVotes(client) {
  client.query('SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote', [], function(err, result) {
    if (err) {
      console.error("Error performing query: " + err);
    } else {
      var votes = collectVotesFromResult(result);
      io.sockets.emit("scores", JSON.stringify(votes));
    }

    setTimeout(function() {getVotes(client) }, 1000);
  });
}

function collectVotesFromResult(result) {
  var votes = {a: 0, b: 0};

  result.rows.forEach(function (row) {
    votes[row.vote] = parseInt(row.count);
  });

  return votes;
}

app.use(cookieParser());
app.use(express.urlencoded());
app.use(express.static(__dirname + '/views'));

app.get('/', function (req, res) {
  res.sendFile(path.resolve(__dirname + '/views/index.html'));
});

server.listen(port, "0.0.0.0", function () {
  console.log('App running on port ' + port);
});
