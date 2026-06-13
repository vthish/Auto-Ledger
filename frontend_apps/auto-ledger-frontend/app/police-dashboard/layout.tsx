// app/police-dashboard/layout.tsx
"use client";

import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { Shield, Gavel, Users, LogOut, Map } from 'lucide-react';

export default function PoliceLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();

  const handleLogout = () => {
    localStorage.clear();
    router.push('/login');
  };

  const getHeaderDetails = () => {
    if (pathname.includes('/fines')) return { title: 'Manage Fines', icon: <Gavel className="mr-3 text-amber-500" /> };
    if (pathname.includes('/divisional-heads')) return { title: 'Divisional Heads', icon: <Users className="mr-3 text-amber-500" /> };
    if (pathname.includes('/divisions')) return { title: 'Police Divisions', icon: <Map className="mr-3 text-amber-500" /> };
    return { title: 'Police Admin Dashboard', icon: <Shield className="mr-3 text-amber-500" /> };
  };

  const header = getHeaderDetails();

  return (
    <div className="flex h-screen bg-[#061022] text-slate-200 overflow-hidden font-sans relative">
      <div className="absolute inset-0 z-0 bg-gradient-to-br from-[#040b17] via-[#091730] to-[#040b17]"></div>

      {/* --- SIDEBAR --- */}
      <aside className="w-72 bg-[#091730]/90 backdrop-blur-xl border-r border-[#1a2f5c] flex flex-col p-6 m-4 rounded-3xl shadow-2xl z-10">
        <div className="mb-8 text-center flex flex-col items-center">
          <div className="w-24 h-28 mb-4 flex items-center justify-center drop-shadow-xl">
            <img src="/Sri_Lanka_Police_logo.png" alt="SL Police Logo" className="w-full h-full object-contain mix-blend-screen" />
          </div>
          <h1 className="text-xl font-black tracking-tight text-white">SRI LANKA POLICE</h1>
          <p className="text-[10px] text-amber-500 tracking-widest uppercase mt-1 font-bold">Traffic Administration</p>
        </div>

        <nav className="flex-1 space-y-2">
          <SidebarBtn to="/police-dashboard" icon={<Shield size={20} />} label="Overview" currentPath={pathname} />
          <SidebarBtn to="/police-dashboard/fines" icon={<Gavel size={20} />} label="Manage Fines" currentPath={pathname} />
          {/* New Divisions Menu */}
          <SidebarBtn to="/police-dashboard/divisions" icon={<Map size={20} />} label="Police Divisions" currentPath={pathname} />
          <SidebarBtn to="/police-dashboard/divisional-heads" icon={<Users size={20} />} label="Divisional Heads" currentPath={pathname} />
        </nav>

        <button onClick={handleLogout} className="flex items-center justify-center px-5 py-3 mt-auto bg-red-600/10 text-red-500 hover:bg-red-600/20 rounded-2xl transition-all border border-red-500/20 group">
          <LogOut size={18} className="mr-3 group-hover:-translate-x-1 transition-transform" /> 
          <span className="font-bold text-sm">Logout</span>
        </button>
      </aside>

      {/* --- MAIN CONTENT --- */}
      <main className="flex-1 flex flex-col p-8 overflow-y-auto z-10 custom-scrollbar">
        <header className="flex justify-between items-center mb-8 bg-[#0b1c3b]/60 backdrop-blur-md p-4 px-8 rounded-3xl border border-[#1a2f5c]">
          <div>
            <h2 className="text-2xl font-bold text-white capitalize flex items-center">
              {header.icon}
              {header.title}
            </h2>
          </div>
          <div className="flex items-center space-x-4">
             <div className="bg-[#132752] p-1.5 pr-5 rounded-full border border-amber-500/30 flex items-center space-x-3">
                <div className="w-9 h-9 rounded-full bg-amber-600 flex items-center justify-center font-bold text-white">PA</div>
                <span className="text-sm font-semibold text-amber-500">Police Admin</span>
             </div>
          </div>
        </header>
        {children}
      </main>

      <style dangerouslySetInnerHTML={{__html: `
        .custom-scrollbar::-webkit-scrollbar { width: 8px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: rgba(11, 28, 59, 0.5); }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(245, 158, 11, 0.3); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(245, 158, 11, 0.6); }
      `}} />
    </div>
  );
}

function SidebarBtn({ to, icon, label, currentPath }: { to: string, icon: any, label: string, currentPath: string }) {
  const isActive = currentPath === to;
  return (
    <Link href={to} className={`flex items-center w-full px-5 py-3.5 rounded-2xl transition-all duration-300 group text-sm ${isActive ? 'bg-amber-600 text-white shadow-lg shadow-amber-900/40 border border-amber-500' : 'hover:bg-[#132752] text-slate-300 hover:text-amber-400 border border-transparent'}`}>
      <span className={`mr-4 transition-transform duration-300 ${isActive ? 'text-white scale-110' : 'group-hover:scale-110'}`}>{icon}</span>
      <span className="font-bold tracking-wide">{label}</span>
    </Link>
  );
}