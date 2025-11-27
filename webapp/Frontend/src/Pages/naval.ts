// is hidden if the highest bit is set
const is_hidden = (byte: number) => {
    return (byte & 0x80) === 0x80;
}

/*
    Ships:
        1-5 -> Submarine
        6 -> Porta Aviao
        7 -> Encouraçado
        8-9 -> Hidroavião
        10-11 -> Cruzador
*/

export const ShipType = {
    SUBMARINE: 'Submarine',
    AIRCRAFT_CARRIER: 'Aircraft Carrier',
    BATTLESHIP: 'Battleship',
    SEAPLANE: 'Seaplane',
    CRUISER: 'Cruiser',
    UNKNOWN: 'Water'
} as const;
export type ShipType = typeof ShipType[keyof typeof ShipType];

const ship_type = (byte: number) => {
    const value = byte & 0x1F; // 5 lower bits
    if (value >= 1 && value <= 5) {
        return ShipType.SUBMARINE;
    } else if (value === 6) {
        return ShipType.AIRCRAFT_CARRIER;
    } else if (value === 7) {
        return ShipType.BATTLESHIP;
    } else if (value >= 8 && value <= 9) {
        return ShipType.SEAPLANE;
    } else if (value >= 10 && value <= 11) {
        return ShipType.CRUISER;
    } else {
        return ShipType.UNKNOWN;
    }
}

export const color_map = new Map<ShipType, string>([
    [ShipType.SUBMARINE, 'green'],
    [ShipType.AIRCRAFT_CARRIER, 'cyan'],
    [ShipType.BATTLESHIP, 'orange'],
    [ShipType.SEAPLANE, 'purple'],
    [ShipType.CRUISER, 'yellow'],
    [ShipType.UNKNOWN, 'blue']
]);


export const getBlockColor = (byte: number) => {
    if (is_hidden(byte)) {
        return 'gray'; // Hidden
    }
    else return color_map.get(ship_type(byte)) || 'blue'; //water
}

export const is_ship_dead = (ship: number, map: number[]) =>
{
    for (let index = 0; index < map.length; index++) {
        if (map[index] === ship)
        {
            return false;
        }
    }
    return true;
}