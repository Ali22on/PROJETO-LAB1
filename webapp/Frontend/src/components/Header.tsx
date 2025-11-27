import React from 'react';
import { Timer } from 'lucide-react';
// import ThemeSelector from './ThemeSelector';
// import confetti from 'canvas-confetti';
// import { MenuIcon } from 'lucide-react';
import { useGlobals } from '../Providers/Globals';
import { useNavigate } from 'react-router';
// import {
//     Sheet,
//     SheetContent,
//     SheetDescription,
//     SheetFooter,
//     SheetHeader,
//     SheetTitle,
// } from "@/components/ui/sheet"
// import { useNavigate } from 'react-router-dom';

// import { useLocation } from 'react-router-dom';
// import { useAlert } from '@/Providers/Alerts';
import MenuButtons from './MenuButtons';
const Header: React.FC = () => {
    const Navigate = useNavigate();
    const {  onMobile } = useGlobals();
    // const fireConfetti = () => {
    //     const duration = 5 * 1000;
    //     const animationEnd = Date.now() + duration;
    //     const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };
    //     const randomInRange = (min: number, max: number) =>
    //         Math.random() * (max - min) + min;
    //     const interval = window.setInterval(() => {
    //         const timeLeft = animationEnd - Date.now();
    //         if (timeLeft <= 0) {
    //             return clearInterval(interval);
    //         }
    //         const particleCount = 50 * (timeLeft / duration);
    //         confetti({
    //             ...defaults,
    //             particleCount,
    //             origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 },
    //         });
    //         confetti({
    //             ...defaults,
    //             particleCount,
    //             origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 },
    //         });
    //     }, 250);
    // };

    // const Navigate = useNavigate();
    // const [menuOpen, setMenuOpen] = React.useState(false);
    // const desc = ['click me', '/vtmattedi', '/vitor-mattedi-dev'];
    // const images = () => {
    //     return [
    //         <img
    //             src="/logo-nobg.png"
    //             alt="Logo"
    //             className="h-8 ml-4 cursor-pointer"
    //             onClick={fireConfetti}
    //             style={{
    //                 filter: theme === 'dark' ? 'invert(1)' : 'none',
    //             }}
    //         />,
    //         <img src="https://simpleicons.org/icons/github.svg" alt="GitHub Logo" className="h-8 ml-4 cursor-pointer hover:opacity-70"
    //             style={{
    //                 filter: theme === 'dark' ? 'invert(1)' : 'none',
    //             }}
    //             onClick={() => window.open('https://github.com/vtmattedi', '_blank')}
    //         />,
    //         <img src="https://icons.getbootstrap.com/assets/icons/linkedin.svg" alt="LinkedIn Logo" className="h-8 ml-4 cursor-pointer hover:opacity-70"
    //             onClick={() => window.open('https://www.linkedin.com/in/vitor-mattedi-dev/', '_blank')}
    //             style={{
    //                 filter: theme === 'dark' ? 'invert(1)' : 'none',
    //             }}
    //         />
    //     ]
    // }

    return (
        <div
            className="bg-[var(--header-bg)] w-full  flex justify-between items-center position-sticky top-0 z-999 shadow-md w-full h-[48px] px-4"
            style={{
                position: 'sticky',
                top: 0,
                zIndex: 9999,
                backdropFilter: 'saturate(180%) blur(20px)',
            }}>

            <div className='flex flex-row gap-2 items-center'>
                {
                    <div className='flex gap-1 hover:cursor-pointer'
                        onClick={() => {
                            Navigate('/');
                        }}
                        style={{
                            color: 'var(--text-secondary)',
                            fontSize: '0.9rem',
                            alignItems: 'flex-end',

                        }}>
                        <span className='font-audiowide text-2xl flex gap-1'> <Timer /> ChronoApp</span>
                        <i className='font-lato text-sm'>by mattediworks &copy;</i>
                    </div>
                }
            </div>
            <MenuButtons
                className='flex flex-row gap-2'
                onlyIcon={onMobile}
            />
            {/* {!onMobile && <ThemeSelector />} */}
            {/* {onMobile && (<div>
                <MenuIcon className='cursor-pointer' />
            </div>)} */}

            {/* <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
                <SheetContent className='z-9999 bg-[var(--header-bg)]' side='right'
                    style={{
                        transition: 'transform 0.3s ease-in-out',
                    }}
                >
                    <SheetHeader>
                        <SheetTitle className='text-2xl font-audiowide flex items-center gap-2'>Settings</SheetTitle>
                        <SheetDescription>
                            <div className='flex mb-6  gap-4 px-2 items-center font-audiowide text-2xl  justify-between text-black dark:text-white'>
                                <span>Theme:</span>
                                <ThemeSelector />
                            </div>
                            <div className='flex flex-col gap-2 mb-4 items-center text-black dark:text-white font-inter text-lg '>
                                {
                                    images().map((img, index) => (
                                        <div key={index} className='flex items-center w-full gap-2' title={desc[index]}>{img}{desc[index]}</div>
                                    ))
                                }
                            </div>
                            <hr />
                            <div className='flex w-full justify-end'>Version 1.0</div>
                        </SheetDescription>
                        <SheetFooter>
                            Designed by Mattediworks &copy;
                        </SheetFooter>
                    </SheetHeader>
                </SheetContent>
            </Sheet> */}

        </div >

    );
};

export default Header;