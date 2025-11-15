// Treat data for all charts
import AnexoII from '../AnexoII.json';
import AnexoI from '../AnexoI.json';
import type { ChartConfig } from "@/components/ui/chart";
const chartData = AnexoII.dadosPessoas as { data: string, funcao: string, quantidade: number, area: string }[];

export interface DataPerDate {
    date: string;
    values: {
        function: string,
        value: number;
        area: string;
    }[];
}
// Get data grouped by date
export const getDataPerDate = () => {
    const myData: DataPerDate[] = [];
    chartData.forEach(item => {
        const func = item.funcao.toLowerCase().replaceAll('â', 'a'); // normalize keys
        // Mecânico has problems with â character
        // Investigate global normalization solution later
        const existing = myData.find(d => d.date === item.data);
        if (existing) {
            existing.values.push({ function: func, value: item.quantidade, area: item.area });
        } else {
            myData.push({
                date: item.data,
                values: [{ function: func, value: item.quantidade, area: item.area }],
            });
        }
    });
    return myData;
};

interface DataPerArea {
    area: string;
    values: { [key: string]: number | string, date: string }[];
}
// Get data grouped by area
export const getDataPerArea = () => {
    const areaData: DataPerArea[] = [];
    chartData.forEach(item => {
        const area = item.area;
        const existing = areaData.find(d => d.area === area);
        if (existing) {
            const itemDate = existing.values.find(v => v.date === item.data);
            const key = item.funcao.toLowerCase().replaceAll('â', 'a'); // normalize keys
            if (itemDate) {
                itemDate[key] = item.quantidade;
            } else {
                existing.values.push({ date: item.data, [key]: item.quantidade });
            }
        } else {
            const key = item.funcao.toLowerCase().replaceAll('â', 'a'); // normalize keys
            areaData.push({
                area: item.area,
                values: [{ date: item.data, [key]: item.quantidade }],
            });
        }
    });
    return areaData;
};


// ChartConfig for functions
// Colors comes from shadcn/tailwind profile
export const chartConfigPerDate = {
    caldeireiro: {
        label: "Caldeireiro",
        color: "var(--chart-1)",
    },
    eletricista: {
        label: "Eletricista",
        color: "var(--chart-2)",
    },
    mecanico: {
        label: "Mecânico",
        color: "var(--chart-3)",
    },
    operador: {
        label: "Operador",
        color: "var(--chart-4)",
    },
    pintor: {
        label: "Pintor",
        color: "var(--chart-5)",
    },
} satisfies ChartConfig

// ChartConfig for areas
export const chartConfigPerArea = {
    oficina_central: {
        label: "Oficina Central",
        color: "var(--chart-6)",
    },
    galpao_xyz: {
        label: "Galpão XYZ",
        color: "var(--chart-7)",
    },
    gaveteiro_de_andaimes: {
        label: "Gaveteiro de Andaimes",
        color: "var(--chart-8)",
    },
    bomba_178: {
        label: "Bomba 178",
        color: "var(--chart-9)",
    },
    tanques: {
        label: "Tanques",
        color: "var(--chart-10)",
    },

} satisfies ChartConfig

export const chartConfigTotal = 
{
    Total: {
        label: "Total de Funcionários",
        color: "var(--chart-1)",
    },
}

export const getAvgPositions = () => {
    const positions = AnexoI.areas as { nome: string, tipo: string, latitude: number, longitude: number }[];
    let totalLat = 0;
    let totalLng = 0;
    positions.forEach(pos => {
        totalLat += pos.latitude;
        totalLng += pos.longitude;
    });
    return [totalLat / positions.length, totalLng / positions.length] as [number, number];

}