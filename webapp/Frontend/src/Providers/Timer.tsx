import React, { createContext, useContext, useState, type ReactNode } from 'react';
import { useAlert } from './Alerts';


export type TeamState = 'running' | 'paused' | 'finished' | 'ready';
export type SpeedType = 0.5 | 1 | 2 | 4;
export type Team = {
    name: string;
    baseTime: number; // in seconds
    timeLeft: number; // in seconds
    timePaused?: number; // in seconds
    timeRunning?: number; // in seconds
    state: TeamState;
    startTime?: Date;
    timeAdded?: number; // in seconds
    timeSubtracted?: number; // in seconds
    finishTime?: Date;
    speed?: SpeedType; // speed multiplier (1x, 2x, etc.)
    finalDrift?: number; // in ms, positive or negative
    stateLocked?: boolean; // if true, state wont be changed by updateTeamsState
}

// name: team.name,
//             state: team.state,
//             timeLeft: team.timeLeft,
//             timeRunning: team.timeRunning,
//             timePaused: team.timePaused,
//             startTime: team.startTime,
//             finishTime: team.finishTime

export type TeamUpdate = {
    name: string,
    state: TeamState,
    timeLeft?: number,
    speed?: SpeedType,
    finishTime?: string,
    startTime?: string,
    timeRunning?: number,
    timePaused?: number,
    timeAdded?: number,
    timeSubtracted?: number,
    finalDrift?: number,
}

export type TeamConfig = {
    name: string[];
    baseTime: number; // in seconds
}

type TimerContextType = {
    teams: Team[];
    setTeams: (newTeams: Team[], store?: boolean) => void;
    // startChrono: (index: number[]) => void;
    // pauseChrono: (index: number[]) => void;
    // unpauseChrono: (index: number[]) => void;
    // finishChrono: (index: number[]) => void;
    // rearmChrono: (index: number[]) => void;
    // setSpeed: (index: number[], speed: SpeedType) => void;
    applyAction: (action: string, index: number[]) => void;
    addTime: (index: number[], seconds: number) => void;
    updateTeamsState: (teamsStates: TeamUpdate[]) => void;
    startTicker: () => void;
    stopTicker: () => void;
    setTeamsFromConfig: (config: TeamConfig) => void;
    exportCSV: () => void;
};

const TimerContext = createContext<TimerContextType | undefined>(undefined);

export const TimerProvider = ({ children }: { children: ReactNode }) => {
    const [teams, __setTeams] = useState<Team[]>([]);
    const [tickerState, setTickerState] = useState<boolean>(false);
    const lastTick = React.useRef({ tickNum: 0, time: performance.now() });
    const ticker = React.useRef<NodeJS.Timeout | null>(null);
    const teamRefs = React.useRef<Team[]>([]);
    const { useToast } = useAlert();

    const exportCSV = () => {
        const secToString = (seconds: number) => {
            const hours = Math.floor(seconds / 3600);
            const minutes = Math.floor((seconds % 3600) / 60);
            const secs = Math.round(seconds % 60);
            return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        }
        const csvContent = "data:text/csv;charset=utf-8," +
            ['Team Name,State,Base Time,Time Left,Time Running,Time Paused,Total Time,Drift(ms),Time Added,Time Subtracted,Speed']
                .concat(teams.map(team => {
                    return [
                        `"${team.name.replace(/"/g, '""')}"`,
                        team.state, // current state
                        secToString(team.baseTime), // base time
                        secToString(team.timeLeft),// time left
                        secToString(team.timeRunning || 0), // time running
                        secToString(team.timePaused || 0),// time paused
                        secToString(((team.timeRunning || 0) + (team.timePaused || 0))), // total time
                        (team.finalDrift || 0).toFixed(0), // in ms, positive or negative
                        secToString((team.timeAdded || 0)), // time added
                        secToString((team.timeSubtracted || 0)), // time subtracted
                        team.speed || 1
                    ].join(',');
                })).join('\n');
        const checkSum = Array.from(csvContent.slice(28)).reduce((a, b) => a + b.charCodeAt(0), 0) % 1997;
        const csvContentWithChecksum = csvContent + `\nchecksum:${checkSum}`;
        const encodedUri = encodeURI(csvContentWithChecksum);
        const link = document.createElement("a");
        link.setAttribute("href", encodedUri);
        link.setAttribute("download", `mw_chrono_${new Date().toISOString().slice(0, 10)}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    const _setTeams = (newTeams: Team[]) => {
        __setTeams(newTeams);
        teamRefs.current = newTeams;
    }
    const lockState = (index: number[], lock: boolean) => {
        const t = teamRefs.current;
        for (const i of index) {
            if (t[i]) {
                t[i].stateLocked = lock;
            }
        }
        _setTeams([...t]);
    }
    const setTeamsFromConfig = (config: TeamConfig) => {
        const _teams: Team[] = [];
        for (let i = 0; i < config.name.length; i++) {
            _teams.push({
                name: config.name[i],
                baseTime: config.baseTime,
                timeLeft: config.baseTime,
                state: 'ready',
                speed: 1
            });
        }
        _setTeams(_teams);
    }
    const setTeams = (newTeams: Team[]) => {
        console.log('Setting teams:', newTeams);
        const _teams = newTeams.map(team => {
            team.state = 'ready';
            team.timeLeft = team.baseTime;
            team.speed = 1;
            return team;
        });
        _setTeams(_teams);
    }
    const startChrono = (index: number[]) => {
        const t = teams;
        for (const i of index) {
            if (t[i].state === 'paused' && t[i].baseTime > 0) {
                t[i].state = 'running';
            }
            else if (t[i].state === 'ready' && t[i].baseTime > 0) {
                t[i].startTime = new Date();
                t[i].timeLeft = t[i].baseTime;
                t[i].state = 'running';
            }
        }
        _setTeams([...t]);
    }
    const unpauseChrono = (index: number[]) => {
        const t = teams;
        for (const i of index) {
            if (t[i].state === 'paused' && t[i].baseTime > 0) {
                t[i].state = 'running';
            }
        }
        _setTeams([...t]);
    }
    const pauseChrono = (index: number[]) => {
        const t = teams;
        for (const i of index) {
            if (t[i].state === 'running') {
                t[i].state = 'paused';
            }
        }
        _setTeams([...t]);
    }
    const finishChrono = (index: number[]) => {
        const t = teams;
        for (const i of index) {
            if (t[i].state !== 'finished') {
                t[i].state = 'finished';
                t[i].finishTime = new Date();
            }
        }
        _setTeams([...t]);
    }
    const addTime = (index: number[], seconds: number) => {
        const t = teams;
        for (const i of index) {
            const old = t[i].timeLeft || 0;
            t[i].timeLeft += seconds;
            if (t[i].timeLeft < 0) t[i].timeLeft = 0;
            if (t[i].timeLeft <= 0) {
                finishChrono([i]);
            }
            if (seconds > 0) {
                t[i].timeAdded = t[i].timeLeft - old + (t[i].timeAdded || 0);
            }
            else {
                t[i].timeSubtracted = (t[i].timeSubtracted || 0) - (t[i].timeLeft - old);
            }
        }
        _setTeams([...t]);
    }
    const rearmChrono = (index: number[]) => {
        const t = teams;
        for (const i of index) {
            t[i].state = 'ready';
            t[i].timeLeft = t[i].baseTime;
            t[i].timeRunning = 0;
            t[i].timePaused = 0;
            t[i].startTime = undefined;
            t[i].finishTime = undefined;
            t[i].timeAdded = 0;
            t[i].timeSubtracted = 0;
            t[i].speed = 1;
        }
        _setTeams([...t]);
    }
    const setSpeed = (index: number[], speed: SpeedType) => {
        const t = teams;
        for (const i of index) {
            t[i].speed = speed;
        }
        _setTeams([...t]);
    }
    const applyAction = (action: string, index: number[]) => {
        let lock = true;
        if (action === 'start') startChrono(index);
        else if (action === 'pause') pauseChrono(index);
        else if (action === 'unpause') unpauseChrono(index);
        else if (action === 'finish') finishChrono(index);
        else if (action === 'rearm') rearmChrono(index);
        else if (action.startsWith('add:')) {
            const seconds = parseInt(action.split(':')[1]);
            if (!seconds) return;
            addTime(index, seconds);

        }
        else if (action.startsWith('speed:')) {
            const speed = parseFloat(action.split(':')[1]);
            setSpeed(index, speed as SpeedType);
        }
        if (lock) {
            lockState(index, true);
            setTimeout(() => {
                lockState(index, false);
            }, 500);
        }
    }
    const startTicker = () => {
        setTickerState(true);
    }
    const stopTicker = () => {
        setTickerState(false);
    }

    const updateTeamsState = (teamsStates: TeamUpdate[]) => {
        try {
            const t = teamRefs.current;
            if (t.length === 0)
                return false;
            console.log('Updating teams state with:', teamsStates);
            for (let i = 0; i < teamsStates.length; i++) {
                if (!t[i]) continue;
                for (const key of Object.keys(teamsStates[i]) as (keyof TeamUpdate)[]) {
                    if (!key) continue;
                    if (teamsStates[i][key] !== undefined && teamsStates[i][key] !== null) {
                        if (key === 'finishTime' || key === 'startTime') {
                            (t[i] as any)[key] = new Date(teamsStates[i][key] as string);
                        }
                        else if (key === 'state' || key === 'speed' || key === 'timeLeft') {
                            if (t[i].stateLocked) {
                                continue;
                            }
                            (t[i] as any)[key] = teamsStates[i][key];
                        }
                        else
                            (t[i] as any)[key] = teamsStates[i][key];
                    }
                }
            }
            _setTeams([...t]);
            return true;
        } catch (error) {
            console.error('Error updating teams state:', error);
            console.log('teamsStates:', teamsStates, teams);
            return false;
        }
    }
    React.useEffect(() => {
        if (!tickerState) {
            if (ticker.current) {
                clearInterval(ticker.current);
                ticker.current = null;
            }
            return;
        }
        ticker.current = setInterval(() => {
            const now = performance.now();
            if (now - lastTick.current.time < 249) {
                return;
            }
            // const delta = Date.now() - lastTick.current.time;
            lastTick.current = { tickNum: (lastTick.current.tickNum + 1) % 8, time: now };
            const t = teams;
            let updated = false;
            for (let i = 0; i < t.length; i++) {
                const cont = t[i];
                const mod = cont.speed === 0.5 ? 8 : cont.speed === 1 ? 4 : cont.speed === 2 ? 2 : cont.speed === 4 ? 1 : 0;
                if (lastTick.current.tickNum % mod !== 0) {
                    continue;
                }
                if (cont.state === 'running' && cont.timeLeft > 0) {
                    cont.timeLeft -= 1;
                    cont.timeRunning = (cont.timeRunning || 0) + 1 / cont.speed!;
                    updated = true;
                    // console.log('Tick', lastTick.current.tickNum, 'for team', cont.name, 'with speed', cont.speed, 'and mod', mod, delta, 1 / cont.speed!, cont.timeLeft);

                }
                if (cont.state === 'paused' && cont.timeLeft > 0) {
                    cont.timePaused = (cont.timePaused || 0) + 1 / cont.speed!;
                    updated = true;
                }
                if (cont.state === 'running' && cont.timeLeft <= 0) {
                    cont.state = 'finished';
                    cont.finishTime = new Date();
                    updated = true;
                    useToast('success', `Team ${cont.name} has finished!`);
                }
            }
            if (updated) {
                _setTeams([...t]);
            }
        }, 5);
        return () => clearInterval(ticker.current!);
    }, [teams, tickerState]);
    return (
        <TimerContext.Provider value={{ updateTeamsState, teams, exportCSV, setTeams, addTime, startTicker, stopTicker, setTeamsFromConfig, applyAction }}>
            {children}
        </TimerContext.Provider>
    );
};

export const useTimer = () => {
    const context = useContext(TimerContext);

    if (!context) {
        throw new Error('useTimer must be used within a TimerProvider');
    }
    return context;
};