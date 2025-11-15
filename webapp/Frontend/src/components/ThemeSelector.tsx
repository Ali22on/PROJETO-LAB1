import React from 'react';
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { MoonStar, Sun } from 'lucide-react';
import { useGlobals } from '@/Providers/Globals';
//Theme Toggle component -> Extract to separate file to have it in the header and login page

const ThemeSelector: React.FC = () => {
    const { theme, setDarkMode } = useGlobals();
    return (
        <div className="pr-4 ">
            <ToggleGroup type="single" value={theme} className="border " aria-label="Theme Toggle">
                <ToggleGroupItem value="dark" className='hover:cursor-pointer'
                    onClick={() => setDarkMode(true)}
                ><MoonStar /></ToggleGroupItem>
                <ToggleGroupItem value="light" className='hover:cursor-pointer'
                    onClick={() => setDarkMode(false)}
                ><Sun /></ToggleGroupItem>
            </ToggleGroup>
        </div>
    );
};

export default ThemeSelector;