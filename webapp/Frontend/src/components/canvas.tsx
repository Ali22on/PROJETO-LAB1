import React, { useRef, useEffect } from 'react';
import { color_map, getBlockColor, ShipType } from '@/Pages/naval';
import { Square } from 'lucide-react';
const MyCanvas: React.FC<{ data: number[]; position: { x: number; y: number }; fogOfWar?: boolean }> = ({ data, position, fogOfWar }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [positionState, _setPositionState] = React.useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const posState = useRef(positionState);
  const isShipDead = useRef(new Map<number, boolean>());
  const setNewPos = (delta: { x: number; y: number }) => {
    delta = { x: delta.x * 50, y: delta.y * 50 };
    const newPos = { x: posState.current.x + delta.x, y: posState.current.y + delta.y };
    if (newPos.x >= 0 && newPos.x <= 350 && newPos.y >= 0 && newPos.y <= 350) {
      _setPositionState(newPos);
      posState.current = newPos;
      console.log(newPos);
    }
  };
  useEffect(() => {
    _setPositionState({
      x: position.x * 50,
      y: position.y * 50,
    });
  }, [position]);

  console.log('Rendering canvas at position:', positionState);
  useEffect(() => {
    const shipStatus = new Map<number, number>();
    for (let i = 1; i < 12; i++) {
      if (i > 0 && i < 6) // submarines
      {
        shipStatus.set(i, 1);
      }
      else if (i === 6) // aircraft carrier
        shipStatus.set(i, 5);
      else if (i === 7) // battleship
        shipStatus.set(i, 4);
      else if (i === 8 || i === 9) // seaplanes
        shipStatus.set(i, 3);
      else if (i === 10 || i === 11) // cruisers
        shipStatus.set(i, 2);
    }

    for (let i = 0; i < 64; i++) {
      const shipId = data[i] & 0xF;
      const isHit = (data[i] & 0x80) === 0;
      const prevCount = shipStatus.get(shipId) || 0;
      if (shipId !== 0 && isHit && prevCount > 0) {
        shipStatus.set(shipId, prevCount - 1);
      }
    }

    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    // Example drawing: a red rectangle
    if (ctx) {
      ctx.clearRect(0, 0, canvas!.width, canvas!.height);
      ctx.fillStyle = 'white';
      ctx.fillRect(positionState.x , positionState.y , 50, 50);
      if (Array.isArray(data)) {
        for (let i = 0; i < data.length; i++) {
          if (ctx) {
            if ((data[i] & 0x80) == 0 && (data[i] & 0x1F) != 0) {
              // Ship hit
              ctx.fillStyle = 'red';
              if (shipStatus.get(data[i] & 0x1F) === 0) {
                // Ship is dead
                ctx.fillStyle = getBlockColor(data[i], fogOfWar);
              }
            }
            else
              ctx.fillStyle = getBlockColor(data[i], fogOfWar);
            ctx.fillRect((i % 8) * 50 + 2, Math.floor(i / 8) * 50 + 2, 46, 46);
          }
        }

      }
    }
  }, [data, positionState]); // Empty dependency array means this runs once on mount
  
  return (
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
          <Square className='inline-block mr-2' size={16} fill='red' />
          <span>{'Ship Hit'}</span>
        </div>
        <div key={'fow'} className='flex items-center mt-2'>
          <Square className='inline-block mr-2' size={16} fill='gray' />
          <span>{'Fog of war'}</span>
        </div>

      </div>
    </div>
  )

};

export default MyCanvas;