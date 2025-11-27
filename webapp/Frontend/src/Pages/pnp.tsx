import { Button } from '@/components/ui/button';
import React, { useEffect, useRef } from 'react';
import { Square } from 'lucide-react';
import { color_map, ShipType, getBlockColor } from './naval';


const get_ship_shape = (shipType: ShipType) => {
    switch (shipType) {
        case ShipType.SUBMARINE:
            return [{ x: 0, y: 0 }];
        case ShipType.AIRCRAFT_CARRIER:
            return [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }, { x: 0, y: 3 }, { x: 0, y: 4 }];
        case ShipType.BATTLESHIP:
            return [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }, { x: 0, y: 3 }];
        case ShipType.SEAPLANE:
            return [{ x: 0, y: 0 }, { x: 1, y: 1 }, { x: 0, y: 2 }];
        case ShipType.CRUISER:
            return [{ x: 0, y: 0 }, { x: 0, y: 1 }];
        default:
            return [];
    }
}

const get_block_value = (ship: ShipType, id: number) => {
    switch (ship) {
        case ShipType.SUBMARINE:
            return 1 + id;// 1-5
        case ShipType.AIRCRAFT_CARRIER:
            return 6;
        case ShipType.BATTLESHIP:
            return 7;
        case ShipType.SEAPLANE:
            return 8 + id; // 8-9
        case ShipType.CRUISER:
            return 10 + id;// 10-11
        default:
            return 0;
    }
}



const get_ship_type = (name: string): ShipType | null => {
    switch (name) {
        case 'Submarine':
            return ShipType.SUBMARINE;
        case 'Aircraft Carrier':
            return ShipType.AIRCRAFT_CARRIER;
        case 'Battleship':
            return ShipType.BATTLESHIP;
        case 'Seaplane':
            return ShipType.SEAPLANE;
        case 'Cruiser':
            return ShipType.CRUISER;
        default:
            return null;
    }
}



const applyRotation = (shape: Array<{ x: number; y: number }>, rotation: number) => {
    const newShape = shape.map((block) => ({ x: block.x, y: block.y }));
    switch (rotation) {
        case 0:
            return newShape;
        case 90:
            for (let block of newShape) {
                const tempX = block.x;
                block.x = -block.y;
                block.y = tempX;
            }
            return newShape;
        case 180:
            for (let block of newShape) {
                block.x = -block.x;
                block.y = -block.y;
            }
            return newShape;
        case 270:
            for (let block of newShape) {
                const tempX = block.x;
                block.x = block.y;
                block.y = -tempX;
            }
            return newShape;
    }
    return newShape;
}
const get_ship_type_from_block = (block: number): ShipType => {
    if (block >= 1 && block <= 5) {
        return ShipType.SUBMARINE;
    } else if (block === 6) {
        return ShipType.AIRCRAFT_CARRIER;
    } else if (block === 7) {
        return ShipType.BATTLESHIP;
    } else if (block >= 8 && block <= 9) {
        return ShipType.SEAPLANE;
    } else if (block >= 10 && block <= 11) {
        return ShipType.CRUISER;
    } else {
        return ShipType.UNKNOWN;
    }
}
const ships = Object.values(ShipType).filter(type => type !== ShipType.UNKNOWN);

const Homedos: React.FC = () => {
    const [map, setMap] = React.useState<number[]>(Array(64).fill(0));
    const [cursor, setCursor] = React.useState<{ x: number; y: number }>({ x: 0, y: 0 });
    const [rotation, setRotation] = React.useState<number>(0);
    const [currentShip, setCurrentShip] = React.useState<number | null>(null);
    const canvasRef = useRef<HTMLCanvasElement | null>(null);
    const ships_left = useRef<Map<ShipType, number>>(new Map<ShipType, number>([
        [ShipType.SUBMARINE, 5],
        [ShipType.AIRCRAFT_CARRIER, 1],
        [ShipType.BATTLESHIP, 1],
        [ShipType.SEAPLANE, 2],
        [ShipType.CRUISER, 2]
    ]
    ));
    const move = (delta: { x: number; y: number }) => {
        setCursor((prev) => {
            const newX = Math.min(7, Math.max(0, prev.x + delta.x));
            const newY = Math.min(7, Math.max(0, prev.y + delta.y));
            return { x: newX, y: newY };
        });
    };
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            console.log('Placing ship at cursor:', e.key);
            switch (e.key) {
                case 'ArrowUp':
                    move({ x: 0, y: -1 });
                    break;
                case 'ArrowDown':
                    move({ x: 0, y: 1 });
                    break;
                case 'ArrowLeft':
                    move({ x: -1, y: 0 });
                    break;
                case 'ArrowRight':
                    move({ x: 1, y: 0 });
                    break;
                case 'r':
                    setRotation((prevRotation) => (prevRotation + 90) % 360);
                    break;
                case '0':
                    setCurrentShip(null);
                    break;
                case '1':
                    setCurrentShip(1);
                    break;
                case '2':
                    setCurrentShip(2);
                    break;
                case '3':
                    setCurrentShip(3);
                    break;
                case '4':
                    setCurrentShip(4);
                    break;
                case '5':
                    setCurrentShip(5);
                    break;
                case '6':
                    setCurrentShip(6);
                    break;
                case 'd':
                    {
                        const placeX = cursor.x;
                        const placeY = cursor.y;
                        if (placeX >= 0 && placeX < 8 && placeY >= 0 && placeY < 8) {
                            const index = placeY * 8 + placeX;
                            const block = map[index];
                            if (block !== 0) {
                                const newMap = [...map];
                                for (let i = 0; i < newMap.length; i++) {
                                    if (newMap[i] === block) {
                                        newMap[i] = 0;
                                    }
                                }
                                setMap(newMap);
                                ships_left.current.set(get_ship_type_from_block(block), (ships_left.current.get(get_ship_type_from_block(block)) || 0) + 1);
                            }
                        }
                    }
                    break;  
                case 'Enter':
                    {
                        if (currentShip !== null) {
                            const shipType = ships[currentShip - 1];
                            const shipsLeft = ships_left.current.get(shipType) || 0;
                            const ship_id = shipsLeft - 1;

                            console.log('Placing ship id:', ship_id, 'of type:', ships[currentShip - 1]);
                            if (shipsLeft > 0) {

                                const shape = get_ship_shape(shipType);
                                const rotatedShape = applyRotation(shape, rotation);
                                let can_place = true;
                                let reason = '';
                                for (let block of rotatedShape) {
                                    const placeX = cursor.x + block.x;
                                    const placeY = cursor.y + block.y;
                                    if (placeX < 0 || placeX >= 8 || placeY < 0 || placeY >= 8) {
                                        can_place = false;
                                        reason = 'out of bounds {' + placeX + ',' + placeY + '}';
                                        break;
                                    }
                                    const current_block = map[placeY * 8 + placeX];
                                    console.log('Checking block at', placeX, placeY, 'value:', current_block, current_block !== 0 ? 'occupied' : 'empty');
                                    if (current_block !== 0) {
                                        can_place = false;
                                        reason = 'overlapping another ship at {' + placeX + ',' + placeY + '} : ship id ' + current_block;
                                        break;
                                    }
                                }
                                if (!can_place) {
                                    alert('Cannot place ship here!' + reason);
                                    return;
                                }
                                ships_left.current.set(shipType, shipsLeft - 1);
                                // check if ship can be placed
                                //skip for now
                                const newMap = [...map];
                                for (let block of rotatedShape) {
                                    const placeX = cursor.x + block.x;
                                    const placeY = cursor.y + block.y;
                                    if (placeX >= 0 && placeX < 8 && placeY >= 0 && placeY < 8) {
                                        const index = placeY * 8 + placeX;
                                        newMap[index] = get_block_value(shipType, ship_id);
                                    }
                                }
                                setMap(newMap);
                                if (shipsLeft - 1 <= 0) {
                                    setCurrentShip(null);
                                }
                            }
                            else {
                                console.log('No ships of this type left to place.', shipType);
                            }
                        }
                    }
                    break;
                default:
                    break;

            }
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => {
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, [map, cursor, rotation, currentShip]);

    useEffect(() => {
        const canvas = canvasRef.current;
        const ctx = canvas?.getContext('2d');
        // Example drawing: a red rectangle
        if (ctx) {
            ctx.clearRect(0, 0, canvas!.width, canvas!.height);
            ctx.fillStyle = 'white';
            ctx.fillRect(cursor.x * 50, cursor.y * 50, 50, 50);
            if (Array.isArray(map)) {
                for (let i = 0; i < map.length; i++) {
                    if (ctx) {
                        ctx.fillStyle = getBlockColor(map[i]);
                        ctx.fillRect((i % 8) * 50 + 2, Math.floor(i / 8) * 50 + 2, 46, 46);
                    }
                }
            }
            // draw current ship at cursor
            if (currentShip !== null) {
                const shipType = ships[currentShip - 1];
                const shape = get_ship_shape(shipType);
                const rotatedShape = applyRotation(shape, rotation);
                ctx.fillStyle = color_map.get(shipType) || 'blue';
                for (let block of rotatedShape) {
                    const drawX = cursor.x + block.x;
                    const drawY = cursor.y + block.y;
                    if (drawX >= 0 && drawX < 8 && drawY >= 0 && drawY < 8) {
                        ctx.fillRect(drawX * 50 + 2, drawY * 50 + 2, 46, 46);
                    }
                }
            }
        }
    }, [map, cursor, rotation, currentShip]); // Empty dependency array means this runs once on mount

    return (
        <div className='flex flex row w-full max-w-[1000px] gap-2'>

            <div className='flex flex-col '>
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
                    < canvas ref={canvasRef} width={400} height={400} />
                </div>
                <div className='mt-4 grid grid-cols-2'>
                    Legenda:
                    {Object.values(ShipType).map((type) => (
                        <div key={type} className='flex items-center mt-2'>
                            <Square className='inline-block mr-2' size={16} fill={color_map.get(type)} />
                            <span>{type}</span>
                        </div>
                    ))}
                    <div key={'miss'} className='flex items-center mt-2'>
                        <Square className='inline-block mr-2' size={16} fill='gray' />
                        <span>{'Fog of war'}</span>
                    </div>
                </div>
            </div>
            <div className='mt-4 flex flex-col'>
                <p>Use arrow keys to move the cursor.</p>
                <p>Press 'r' to rotate the ship.</p>
                {
                    ships.map((ship, index) => {
                        const ships_left_count = ships_left.current.get(get_ship_type(ship)!);
                        const bg_color = ships_left_count && ships_left_count > 0 ? (color_map.get(get_ship_type(ship)!) || 'blue') : 'gray';
                        return (
                            <Button key={ship} onClick={() => setCurrentShip(index + 1)} className='mr-2 mt-2'
                                style={{
                                    backgroundColor: bg_color,
                                    color: 'Black',
                                }}
                            >
                                {index + 1}: {ship} ({ships_left.current.get(get_ship_type(ship)!) || 0} left)
                            </Button>
                        )
                    })
                }
                <div>Rotation: {rotation}</div>
                <div>Current Ship: {currentShip !== null ? ships[currentShip - 1] : 'None'}</div>
                <Button className='mt-2' variant={'destructive'} onClick={() => {
                    if (confirm('Are you sure you want to clear the map?')) {
                        setMap(Array(64).fill(0));
                        ships_left.current = new Map<ShipType, number>([
                            [ShipType.SUBMARINE, 5],
                            [ShipType.AIRCRAFT_CARRIER, 1],
                            [ShipType.BATTLESHIP, 1],
                            [ShipType.SEAPLANE, 2],
                            [ShipType.CRUISER, 2]
                        ]);
                        setCurrentShip(null);
                    }
                }
                }>Clear All</Button>
                <Button className='mt-2 bg-[green] hover:bg-[darkgreen]' onClick={() => {
                    console.log('Final map:', map);
                    alert('Final map data logged to console.');
                }}>Finish Placement</Button>
            </div>
        </div>
    )
};

export default Homedos;