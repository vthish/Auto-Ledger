// app/dmt-dashboard/layout.tsx
"use client";

import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { LayoutDashboard, Users, UserPlus, LogOut, FileWarning } from 'lucide-react';

export default function DMTLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();

  const handleLogout = () => {
    localStorage.clear();
    router.push('/login');
  };

  const getHeaderDetails = () => {
    if (pathname.includes('/add-driver')) return { title: 'Issue & Manage Licenses', icon: <UserPlus className="mr-3 text-red-500" /> };
    if (pathname.includes('/drivers')) return { title: 'Driver Directory', icon: <Users className="mr-3 text-red-500" /> };
    if (pathname.includes('/fines')) return { title: 'Police Traffic Fines Database', icon: <FileWarning className="mr-3 text-red-500" /> };
    return { title: 'DMT Admin Dashboard', icon: <LayoutDashboard className="mr-3 text-red-500" /> };
  };

  const header = getHeaderDetails();

  return (
    <div className="flex h-screen bg-[#111111] text-slate-200 overflow-hidden font-sans relative">
      <div className="absolute inset-0 z-0 bg-gradient-to-br from-[#1a0505] via-[#0a0a0a] to-[#1a0505]"></div>

      {/* --- SIDEBAR --- */}
      <aside className="w-72 bg-[#141414]/90 backdrop-blur-xl border-r border-red-900/30 flex flex-col p-6 m-4 rounded-3xl shadow-2xl z-10">
        <div className="mb-8 text-center flex flex-col items-center">
          {/* DMT Logo */}
          <div className="w-24 h-24 mb-4 flex items-center justify-center rounded-full bg-white p-1 shadow-lg shadow-red-900/50">
            <img src="/dmt_logo.png" alt="DMT Logo" className="w-full h-full object-contain rounded-full" />
          </div>
          <h1 className="text-xl font-black tracking-tight text-white mt-2">DMT SRI LANKA</h1>
          <p className="text-[10px] text-red-500 tracking-widest uppercase mt-1 font-bold">License Administration</p>
        </div>

        <nav className="flex-1 space-y-2">
          <SidebarBtn to="/dmt-dashboard" icon={<LayoutDashboard size={20} />} label="Overview" currentPath={pathname} />
          <SidebarBtn to="/dmt-dashboard/add-driver" icon={<UserPlus size={20} />} label="Manage Licenses" currentPath={pathname} />
          {/* Aluth Fines View eka */}
          <SidebarBtn to="/dmt-dashboard/fines" icon={<FileWarning size={20} />} label="Traffic Fines" currentPath={pathname} />
        </nav>

        <button onClick={handleLogout} className="flex items-center justify-center px-5 py-3 mt-auto bg-red-600/10 text-red-500 hover:bg-red-600/20 rounded-2xl transition-all border border-red-500/20 group">
          <LogOut size={18} className="mr-3 group-hover:-translate-x-1 transition-transform" /> 
          <span className="font-bold text-sm">Logout</span>
        </button>
      </aside>

      {/* --- MAIN CONTENT --- */}
      <main className="flex-1 flex flex-col p-8 overflow-y-auto z-10 custom-scrollbar">
        <header className="flex justify-between items-center mb-8 bg-[#1a1a1a]/60 backdrop-blur-md p-4 px-8 rounded-3xl border border-red-900/20">
          <div>
            <h2 className="text-2xl font-bold text-white capitalize flex items-center">
              {header.icon}
              {header.title}
            </h2>
          </div>
          <div className="flex items-center space-x-4">
             <div className="bg-[#241010] p-1.5 pr-5 rounded-full border border-red-500/30 flex items-center space-x-3">
                <div className="w-9 h-9 rounded-full bg-red-600 flex items-center justify-center font-bold text-white">DA</div>
                <span className="text-sm font-semibold text-red-400">DMT Admin</span>
             </div>
          </div>
        </header>
        {children}
      </main>

      <style dangerouslySetInnerHTML={{__html: `
        .custom-scrollbar::-webkit-scrollbar { width: 8px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: rgba(20, 20, 20, 0.5); }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(220, 38, 38, 0.3); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(220, 38, 38, 0.6); }
      `}} />
    </div>
  );
}

function SidebarBtn({ to, icon, label, currentPath }: { to: string, icon: any, label: string, currentPath: string }) {
  const isActive = currentPath === to;
  return (
    <Link href={to} className={`flex items-center w-full px-5 py-3.5 rounded-2xl transition-all duration-300 group text-sm ${isActive ? 'bg-red-600 text-white shadow-lg shadow-red-900/40 border border-red-500' : 'hover:bg-[#1f1f1f] text-slate-400 hover:text-red-400 border border-transparent'}`}>
      <span className={`mr-4 transition-transform duration-300 ${isActive ? 'text-white scale-110' : 'group-hover:scale-110'}`}>{icon}</span>
      <span className="font-bold tracking-wide">{label}</span>
    </Link>
  );
}