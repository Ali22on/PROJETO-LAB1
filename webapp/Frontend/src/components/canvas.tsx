import React, { useRef, useEffect } from 'react';

const MyCanvas: React.FC = ({ data, position }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [positionState, _setPositionState] = React.useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const posState = useRef(positionState);
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
    
   
  useEffect(() => {
    const keyEvent = (e) => {
      switch (e.key) {
        case 'ArrowUp':
          setNewPos({ x: 0, y: -1 });
          break;
        case 'ArrowDown':
          setNewPos({ x: 0, y: 1 });
          break;
        case 'ArrowLeft':
          setNewPos({ x: -1, y: 0 });
          break;
        case 'ArrowRight':
          setNewPos({ x: 1, y: 0 });
          break;
      }
      
    };
    window.addEventListener('keydown', keyEvent);
    return () => {
      window.removeEventListener('keydown', keyEvent);
    };

  }, [position]);
  const getColor = (value: number) => {
    const colors = ['blue', 'green', 'red', 'yellow'];
    return colors[value] || 'black';
  };
  useEffect(() => {
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
            ctx.fillStyle = getColor(data[i]);
            ctx.fillRect((i % 8) * 50 + 2, Math.floor(i / 8) * 50 + 2, 46, 46);

          }
        }

      }
    }
  }, [data, positionState]); // Empty dependency array means this runs once on mount

  return <canvas ref={canvasRef} width={400} height={400} />;
};

export default MyCanvas;