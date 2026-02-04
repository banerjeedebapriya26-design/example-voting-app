const express = require('express');
const async = require('async');
const { Pool } = require('pg');
const path = require('path');
const cookieParser = require('cookie-parser');
const app = express();
const server = require('http').Server(app);
const io = require('socket.io')(server);

const port = process.env.PORT || 80;

// 1. Database Configuration from Environment Variables
const pgUser = process.env.POSTGRES_USER || 'postgres';
const pgPass = process.env.POSTGRES_PASSWORD || 'postgres';
const pgHost = process.env.POSTGRES_HOST || 'db';
const pgPort = process.env.POSTGRES_PORT || '5432';

const connectionString = `postgres://${pgUser}:${pgPass}@${pgHost}:${pgPort}/postgres`;

const pool = new Pool({
  connectionString: connectionString,
  max: 10,                 // Maximum number of clients in the pool
  idleTimeoutMillis: 30000 // Close idle clients after 30 seconds
});

let isReady = false;

// 2. Health Check Endpoints
app.get('/ready', (req, res) => {
  if (isReady) {
    res.status(200).send('Ready');
  } else {
    res.status(503).send('Not Ready');
  }
});

app.get('/live', (req, res) => {
  res.status(200).send('Alive');
});

// 3. Database Connection Logic with Retry
async.retry(
  { times: 1000, interval: 1000 },
  function(callback) {
    pool.connect(function(err, client, done) {
      if (err) {
        console.error("Waiting for db...");
      }
      callback(err, client, done);
    });
  },
  function(err, client, done) {
    if (err) {
      return console.error("Giving up on database connection");
    }
    
    // Release the initial test client back to the pool
    if (done) done();
    
    console.log("Connected to db");
    isReady = true; 
    getVotes(pool);
  }
);

// 4. Data Fetching Logic (Using Connection Pool)
function getVotes(pool) {
  pool.connect(function(err, client, done) {
    if (err) {
      console.error("Error acquiring client from pool: " + err);
      setTimeout(() => getVotes(pool), 2000);
      return;
    }

    client.query('SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote', [], function(err, result) {
      // RELEASE CLIENT back to the pool immediately after query
      done();

      if (err) {
        console.error("Error performing query: " + err);
      } else {
        const votes = collectVotesFromResult(result);
        io.sockets.emit("scores", JSON.stringify(votes));
      }

      // Schedule next update
      setTimeout(() => getVotes(pool), 1000);
    });
  });
}

function collectVotesFromResult(result) {
  const votes = { a: 0, b: 0 };
  result.rows.forEach(function (row) {
    votes[row.vote] = parseInt(row.count);
  });
  return votes;
}

// 5. Socket.io Logic
io.on('connection', function (socket) {
  socket.emit('message', { text: 'Welcome!' });
  socket.on('subscribe', function (data) {
    socket.join(data.channel);
  });
});

// 6. Express Middleware and Routing
app.use(cookieParser());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'views')));

app.get('/', function (req, res) {
  res.sendFile(path.resolve(__dirname, 'views', 'index.html'));
});

// 7. Start Server
server.listen(port, "0.0.0.0", function () {
  console.log('App running on port ' + port);
});
