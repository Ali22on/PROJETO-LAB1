import React, { useState } from 'react';

interface TimeInputProps extends React.HTMLAttributes<HTMLInputElement> {
    setSeconds?: (value: number) => void;
    seconds?: number;
}

const TimeInput: React.FC<TimeInputProps> = ({ seconds, setSeconds, ...props }) => {
    const inputRef = React.useRef<HTMLInputElement>(null);
    // const timer = React.useRef<NodeJS.Timeout | null>(null);
    const secondsToTime = (secs: number) => {
        const minutes = Math.floor(secs / 60);
        const seconds = secs % 60;
        return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }
    const [value, setValue] = useState<string>(secondsToTime(seconds || 0));
    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        e.preventDefault();
        let value = e.target.value.replace(/[^\d]/g, '');
        let cursorPosition = e.target.selectionStart || 0;
        if (value.length > 2) {
            value = value.substring(0, 2) + ':' + value.substring(2, 4);
            if (cursorPosition >= 2) {
                cursorPosition += 1;
            }
        }

        e.target.value = value;
        e.target.setSelectionRange(cursorPosition, cursorPosition);
        setValue(value);
        setSeconds?.(value.split(':').reduce((acc, time) => (60 * acc) + +time, 0));

    };
    const cleanInput = (e: React.FocusEvent<HTMLInputElement, Element>) => {
        let value = e.target.value;
        if (value[value.length - 1] === ':') {
            value = value.slice(0, -1);

        }
        if (value.length > 2) {
            let [minutes, seconds] = value.split(':').map(v => parseInt(v, 10));
            if (seconds > 59) {
                seconds = 59;
            }
            value = minutes.toString().padStart(2, '0') + ':' + (isNaN(seconds) ? '' : seconds.toString().padStart(2, '0'));
        }
        setValue(value);
    }

    const propsFiltered = { ...props };
    delete propsFiltered.className;

    return (
        <input
            ref={inputRef}
            type='text'
            pattern="\d*"
            value={value}
            inputMode="numeric"
            className={`timeInput ${props.className}`}
            onChange={handleChange}
            onFocus={(e) => {
                e.target.setSelectionRange(0, 2)
                e.target.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
            }}
            onBlur={cleanInput}
            placeholder='MM:SS'
            {...propsFiltered}
        />
    );
};

export default TimeInput;