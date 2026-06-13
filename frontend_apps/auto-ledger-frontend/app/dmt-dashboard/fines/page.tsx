// app/dmt-dashboard/fines/page.tsx
"use client";

import React, { useState } from 'react';
import { FileWarning, Info, ShieldCheck } from 'lucide-react';

export default function DMTFinesViewPage() {
  // Real system eke meka API (NestJS Backend) eken Police add karapu details tikama auto fetch wela enawa.
  const [fines, setFines] = useState([
    { id: 1, code: 'SPD-01', name: 'Speeding over 70kmph', points: 4, amount: 3000, isCourtCase: false },
    { id: 2, code: 'DRK-02', name: 'Driving under influence', points: 10, amount: 25000, isCourtCase: true },
    { id: 3, code: 'LGN-03', name: 'Driving without a valid license', points: 6, amount: 10000, isCourtCase: true },
  ]);

  return (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-700 pb-10">
      
      {/* Sync Info Banner */}
      <div className="bg-blue-900/20 border border-blue-500/30 p-4 rounded-2xl flex items-start space-x-4 backdrop-blur-md">
        <Info className="text-blue-400 mt-0.5 flex-shrink-0" size={20} />
        <div>
          <h4 className="text-blue-400 font-bold text-sm">Synchronized with Sri Lanka Police</h4>
          <p className="text-blue-300/70 text-xs mt-1">
            This is a read-only view. The fines and demerit points listed below are actively managed and updated by the Sri Lanka Police Traffic Administration portal. Any updates made by the Police will automatically reflect here.
          </p>
        </div>
      </div>

      {/* Fines Table */}
      <div className="bg-[#141414]/80 border border-red-900/20 rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <div className="p-6 border-b border-red-900/20 bg-black/20 flex justify-between items-center">
          <h3 className="text-lg font-bold text-white flex items-center">
            <FileWarning className="mr-2 text-red-500" size={18} /> 
            Active Traffic Offenses & Demerit Points
          </h3>
          <span className="flex items-center text-[10px] font-bold uppercase tracking-widest text-emerald-400 bg-emerald-900/20 px-3 py-1.5 rounded-lg border border-emerald-500/20">
            <ShieldCheck size={14} className="mr-1" /> Live Synced
          </span>
        </div>
        
        <table className="w-full text-left text-sm">
          <thead className="bg-[#0a0a0a] text-slate-400 text-xs uppercase tracking-widest border-b border-red-900/20">
            <tr>
              <th className="p-4">Offense Code</th>
              <th className="p-4">Description</th>
              <th className="p-4">Demerit Points</th>
              <th className="p-4">Fine Amount (LKR)</th>
              <th className="p-4">Court Appearance</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-red-900/10">
            {fines.map(fine => (
              <tr key={fine.id} className="hover:bg-[#1a0505] transition-all">
                <td className="p-4 font-mono font-bold text-red-400">{fine.code}</td>
                <td className="p-4 font-bold text-white">{fine.name}</td>
                <td className="p-4">
                  <span className="bg-red-500/10 text-red-500 px-2 py-1 rounded border border-red-500/20 font-bold">
                    {fine.points} pts
                  </span>
                </td>
                <td className="p-4 font-bold text-slate-200">{fine.amount.toLocaleString()}</td>
                <td className="p-4">
                  {fine.isCourtCase ? 
                    <span className="text-rose-500 font-bold">Mandatory</span> : 
                    <span className="text-slate-400 font-bold">No</span>
                  }
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

    </div>
  );
}