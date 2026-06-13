// app/police-dashboard/divisions/page.tsx
"use client";

import React, { useState } from 'react';
import { Map, PlusCircle, Trash2, Edit, Save } from 'lucide-react';

export default function ManageDivisions() {
  const [divisions, setDivisions] = useState([
    { id: 1, division_Id: 'DIV-001', division_Name: 'Colombo South' },
    { id: 2, division_Id: 'DIV-002', division_Name: 'Galle' },
  ]);

  const [divisionForm, setDivisionForm] = useState({ division_Id: '', division_Name: '' });
  const [editingId, setEditingId] = useState<number | null>(null);

  const handleDivisionSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingId) {
      setDivisions(divisions.map(d => d.id === editingId ? { ...d, ...divisionForm } : d));
      setEditingId(null);
      alert("Police Division Successfully Updated!");
    } else {
      setDivisions([...divisions, { id: Date.now(), ...divisionForm }]);
      alert("Police Division Successfully Registered!");
    }
    setDivisionForm({ division_Id: '', division_Name: '' });
  };

  const handleEdit = (division: any) => {
    setDivisionForm({ division_Id: division.division_Id, division_Name: division.division_Name });
    setEditingId(division.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setDivisionForm({ division_Id: '', division_Name: '' });
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500">
      
      {/* ADD / EDIT FORM */}
      <form onSubmit={handleDivisionSubmit} className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm">
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Map className="mr-2" size={18} /> {editingId ? 'Update Police Division' : 'Register New Police Division'}
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Division ID <span className="text-red-500">*</span></label>
            <input 
              required 
              value={divisionForm.division_Id} 
              onChange={(e) => setDivisionForm({...divisionForm, division_Id: e.target.value})} 
              type="text" 
              placeholder="e.g. DIV-001"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white font-mono" 
            />
          </div>
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Division Name <span className="text-red-500">*</span></label>
            <input 
              required 
              value={divisionForm.division_Name} 
              onChange={(e) => setDivisionForm({...divisionForm, division_Name: e.target.value})} 
              type="text" 
              placeholder="e.g. Colombo South"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" 
            />
          </div>
        </div>

        <div className="flex justify-end space-x-4 border-t border-[#1a2f5c] pt-6">
          {editingId && (
            <button type="button" onClick={handleCancelEdit} className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-[#132752] transition-all">Cancel</button>
          )}
          <button type="submit" className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-amber-900/40">
            {editingId ? <><Save size={18} className="mr-2" /> Update Division</> : <><PlusCircle size={18} className="mr-2" /> Register Division</>}
          </button>
        </div>
      </form>

      {/* DATA TABLE */}
      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th className="p-4">Division ID</th>
              <th className="p-4">Division Name</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {divisions.map(division => (
              <tr key={division.id} className="hover:bg-[#132752]/50 transition-all">
                <td className="p-4 font-mono font-bold text-amber-500">{division.division_Id}</td>
                <td className="p-4 font-bold text-white">{division.division_Name}</td>
                <td className="p-4 text-right space-x-2">
                  <button onClick={() => handleEdit(division)} className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg transition-colors"><Edit size={16} /></button>
                  <button onClick={() => setDivisions(divisions.filter(d => d.id !== division.id))} className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg transition-colors"><Trash2 size={16} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}