import React from 'react';
import { Badge } from './ui/badge';

interface StateBadgeProps {
    state: string;
    className?: string;
}

const StateBadge: React.FC<StateBadgeProps> = ({ state, className }) => {
    const pallete = {
        "ready": '#2f6298ff ',
        "running": 'green ',
        "paused": 'orange ',
        "finished": 'red ',
    } as any;
    const State = state.charAt(0).toUpperCase() + state.slice(1);
    return (
        <Badge className={`${state !== 'paused' ? 'text-white' : ''} ${className || ''}`} 
            style={{ backgroundColor: pallete[state] || 'gray' }}
        >
            {State}
        </Badge>
        
    );
};

export default StateBadge;