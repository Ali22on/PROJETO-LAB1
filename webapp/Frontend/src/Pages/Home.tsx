import { Button } from '@/components/ui/button';
import React, { useRef } from 'react';
import { io, Socket } from 'socket.io-client';
// import { BASE_URL } from '@/Providers/Urls.tsx';
import MyCanvas from '@/components/canvas';
const Home: React.FC = () => {
    const [state, setState] = React.useState<string>('');
    const [gamestate, setGamestate] = React.useState<any>(null);
    const socket = useRef<Socket>(io('http://localhost:3000', {
        autoConnect: false,
    }));

    const connectWebSocket = () => {
        socket.current.connect();
        socket.current.on('connect', () => {
            console.log('WebSocket connected');
            setState('Connected');
        });
        socket.current.on('message', (event) => {
            console.log('WebSocket message received:', event.data);
            setState(`Message: ${event.data}`);
        });
        socket.current.on('gamestate', (data) => {
            console.log('Game State received:', data);
            setGamestate(data);
        });
        socket.current.on('disconnect', () => {
            console.log('WebSocket disconnected');
            setState('Disconnected');
        });
    };

    const disconnectWebSocket = () => {
        if (socket.current.connected) {
            socket.current.disconnect();
        }
    };

    return (
        <div className="w-[100vw] h-full flex flex-col items-center justify-center p-4">
            <div className='flex gap-4'>
                <Button
                    onClick={connectWebSocket}
                >
                    Connect
                </Button>
                <Button onClick={disconnectWebSocket}>
                    Disconnect
                </Button>
            </div>
            {
                gamestate && (
                    <div className='flex gap-8 mt-4'>
                        <div className='p-4'>
                            <div className='flex justify-between px-[50px]'>
                                <h2>Player 1</h2>
                                <h2>Score: {gamestate.player1.score || 0}</h2>
                            </div>
                            <div>
                                {"#ABCDEFGH".split("").map((char) => (
                                    <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                                        {char}
                                    </div>
                                ))
                                }
                            </div>
                            <div className='flex flex-row'>
                                <div className='flex flex-col'>
                                    {"01234567".split("").map((char) => (
                                        <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                                            {char}
                                        </div>
                                    ))
                                    }
                                </div>
                                <MyCanvas data={gamestate ? gamestate.player1.map : []} position={
                                    gamestate ? gamestate.player2.pos : { x: 0, y: 0 }
                                } />
                            </div>
                        </div>
                        <div className='p-4'>
                            <div className='flex justify-between px-[50px]'>
                                <h2>Player 2</h2>
                                <h2>Score: {gamestate.player2.score || 0}</h2>
                            </div>
                            <div>
                                {"#ABCDEFGH".split("").map((char) => (
                                    <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                                        {char}
                                    </div>
                                ))
                                }
                            </div>
                            <div className='flex flex-row'>
                                <div className='flex flex-col'>
                                    {"01234567".split("").map((char) => (
                                        <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                                            {char}
                                        </div>
                                    ))
                                    }
                                </div>
                                <MyCanvas data={gamestate ? gamestate.player2.map : []} position={
                                    gamestate ? gamestate.player1.pos : { x: 0, y: 0 }
                                } />
                            </div>
                        </div>
                    </div>
                )
            }
            {state}
        </div >
    );
};

export default Home;