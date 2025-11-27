import { Button } from '@/components/ui/button';
import React, { useEffect, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
// import { BASE_URL } from '@/Providers/Urls.tsx';
import MyCanvas from '@/components/canvas';
const Home: React.FC = () => {
    const [state, setState] = React.useState<string>('');
    const [gamestate, setGamestate] = React.useState<any>(null);
    const [player, setPlayer] = React.useState<number>(0);
    const [imPlayer, setImPlayer] = React.useState<number>(-2);
    const imPlayerRef = useRef(imPlayer);
    useEffect(() => {
        imPlayerRef.current = imPlayer;
    }, [imPlayer]);
    const [otherPlayer, setOtherPlayer] = React.useState<Array<number>>([]);
    const socket = useRef<Socket>(io('http://localhost:3000', {
        autoConnect: false,
    }));

    const genMap = () => {
        const arr = [];
        // subsmarines 1-5 1 piece each
        for (let i = 0; i < 5; i++) {
            arr.push(i + 1);
        }
        // porta aviao 6 5 pieces
        for (let i = 0; i < 5; i++) {
            arr.push(6); // water
        }
        // encouraçado 7 4 pieces
        for (let i = 0; i < 4; i++) {
            arr.push(7);
        }
        // hidroavião 8-9 3 pieces each
        for (let i = 0; i < 3; i++) {
            arr.push(8);
            arr.push(9);
        }
        // cruzador 10-11 2 pieces each
        for (let i = 0; i < 2; i++) {
            arr.push(10);
            arr.push(11);
        }
        for (let i = arr.length; i < 64; i++) {
            arr.push(0); // water
        }
        // shuffle array
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
    }
    const [testData, _] = React.useState<Array<number>>(genMap());
    const connectWebSocket = () => {
        socket.current.connect();
        socket.current.on('connect', () => {
            console.log('WebSocket connected');
            setState('Connected');
        });
        socket.current.on('playerNum', (num: string) => {
            console.log('Assigned player number:', num);
            setImPlayer(parseInt(num));
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
            setImPlayer(-2);
            setState('Disconnected');
        });
        socket.current.on('set_player', (error) => {
            console.error('WebSocket connection error:', error);
            setState(`Connection Error: ${error.message}`);
        });
        socket.current.on('map', (data) => {
            console.log('Map update received:', data, data.player, imPlayerRef.current, data.player === imPlayerRef.current);
            alert(`Player ${data.player + 1} has updated their map!`);
            if (data.player !==   imPlayerRef.current) {
                setOtherPlayer(data.map);
            }
        });
    };

    const disconnectWebSocket = () => {
        if (socket.current.connected) {
            socket.current.disconnect();
        }
        socket.current.off('connect');
        socket.current.off('message');
        socket.current.off('disconnect');
        socket.current.off('set_player');
        socket.current.off('gamestate');
        socket.current.off('map');
    };

    useEffect(() => {
        return () => {
            disconnectWebSocket();
        };
    }, []);


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
                <Button onClick={() => {
                    if (socket.current.connected) {
                        socket.current.emit('map', {
                            player: imPlayer,
                            map: testData
                        });
                    }
                }}>
                    Send
                </Button>
            </div>
            {
                imPlayer !== -2 && (
                    <div><strong>You are player {imPlayer + 1}</strong></div>
                )
            }
            <div className='flex gap-8 mt-4'>
            <MyCanvas data={testData} position={{ x: 0, y: 0 }} />
            <MyCanvas data={otherPlayer} position={{ x: 0, y: 0 }} />
            </div>
            {

                // <div className='flex gap-8 mt-4'>
                //     <div className='p-4'>
                //         <div className='flex justify-between px-[50px]'>
                //             <h2>Player 1</h2>
                //             <h2>Score: {gamestate?.player1?.score || 0}</h2>
                //         </div>
                //         <div>
                //             {"#ABCDEFGH".split("").map((char) => (
                //                 <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                //                     {char}
                //                 </div>
                //             ))
                //             }
                //         </div>
                //         <div className='flex flex-row'>
                //             <div className='flex flex-col'>
                //                 {"01234567".split("").map((char) => (
                //                     <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                //                         {char}
                //                     </div>
                //                 ))
                //                 }
                //             </div>
                //             <MyCanvas data={testData} />
                //         </div>
                //     </div>
                //     {/* <div className='p-4'>
                //             <div className='flex justify-between px-[50px]'>
                //                 <h2>Player 2</h2>
                //                 <h2>Score: {gamestate.player2.score || 0}</h2>
                //             </div>
                //             <div>
                //                 {"#ABCDEFGH".split("").map((char) => (
                //                     <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                //                         {char}
                //                     </div>
                //                 ))
                //                 }
                //             </div>
                //             <div className='flex flex-row'>
                //                 <div className='flex flex-col'>
                //                     {"01234567".split("").map((char) => (
                //                         <div key={char} style={{ width: 50, height: 50, display: 'inline-block', textAlign: 'center', lineHeight: '50px', fontWeight: 'bold' }}>
                //                             {char}
                //                         </div>
                //                     ))
                //                     }
                //                 </div>
                //                 <MyCanvas data={gamestate ? gamestate.player2.map : []} position={
                //                     gamestate ? gamestate.player1.pos : { x: 0, y: 0 }
                //                 } />
                //             </div>
                //         </div> */}
                // </div>

            }
            {state}
        </div >
    );
};

export default Home;