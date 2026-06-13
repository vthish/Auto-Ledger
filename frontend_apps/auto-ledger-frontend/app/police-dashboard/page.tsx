"use client";

import React from 'react';
import { Gavel, Building, UserCheck } from 'lucide-react';

export default function PoliceOverview() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-in fade-in duration-500">
      <StatCard title="Total Offenses" value={24} icon={<Gavel />} color="amber" />
      <StatCard title="Divisional Heads" value={12} icon={<Building />} color="blue" />
      <StatCard title="Active Officers" value={156} icon={<UserCheck />} color="emerald" />
    </div>
  );
}

function StatCard({ title, value, icon, color }: any) {
  const colorMap: any = {
    amber: 'from-amber-600/20 to-orange-600/10 border-amber-500/30 text-amber-400 bg-amber-500/20',
    blue: 'from-blue-600/20 to-indigo-600/10 border-blue-500/30 text-blue-400 bg-blue-500/20',
    emerald: 'from-emerald-600/20 to-teal-600/10 border-emerald-500/30 text-emerald-400 bg-emerald-500/20'
  };
  return (
    <div className={`p-6 rounded-[24px] bg-gradient-to-br ${colorMap[color].split(' ')[0]} ${colorMap[color].split(' ')[1]} border ${colorMap[color].split(' ')[2]} backdrop-blur-md relative overflow-hidden group hover:-translate-y-1 transition-transform shadow-xl`}>
      <div className="flex justify-between items-start mb-4">
        <div className={`p-3 rounded-xl shadow-inner ${colorMap[color].split(' ')[4]} ${colorMap[color].split(' ')[3]}`}>{icon}</div>
      </div>
      <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-1">{title}</p>
      <p className="text-3xl font-black text-white">{value}</p>
    </div>
  );
}