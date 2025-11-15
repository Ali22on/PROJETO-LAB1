
import { createRoot } from 'react-dom/client'
import './index.css'
import "leaflet/dist/leaflet.css";
import { createBrowserRouter } from "react-router";
import { RouterProvider } from "react-router-dom";
import { AlertProvider } from './Providers/Alerts.tsx';
import { Toaster } from "@/components/ui/sonner"
import { TimerProvider } from './Providers/Timer.tsx';
import Home from './Pages/Home.tsx';
// import Admin from './Pages/admin.tsx';
const router = createBrowserRouter([
  
  {
    path: "*",
    element: <Home />,
  }


]);
createRoot(document.getElementById('root')!).render(

  <AlertProvider>
    
      <TimerProvider>
          <RouterProvider router={router} />
          <Toaster richColors closeButton />
      </TimerProvider>
    
  </AlertProvider>

)
