
const express = require('express');
const { Server } = require('socket.io');
const { GameState } = require('./gamelogic');
const { setOnFrameReceived,
    startSerial,
    sendFrame,
    listPorts } = require('./serialManager.js');

const gameState = new GameState();

const app = express();
app.use(express.static('./Frontend/dist'));

const server = app.listen(3000, () => {
    console.log('Server is listening on port 3000');
});

const io = new Server(server, {
    cors: {
        origin: 'http://localhost:5173',
    }
});

const port = 3000;

const sendMapUpdate = (mapData) => {
   const frame = mapData;
   frame.push(0); // p1 score
   frame.push(0); // p1 cursor
   //replicate for p2
   for (let i = 0; i < 66; i++) {
       frame.push(frame[i]); 
   }
    sendFrame(frame);
}

io.on('connection', (socket) => {
    const slot = gameState.playerJoin(socket.id);
    console.log('New client connected:', socket.id, 'assigned to slot', slot);
    socket.emit('playerNum', `${slot}`);
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
        gameState.playerLeave(socket.id);
        console.log('Slot freed for client:', socket.id);
    });
    socket.on('map', (data) => {
        console.log(`Received map data from player ${data.player}`);
        io.emit('map', data);
        sendMapUpdate(data.map);
    });
});
// startSerial();
setOnFrameReceived((frame, game) => {
    io.emit('map', { player: 2, map: game.player2.map });
    console.log('sending player 2 map via socket.io', game.player2.map.length);
});