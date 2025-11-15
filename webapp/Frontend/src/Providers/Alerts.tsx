import { createContext, useContext, useState, type ReactNode } from 'react';
import {
    AlertDialog,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogAction
} from "@/components/ui/alert-dialog"
import { toast } from 'sonner';

interface Alert {
    message: ReactNode;
    title: ReactNode;
    onResult?: (result: boolean) => void;
    buttons?: 'ok' | 'confirm-cancel' | 'yes-no' ;

}

type ToastTypes = 'success' | 'error' | 'info' | 'warning';

interface AlertContextProps {
    alert: Alert | null;
    showAlert: (message: ReactNode, title: ReactNode, onResult?: (result: boolean) => void, buttons?: Alert['buttons']) => void;
    clearAlert: () => void;
    useToast: (type: ToastTypes, message: string) => void;
}

const AlertContext = createContext<AlertContextProps | undefined>(undefined);

export const useAlert = () => {
    const context = useContext(AlertContext);
    if (!context) {
        throw new Error('useAlert must be used within an AlertProvider');
    }
    return context;
};

export const AlertProvider = ({ children }: { children: ReactNode }) => {
    const [alert, setAlert] = useState<Alert | null>(null);
    const [alertVisible, setAlertVisible] = useState<boolean>(false);
    const showAlert = (title: ReactNode, message: ReactNode, onResult?: (result: boolean) => void, buttons?: Alert['buttons']) => {
        setAlert({ message, title, onResult, buttons });
        setAlertVisible(true);
    };

    const clearAlert = () => {
        setAlert(null);
        setAlertVisible(false);
    };

    // const useToast = (type, message) => {
    //     const data = {

    //     }
    //     toast[type]?.(message, {
    //         duration: 4000,
    //         description: `${new Date().toLocaleTimeString()}`,
    //     });
    // }
    const useToast = (type: ToastTypes, message: string) => {
        toast[type]?.(message, {
            duration: 3000,
            description: `${new Date().toLocaleTimeString()}`,
        });
    }
    return (

        <AlertContext.Provider value={{ alert, showAlert, clearAlert, useToast }}>
            {children}
            <AlertDialog open={alertVisible} onOpenChange={(open) => {
                if (!open) {
                    clearAlert();
                }
            }} >
                <AlertDialogContent  className='z-100100'>
                    <AlertDialogHeader>
                        <AlertDialogTitle className='font-lato'> {alert?.title}</AlertDialogTitle>
                        <AlertDialogDescription asChild className='font-inter'>
                            {alert?.message}
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        {
                            alert?.buttons === 'ok' ? (
                                <AlertDialogAction onClick={() => {
                                    alert?.onResult?.(true);
                                    setAlertVisible(false);
                                }}>OK</AlertDialogAction>
                            ) : alert?.buttons === 'yes-no' ? (
                                <>
                                    <AlertDialogCancel className={'bg-red-500 dark:bg-[#8D0000] text-white'} onClick={() => {
                                        if (alert?.onResult) {
                                            alert?.onResult?.(false);
                                        }
                                        setAlertVisible(false);
                                    }}>No</AlertDialogCancel>  
                                    <AlertDialogAction onClick={() => {
                                        alert?.onResult?.(true);
                                        setAlertVisible(false);
                                    }}>Yes</AlertDialogAction>
                                </>
                            ) : (
                                <>
                                    <AlertDialogCancel onClick={() => {
                                        if (alert?.onResult) {
                                            alert?.onResult?.(false);
                                        }
                                        setAlertVisible(false);
                                    }} className='bg-red-500 dark:bg-[#8D0000] text-white'>Cancel</AlertDialogCancel>
                                    <AlertDialogAction onClick={() => {
                                        alert?.onResult?.(true);
                                    }} >Confirm</AlertDialogAction>
                                </>
                            )
                        }
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </AlertContext.Provider>
    );
};