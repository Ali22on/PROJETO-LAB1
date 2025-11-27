import React, { type JSX } from 'react';
import { chartConfigPerArea, chartConfigPerDate } from '@/assets/util/AttachedData';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { X, Squircle, ListFilter, Check, CircleCheck, CircleMinus, CircleDashed, Globe2, ShieldAlert, Info, ShieldAlertIcon } from 'lucide-react';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Button } from '@/components/ui/button';
import { useGlobals } from '@/Providers/Globals';
import AnexoI from '@/assets/AnexoI.json';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { useAlert } from '@/Providers/Alerts';

type AggragateTypes = 'Total' | 'by Function' | 'by Area';
type TimeAggragateTypes = 'Hourly' | 'Daily' | 'Weekly' | 'Monthly';
type dataType = {
    type: AggragateTypes;
    time: TimeAggragateTypes;
}
export const avilableTimes = {
    'Hourly': 'Por Hora',
    'Daily': 'Por Dia',
    'Weekly': 'Por Semana',
    'Monthly': 'Por Mês',
}
export const avilableAggragates = {
    'Total': 'Total',
    'by Function': 'Por Função',
    'by Area': 'Por Área',
}
export type FilterType = {
    area: string[];
    function: string[];
    timeFrame: number; // -1 for all days, 7 for last 7 days from the most recent date in the data
    dataType: dataType;
}

interface FilterProps extends React.ComponentProps<"div"> {
    filters: FilterType;
    setFilters: React.Dispatch<React.SetStateAction<FilterType>>;
}

const attachedAreas = AnexoI.areas as { nome: string, tipo: string, latitude: number, longitude: number }[];

export const availableFunctions = [...Object.keys(chartConfigPerDate)];

const rawAreas = [...Object.entries(chartConfigPerArea).map(([key, value]) => {
    return {
        value: value,
        key: key,
        type: attachedAreas.find(area => area.nome === value.label)?.tipo || 'Desconhecido'
    }
})]
export const availableAreas = [...rawAreas.map(area => area.value.label)];
const areaTypes = [...new Set(rawAreas.map(area => area.type))];

const Filters: React.FC<FilterProps> = ({ filters, setFilters, ...props }) => {
    const { onMobile } = useGlobals();
    const { showAlert } = useAlert();
    const mobileText = "text-l font-[400] font-lato ml-2 "
    const desktopText = "text-l font-[400] font-lato ml-4 "
    const periodWithNotice: (className: string) => JSX.Element = (className: string) => {
        return (
            <div className={`${className} flex items-center gap-1 ml-0`}
            style={{ marginLeft: '0px' }}>
                <Info size={18}
                    className='hover:cursor-pointer hover:text-blue-700 text-blue-500 dark:text-yellow-400'
                    onClick={() => {
                        showAlert(
                            <div className='flex gap-2'><ShieldAlertIcon className='text-blue-500 dark:text-yellow-400' />Informação Sobre o Período</div>,
                            <div>Como o sistema não esta conectado com um back-end própio, o período dos dados coletados reflete apartir da <i>última data disponível</i> e não do dia atual.</div>,
                        );
                    }}
                /> <h1>Período</h1>
            </div>
        );
    }
    return (
        <div {...props} >
            {/* Data Filters */}
            {
                onMobile && <h1 className={mobileText}>Filtrar Dados</h1>
            }
            <div className="gap-x-4 gap-y-2 flex  items-center flex-wrap">
                {
                    !onMobile && <h1 className={desktopText}>Filtrar Dados</h1>
                }
                <Popover >
                    <PopoverTrigger asChild>
                        <div className="flex items-center ">
                            <Button variant="outline">
                                <ListFilter className="mr-2" />
                                Filtrar Funções {
                                    filters.function.length !== availableFunctions.length && <>({filters.function.length})</>
                                }
                            </Button>
                            {
                                filters.function.length !== availableFunctions.length ? (
                                    <div>
                                        <X onClick={() => setFilters(prev => ({ ...prev, function: availableFunctions }))} color="red" className="text-red-500 hover:text-red-300 hover:cursor-pointer" />
                                    </div>
                                ) : null

                            }
                        </div>
                    </PopoverTrigger>
                    <PopoverContent className="">
                        <div>
                            <div className="font-lato font-[600] text-lg mb-2 font-lato">Funções</div>
                            <div className="text-sm text-muted-foreground mb-2">Selecione as funções que deseja incluir na análise.</div>

                        </div>
                        <hr />
                        <div className="flex flex-col mt-2">
                            {

                                Object.entries(chartConfigPerDate).map(([key, config]) => (
                                    <div key={key} className="flex items-center space-x-2 gap-2 hover:cursor-pointer"
                                        onClick={() => setFilters(prev => {
                                            if (prev.function.includes(key)) {
                                                return { ...prev, function: prev.function.filter(f => f !== key) }
                                            }
                                            return { ...prev, function: [...prev.function, key] }
                                        })}
                                    >
                                        {
                                            filters.function.includes(key) ? <Squircle fill={config.color} /> : <Squircle fill="gray" />
                                        }
                                        {config.label}
                                    </div>
                                ))
                            }
                        </div>
                    </PopoverContent>
                </Popover>
                <Popover  >
                    <PopoverTrigger asChild>
                        <div className="flex items-center ">
                            <Button variant="outline">
                                <ListFilter className="mr-2" />
                                Filtrar Áreas {
                                    filters.area.length !== availableAreas.length && <>({filters.area.length})</>
                                }
                            </Button>
                            {
                                filters.area.length !== availableAreas.length ? (
                                    <div>
                                        <X onClick={() => setFilters(prev => ({ ...prev, area: availableAreas }))} className="text-red-500 hover:text-red-300 hover:cursor-pointer" />
                                    </div>
                                ) : null

                            }
                        </div>
                    </PopoverTrigger>
                    <PopoverContent className="">
                        <div>
                            <div className="font-lato font-[600] text-lg mb-2 font-lato">Áreas</div>
                            <div className="text-sm text-muted-foreground mb-2">Selecione as áreas que deseja incluir na análise.</div>
                            <div className="flex flex-col mb-2 gap-1">
                                {
                                    areaTypes.map(area => {
                                        const numAreas = rawAreas.filter(a => a.type === area).map(a => a.value.label);
                                        const currentAreas = filters.area.map(a => rawAreas.find(ra => ra.value.label === a)?.type || null).filter(a => a !== null && a === area);
                                        const icon = numAreas.length === currentAreas.length ? <CircleCheck color={"green"} /> : (currentAreas.length > 0 ? <CircleMinus color={"orange"} /> : <CircleDashed color="gray" />);
                                        return (
                                            <div key={area} className="flex items-center space-x-2 gap-2 hover:cursor-pointer"
                                                onClick={() => setFilters(prev => {
                                                    return {
                                                        ...prev,
                                                        area: numAreas.length === currentAreas.length ? prev.area.filter(a => !numAreas.includes(a)) : [...new Set([...prev.area, ...numAreas])]
                                                    }
                                                })}
                                            >
                                                {icon} {area}
                                            </div>
                                        )
                                    })
                                }
                            </div>
                        </div>
                        <hr></hr>
                        <div className="flex flex-col mb-2">
                            {
                                availableAreas.map(area => (
                                    <div key={area} className="flex items-center space-x-2 gap-2 hover:cursor-pointer"
                                        onClick={() => setFilters(prev => {
                                            if (prev.area.includes(area)) {
                                                return { ...prev, area: prev.area.filter(f => f !== area) }
                                            }
                                            return { ...prev, area: [...prev.area, area] }
                                        })}
                                    >
                                        {filters.area.includes(area) ? <Check color={"green"} /> : <X color="gray" />}
                                        {area}
                                    </div>
                                ))
                            }
                        </div>
                    </PopoverContent>
                </Popover>
            </div>
            {/* Data Type Filters */}
            {onMobile && <h1 className={mobileText}>Agregar Dados</h1>}
            <div className="gap-2 flex  items-center">
                {!onMobile && <h1 className={desktopText}>Agregar Dados</h1>}
                <Select value={filters.dataType.type} onValueChange={(value) => setFilters(prev => ({ ...prev, dataType: { ...prev.dataType, type: value as AggragateTypes } }))}>
                    <SelectTrigger className="w-[120px] bg-white">
                        <SelectValue placeholder="Tipo de Agregação" />
                    </SelectTrigger>
                    <SelectContent>
                        {
                            Object.entries(avilableAggragates).map(([key, value]) => (
                                <SelectItem key={key} value={key}>
                                    {value}
                                </SelectItem>
                            ))
                        }
                    </SelectContent>
                </Select>
                <Select
                    value={filters.dataType.time}
                    onValueChange={(value) => {
                        if (value === "Hourly") {
                            showAlert(
                                <div className='flex gap-2'><ShieldAlert color='darkred' />Opção Indisponível</div>,
                                <>Ainda não temos os dados por hora. Por favor, escolha outra opção.</>,
                            );
                            return;
                        }
                        setFilters(prev => ({ ...prev, dataType: { ...prev.dataType, time: value as TimeAggragateTypes } }))

                    }}>
                    <SelectTrigger className="w-[150px] bg-white">
                        <SelectValue placeholder="Por Tempo" />
                    </SelectTrigger>
                    <SelectContent>
                        {
                            Object.entries(avilableTimes).map(([key, value]) => (
                                <SelectItem key={key} value={key}>
                                    {value}
                                </SelectItem>
                            ))
                        }
                    </SelectContent>
                </Select>
            </div>
            {/* Time Filters */}
            {onMobile && periodWithNotice(desktopText)}
            <div className="flex gap-4 justify-between items-center">
                {!onMobile && periodWithNotice(mobileText)}
                <ToggleGroup type="single" value={"" + filters.timeFrame} className=" border " aria-label="Theme Toggle"
                    onValueChange={(value) => {
                        if (value) setFilters((prev) => ({ ...prev, timeFrame: parseInt(value) }))
                    }}>
                    <ToggleGroupItem value={"1"} className='hover:cursor-pointer'
                    >24H</ToggleGroupItem>
                    <ToggleGroupItem value={"15"} className='hover:cursor-pointer'
                    >15d</ToggleGroupItem>
                    <ToggleGroupItem value={"30"} className='hover:cursor-pointer'
                    >Mês</ToggleGroupItem>
                    <ToggleGroupItem value={"-1"} className='hover:cursor-pointer'
                    ><Globe2 /></ToggleGroupItem>

                </ToggleGroup>
            </div>
        </div>
    );
};

export default Filters;