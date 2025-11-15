import React from 'react';
import { Button } from './ui/button';
import { RotateCcw, Plus, Minus } from 'lucide-react';
import { useTimer, type SpeedType } from '../Providers/Timer';
import { Card } from './ui/card';
import { PlayBtn, PauseBtn, StopBtn, SpeedControl } from './btns.tsx';
import type { HTMLAttributes } from 'react';
import TimeInput from './timeInput.tsx';
import { Tooltip, TooltipContent, TooltipTrigger } from './ui/tooltip.tsx';

interface TeamCardsProps extends HTMLAttributes<HTMLDivElement> {
    onAction?: (action: string, index: number[]) => void;

}

const pallete = {
    ready: '#2f6298ff',
    running: 'green',
    paused: 'orange',
    finished: 'red',
}

const TeamCards: React.FC<TeamCardsProps> = ({ onAction }, ...props) => {
    const startChrono = (index: number[]) => onAction?.('start', index);
    const pauseChrono = (index: number[]) => onAction?.('pause', index);
    const finishChrono = (index: number[]) => onAction?.('finish', index);
    const addTime = (index: number[], seconds: number) => onAction?.(`add:${seconds}`, index);
    const rearmChrono = (index: number[]) => onAction?.('rearm', index);
    const setSpeed = (index: number[], speed: SpeedType) => onAction?.(`speed:${speed}`, index);
    const { teams } = useTimer();
    const [values, setValues] = React.useState<number[]>(teams.map(() => 300));
    const maxName = (name: string) => {
        if (name.length > 18) {
            return name.slice(0, 15) + '...';
        }
        return name;
    };
    const secondsToTime = (secs?: number) => {
        if (secs === undefined) return '00:00';
        const hours = Math.floor(secs / 3600);
        const minutes = Math.floor(secs / 60) % 60;
        const seconds = Math.floor(secs % 60);
        let str = '';
        if (hours > 0) {
            str += `${hours.toString().padStart(2, '0')}:`;
        }
        str += `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        return str;
    }
    return (
        <div className='flex flex-wrap justify-center' {...props}>
            {
                teams.map((team, index) => (
                    <Card key={index} className='m-2 p-4 w-80 gap-2'>
                        <div className='flex justify-between items-center'>
                            {team.name.length <= 18 ? <h2 className='font-lato text-xl mb-2'>{team.name}</h2> : (
                                <Tooltip>
                                    <TooltipTrigger className='hover:cursor-default' asChild>
                                        <h2 className='font-lato text-xl mb-2'>{maxName(team.name)}</h2>
                                    </TooltipTrigger>
                                    <TooltipContent sideOffset={4} className='max-w-md'>
                                        <h5 className='font-lato text-[1rem] mb-2'>{team.name}</h5>
                                    </TooltipContent>
                                </Tooltip>
                            )}
                            <span
                                style={{
                                    color: pallete[team.state] || 'black',
                                }}
                            >{team.state[0]?.toLocaleUpperCase() + team.state.slice(1)}</span>
                        </div>
                        <hr />
                        {
                            team.state === 'finished' && team.finishTime ? (
                                <div className='w-full flex flex-col items-center gap-0'>
                                    <div className='text-sm text-gray-500 mb-2 flex justify-between w-full'>
                                        <div >
                                            {team.startTime ? team.startTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }) : 'N/A'}-
                                            {team.finishTime ? team.finishTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }) : 'N/A'}
                                        </div>
                                        <div>
                                            {team.finalDrift?.toFixed(0)}ms
                                        </div>
                                    </div>
                                    <div className='flex justify-between items-center w-full px-4'>
                                        <span className='text-muted-foreground text-sm'>Paused Time:</span>
                                        <span className='font-inter text-2xl'>
                                            {secondsToTime((team.timePaused))}
                                        </span>
                                    </div>
                                    <div className='flex justify-between items-center w-full px-4'>
                                        <span className='text-muted-foreground text-sm'>Running Time:</span>
                                        <span className='font-inter text-2xl'>
                                            {secondsToTime((team.timeRunning))}
                                        </span>
                                    </div>
                                    <div className='flex justify-between items-center w-full px-4'>
                                        <span className='text-muted-foreground text-sm'>Added Time:</span>
                                        <span className='font-inter text-lg text-green-500'>
                                            {secondsToTime((team.timeAdded))}
                                        </span>
                                    </div>
                                    <div className='flex justify-between items-center w-full px-4'>
                                        <span className='text-muted-foreground text-sm'>Sub'ed Time:</span>
                                        <span className='font-inter text-lg text-red-500'>
                                            {secondsToTime((team.timeSubtracted))}
                                        </span>
                                    </div>
                                    {/* <div className='flex justify-between items-center w-full px-4'>
                                        <span className='text-sm text-red-500'>-{team.timeSubtracted || 0}</span>
                                        <span className='text-sm text-green-500'>+{team.timeAdded || 0}</span>
                                    </div> */}
                                    <Button className='bg-blue-500 text-white mt-2' onClick={() => rearmChrono([index])}><RotateCcw className='rotate-275' /><span>Reset</span></Button>
                                </div>
                            ) : (<>
                                <div className='flex justify-center items-center text-4xl h-full'>
                                    <p className='font-inter'>{new Date(team.timeLeft * 1000).toISOString().slice(11, 19)}</p>
                                </div>
                                <div className='flex flex-col items-center gap-2 '>
                                    <div className='flex items-center w-full justify-center gap-2'>
                                        <Button onClick={() => {
                                            addTime([index], -values[index]);
                                        }} className='m-2 bg-blue-500 text-white w-20'>
                                            <Minus /> Sub
                                        </Button>
                                        <div className='flex flex-col items-center border-white border rounded-md p-0 hover:bg-gray-200 dark:hover:bg-gray-800'>
                                            <TimeInput className='w-24 text-center text-[1.2rem]'
                                                seconds={values[index]}
                                                setSeconds={(val) => {
                                                    const newValues = [...values];
                                                    newValues[index] = val;
                                                    setValues(newValues);
                                                }}
                                            />
                                            <i className='text-[0.70rem] text-muted-foreground'>Minutes</i>
                                        </div>

                                        <Button onClick={() => {
                                            addTime([index], values[index]);
                                        }} className='m-2 bg-blue-500 text-white w-20'>
                                            <Plus /> Add
                                        </Button>

                                    </div>
                                    <div className='flex flex-wrap gap-2 '>
                                        <PlayBtn state={team.state} onClick={() => startChrono([index])} />
                                        <PauseBtn state={team.state} onClick={() => pauseChrono([index])} />
                                        <StopBtn state={team.state} onClick={() => finishChrono([index])} />
                                    </div>
                                    <div>
                                        <SpeedControl state={team.state} speed={team.speed || 1} setSpeed={(speed: SpeedType) => { setSpeed([index], speed); }} />
                                    </div>
                                </div>
                            </>)
                        }
                    </Card>
                ))
            }
        </div >
    );
};

export default TeamCards;