export type TeamState = 'ready' | 'running' | 'paused' | 'finished';
export type SpeedType = 0.5 | 1 | 2 | 4;

export class Team {
    private static DRIFT_CHECK_INTERVAL_MS = ((3 * 60) + 11) * 1000; // 3 minutes + 11 seconds
    public name: string;
    public baseTime: number; // in seconds
    public state: TeamState = 'ready';
    public speed: SpeedType = 1;
    public timeLeft: number = 0;
    public timeAdded: number = 0;
    public timeSubtracted: number = 0;
    public timePaused: number = 0;
    public timeRunning: number = 0;
    public startTime?: Date;
    public finishTime?: Date;
    private lastUpdateTime?: number;
    private referenceTime: number = 0;
    public finalDrift = 0; // in ms, final uncorrected drift at finish
    
    constructor(name: string, baseTime: number) {
        this.name = name;
        this.baseTime = baseTime;
        this.rearm()
    }

    public rearm() {
        this.state = 'ready';
        this.speed = 1;
        this.timeLeft = this.baseTime;
        this.timeAdded = 0;
        this.timeSubtracted = 0;
        this.timePaused = 0;
        this.timeRunning = 0;
        this.startTime = undefined;
        this.finishTime = undefined;
    }
    public start() {
        if (this.state === 'ready' && this.baseTime > 0) {
            this.startTime = new Date();
            this.lastUpdateTime = performance.now();
            this.referenceTime = performance.now();
            this.state = 'running';
        }
        if (this.state === 'paused' && this.timeLeft > 0) {
            this.state = 'running';
        }
    }
    public pause() {
        if (this.state === 'running') {
            this.state = 'paused';
        }
    }
    public correctDrift(currentMs: number, force: boolean = false) {
        if (!this.lastUpdateTime) return;
        const deltaTime_ms = currentMs - this.lastUpdateTime;
        if (deltaTime_ms >= Team.DRIFT_CHECK_INTERVAL_MS || force) {
            const referenceTime_ms = currentMs - this.referenceTime;
            const totalTime_ms = (this.timeRunning + this.timePaused) * 1000;
            const drift_ms = referenceTime_ms - totalTime_ms;
            const drift_s = drift_ms / 1000;
            // const calculatedTime_ms = ((this.timeRunning + this.timePaused) * 1000) - this.lastFixedTime;
            // const drift_ms = deltaTime_ms - calculatedTime_ms;
            // const drift_s = drift_ms / 1000;
            // if (this.name === 'Equipe 1') {
            //     console.log((this.timeRunning + this.timePaused) * 1000, this.lastFixedTime, calculatedTime_ms + drift_ms);
            //     console.log(`Correcting drift for ${this.name}: deltaTime=${deltaTime_ms}ms, calculatedTime=${calculatedTime_ms}ms, drift=${drift_ms}ms`);
            // }
            if (this.state === 'running') {
                this.timeLeft -= drift_s;
                if (this.timeLeft < 0) this.timeLeft = 0;
                this.timeRunning += drift_s;
            }
            else if (this.state === 'paused') {
                this.timePaused += drift_s;
            }
            // else if (this.state === 'finished' && !this.finalDriftCorrection) {
            //     if (drift_ms > 0) {
            //         this.timeRunning += drift_s;
            //         this.timeLeft -= drift_s;
            //         this.state = 'running'; // temporarily set to running to add the drift time
            //         this.finishTime = undefined; // clear finish time to be recalculated 
            //     }
            //     this.finalDriftCorrection = true; // only correct once after finish
            // }

            this.lastUpdateTime = currentMs;
        }
    };

    public checkFinish(): boolean {
        if (this.timeLeft <= 0 && this.state === 'running') {
            this.timeLeft = 0;
            this.state = 'finished';
            this.finishTime = new Date();
            this.finalDrift = (performance.now() - this.referenceTime) - (this.timeRunning + this.timePaused) * 1000;
            return true;
        }
        return false;
    }
    public addTime(seconds: number) {
        this.timeLeft += seconds;
        if (seconds > 0) {
            this.timeAdded += seconds;
        }
        else {
            this.timeSubtracted += -seconds;
            if (this.timeLeft < 0) this.timeLeft = 0;
        }

    }
}
