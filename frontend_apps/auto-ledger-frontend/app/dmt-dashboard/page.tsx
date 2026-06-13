"use client";

import React from 'react';
import { Users, CheckCircle, AlertTriangle } from 'lucide-react';

export default function DMTDashboard() {
  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard title="Total Registered" value="12,450" icon={<Users />} color="red" />
        <StatCard title="Active Licenses" value="11,890" icon={<CheckCircle />} color="rose" />
        <StatCard title="Suspended" value="560" icon={<AlertTriangle />} color="orange" />
      </div>

      <div className="bg-[#141414]/80 border border-red-900/20 rounded-3xl p-8 backdrop-blur-md shadow-2xl mt-8">
        <h3 className="text-xl font-bold text-white mb-6">Recent License Issuance</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="text-slate-500 text-xs uppercase tracking-widest border-b border-red-900/30">
              <tr>
                <th className="pb-4 px-2">Driver Name</th>
                <th className="pb-4 px-2">NIC Number</th>
                <th className="pb-4 px-2">License No</th>
                <th className="pb-4 px-2">Issue Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-red-900/10 text-sm">
              <tr className="hover:bg-white/5 transition-all"><td className="py-4 px-2 font-bold text-white">Nimal Perera</td><td className="py-4 px-2 text-slate-400">851234567V</td><td className="py-4 px-2 font-mono text-red-400">B5544123</td><td className="py-4 px-2 text-slate-400">2024-05-12</td></tr>
              <tr className="hover:bg-white/5 transition-all"><td className="py-4 px-2 font-bold text-white">Kasun Silva</td><td className="py-4 px-2 text-slate-400">921234567V</td><td className="py-4 px-2 font-mono text-red-400">B5544456</td><td className="py-4 px-2 text-slate-400">2024-05-11</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, icon, color }: any) {
  const colorMap: any = {
    red: 'from-red-600/20 to-red-900/10 border-red-500/30 text-red-500 bg-red-500/10',
    rose: 'from-rose-600/20 to-rose-900/10 border-rose-500/30 text-rose-500 bg-rose-500/10',
    orange: 'from-orange-600/20 to-orange-900/10 border-orange-500/30 text-orange-500 bg-orange-500/10'
  };
  return (
    <div className={`p-6 rounded-[24px] bg-gradient-to-br ${colorMap[color].split(' ')[0]} ${colorMap[color].split(' ')[1]} border ${colorMap[color].split(' ')[2]} backdrop-blur-md shadow-xl group hover:-translate-y-1 transition-all`}>
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center mb-4 ${colorMap[color].split(' ')[3]} ${colorMap[color].split(' ')[4]}`}>{icon}</div>
      <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-1">{title}</p>
      <p className="text-3xl font-black text-white">{value}</p>
    </div>
  );
}