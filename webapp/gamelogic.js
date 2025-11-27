class GameState {
    players = {};
    avaliableSlots = [0,1];
    constructor() {
        this.score = 0;
        this.level = 1;
        this.lives = 3;
    }
    playerJoin(playerId) {
        console.log(`Player ${playerId} is trying to join.`, this.avaliableSlots);
        if (this.avaliableSlots.length == 0) {
            return -1;
        }
        const slot = this.avaliableSlots.shift();
        this.players[playerId] = slot;
        return slot;
    }
    playerLeave(playerId) {
        const slot = this.players[playerId];
        // if player was not p1 or p2
        if (slot === undefined) {
            return;
        }
        this.avaliableSlots.push(slot);
        console.log(`Player ${playerId} left. Slot ${slot} is now available.`, this.avaliableSlots);
        delete this.players[playerId];
    }
}

module.exports = {GameState};