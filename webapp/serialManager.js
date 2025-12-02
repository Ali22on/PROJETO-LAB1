const { SerialPort } = require('serialport');
const PORT = 'COM3';
const BAUD_RATE = 115200;
const listPorts = async () => {
    try {
        const ports = await SerialPort.list();
        if (!ports.length) {
            console.log('No serial ports found.');
            return [];
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
        return ports;
    } catch (err) {
        console.error('Failed to list ports:', err);
        return [];
    }
};



GAMESTATE = [];
game_index = 0;

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

let onFrameReceived = null;

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

const setOnFrameReceived = (callback) => {
    onFrameReceived = callback;
};

let sp = null;
let gi = 0;
let preambleDetected = 0;
const startSerial = (port, baudRate) => {
    port = port || PORT;
    baudRate = baudRate || BAUD_RATE;
    sp = new SerialPort({ path: port, baudRate: baudRate, stopBits: 1, parity: 'none', dataBits: 8 });
    sp.on('open', () => {
        console.log('Serial Port Opened', sp.path, sp.baudRate);
    });
    sp.on('data', (data) => {
        
        for (let i = 0; i < data.length; i++) {
            if (data[i] === 0xFF) {
                preambleDetected ++;
                continue;
            }
            if (preambleDetected == 2) {
                preambleDetected = 0;
                gi = 0;
                game_index = 0;
                console.log('Preamble detected');
                continue;
            } 
            console.log(gi++, data[i], String.fromCharCode(data[i]));
            GAMESTATE[game_index] = data[i];
            game_index++;
            if (game_index >= 132) {
                game_index = 0;
                parseGameState();
                if (onFrameReceived) {
                    onFrameReceived(Array.from(GAMESTATE), game);
                }

            }
        };
    });
    sp.on('error', (err) => {
        console.log('Error: ', err.message);
    });
    sp.on('close', () => {
        console.log('Serial Port Closed');
    });
}

const sendFrame = (frameData) => {
    if (Array.isArray(frameData) === false) {
        console.log('Frame data must be an array of bytes.');
        return;
    }
    if (frameData.length !== 132) {
        console.log('Frame data must be 132 bytes long.');
        return;
    }

    if (sp && sp.isOpen) {
        sp.write(Buffer.from(frameData), (err) => {
            if (err) {
                return console.log('Error on write: ', err.message);
            }
        });
    }
};
// listPorts().then((data) => {
//     console.log(`Found ${data.length} ports.`, data.map(p => p.path).join(', '));
    
// });
startSerial(PORT, BAUD_RATE);
module.exports = {
    setOnFrameReceived,
    startSerial,
    sendFrame,
    listPorts
};