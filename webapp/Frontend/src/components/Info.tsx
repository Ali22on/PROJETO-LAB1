import React from 'react';
import {
    Tooltip,
    TooltipContent,
    TooltipTrigger,
} from "@/components/ui/tooltip"
import { InfoIcon } from 'lucide-react';


interface InfoTooltipProps extends React.HTMLAttributes<HTMLDivElement> {
    legend?: React.ReactNode;
    children?: React.ReactNode;
    iconSize?: number;
    iconColor?: string;
    legendClassName?: string;
}

const InfoTooltip: React.FC<InfoTooltipProps> = ({ legend, legendClassName, children, iconSize = 24, ...props }) => {
    const [open, setOpen] = React.useState(false);
    return (
        <Tooltip open={open} onOpenChange={setOpen} >
            <TooltipTrigger asChild>
                <div className='text-gray-500 ' {...props} onClick={() => setOpen(!open)}>
                    <InfoIcon
                        size={iconSize}
                    />
                </div>
            </TooltipTrigger>
            <TooltipContent sideOffset={4} className='z-100001 text-md font-inter max-w-[90vw] flex-wrap break-words ' >
            {
                legend && <div className={`flex text-center ${legendClassName}`}>{legend}</div>
            }
            {
                !legend && <>{children}</>
            }
            </TooltipContent>
        </Tooltip>
    );
};

export default InfoTooltip;