const { SerialPort } = require('serialport');
const express = require('express');
const { Server } = require('socket.io');

const listPorts = async () => {
    try {
        const ports = await SerialPort.list();
        if (!ports.length) {
            console.log('No serial ports found.');
            return;
        }
        ports.forEach(p => {
            console.log(`Path: ${p.path}`);
            if (p.manufacturer) console.log(`  Manufacturer: ${p.manufacturer}`);
            if (p.serialNumber) console.log(`  Serial Number: ${p.serialNumber}`);
            if (p.pnpId) console.log(`  PnP ID: ${p.pnpId}`);
            if (p.locationId) console.log(`  Location ID: ${p.locationId}`);
            if (p.vendorId) console.log(`  Vendor ID: ${p.vendorId}`);
            if (p.productId) console.log(`  Product ID: ${p.productId}`);
        });
    } catch (err) {
        console.error('Failed to list ports:', err);
    }
};

const sp = new SerialPort({ path: 'COM14', baudRate: 115200 });
sp.on('open', () => {
    console.log('Serial Port Opened', sp.path, sp.baudRate);
});
GAMESTATE = [];
game_index = 0;
let t = null;
const game = {
    player1: {
        pos: { x: 0, y: 0 },
        score: 0,
        map: []
    },
    player2: {
        pos: { x: 0, y: 0 },
        score: 0,
        map: []
    }
};

const parseGameState = () => {
    let index = 0;
    game.player1.map = [];
    game.player2.map = [];
    for (let i = 0; i < 64; i++) {
        game.player1.map[i] = GAMESTATE[index];
        index++;
    }
    for (let i = 0; i < 64; i++) {
        game.player2.map[i] = GAMESTATE[index];
        index++;
    }
    game.player1.score = GAMESTATE[index];
    index++;
    game.player2.score = GAMESTATE[index];
    index++;
    const p1pos = GAMESTATE[index];
    game.player1.pos = {
        x: (p1pos >> 4) & 0x0F,
        y: p1pos & 0x0F
    };
    index++;
    const p2pos = GAMESTATE[index];
    game.player2.pos = {
        x: (p2pos >> 4) & 0x0F,
        y: p2pos & 0x0F
    };
}

const printGS = () => {
    for (let i = 0; i < GAMESTATE.length; i++) {
        const char = GAMESTATE[i];
        process.stdout.write(String.fromCharCode(char));
    }
}
sp.on('data', (data) => {
    for (let i = 0; i < data.length; i++) {
        GAMESTATE[game_index] = data[i];
        game_index++;
        if (game_index >= 132) {
            game_index = 0;
            parseGameState();
            console.log(game);
            io.emit('gamestate', game);
            //printGS();
        }
    };
});

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

io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});
