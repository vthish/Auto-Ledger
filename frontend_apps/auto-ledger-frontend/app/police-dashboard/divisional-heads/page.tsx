// app/police-dashboard/divisional-heads/page.tsx
"use client";

import React, { useState } from 'react';
import { Users, PlusCircle, Trash2, Edit, Save, MapPin } from 'lucide-react';

export default function ManageHeads() {
  // DB eken ena Divisions list eka (Dropdown ekata)
  const availableDivisions = [
    { id: 'DIV-001', name: 'Colombo South' },
    { id: 'DIV-002', name: 'Galle' },
    { id: 'DIV-003', name: 'Kandy' },
  ];

  const [heads, setHeads] = useState([
    { id: 1, name: 'Ajith Rohana', badgeId: 'DIG-001', division: 'Colombo South', phone: '0712345678', email: 'ajith@police.lk' },
  ]);

  const [headForm, setHeadForm] = useState({ name: '', badgeId: '', division: '', phone: '', email: '' });
  const [editingId, setEditingId] = useState<number | null>(null);

  const handleHeadSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingId) {
      setHeads(heads.map(h => h.id === editingId ? { ...h, ...headForm } : h));
      setEditingId(null);
      alert("Divisional Head Successfully Updated!");
    } else {
      setHeads([...heads, { id: Date.now(), ...headForm }]);
      alert("Divisional Head Successfully Registered!");
    }
    setHeadForm({ name: '', badgeId: '', division: '', phone: '', email: '' });
  };

  const handleEdit = (head: any) => {
    setHeadForm({ name: head.name, badgeId: head.badgeId, division: head.division, phone: head.phone, email: head.email });
    setEditingId(head.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancelEdit = () => {
    setEditingId(null);
    setHeadForm({ name: '', badgeId: '', division: '', phone: '', email: '' });
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500">
      
      <form onSubmit={handleHeadSubmit} className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm">
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Users className="mr-2" size={18} /> {editingId ? 'Update Divisional Head' : 'Register Divisional Head'}
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Full Name <span className="text-red-500">*</span></label>
            <input required value={headForm.name} onChange={(e) => setHeadForm({...headForm, name: e.target.value})} type="text" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
          
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Badge / Police ID <span className="text-red-500">*</span></label>
            <input required value={headForm.badgeId} onChange={(e) => setHeadForm({...headForm, badgeId: e.target.value})} type="text" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>

          {/* UPDATE KARAPU DIVISION DROPDOWN EKA */}
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center">
              <MapPin size={12} className="mr-1 text-amber-500"/> Assigned Division <span className="text-red-500 ml-1">*</span>
            </label>
            <select 
              required 
              value={headForm.division} 
              onChange={(e) => setHeadForm({...headForm, division: e.target.value})} 
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white"
            >
              <option value="" disabled>-- Select a Division --</option>
              {availableDivisions.map(div => (
                <option key={div.id} value={div.name}>{div.name} ({div.id})</option>
              ))}
            </select>
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Contact Number <span className="text-red-500">*</span></label>
            <input required pattern="[0-9]{10}" title="10 digit mobile number" value={headForm.phone} onChange={(e) => setHeadForm({...headForm, phone: e.target.value})} type="tel" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" placeholder="07XXXXXXXX" />
          </div>
          
          <div className="space-y-2 col-span-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">Official Email <span className="text-red-500">*</span></label>
            <input required value={headForm.email} onChange={(e) => setHeadForm({...headForm, email: e.target.value})} type="email" className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white" />
          </div>
        </div>
        
        <div className="flex justify-end space-x-4 border-t border-[#1a2f5c] pt-6">
          {editingId && (
            <button type="button" onClick={handleCancelEdit} className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-[#132752] transition-all">Cancel</button>
          )}
          <button type="submit" className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-amber-900/40">
            {editingId ? <><Save size={18} className="mr-2" /> Update Head</> : <><PlusCircle size={18} className="mr-2" /> Register Head</>}
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr><th className="p-4">Badge ID</th><th className="p-4">Name</th><th className="p-4">Division</th><th className="p-4">Contact</th><th className="p-4 text-right">Actions</th></tr>
          </thead>
          <tbody className="divide-y divide-[#1a2f5c]">
            {heads.map(head => (
              <tr key={head.id} className="hover:bg-[#132752]/50 transition-all">
                <td className="p-4 font-mono font-bold text-amber-500">{head.badgeId}</td>
                <td className="p-4 font-bold text-white">{head.name}</td>
                <td className="p-4"><span className="bg-[#1a2f5c] px-2 py-1 rounded text-amber-400 text-xs border border-amber-500/20">{head.division}</span></td>
                <td className="p-4 text-slate-400">{head.phone}<br/>{head.email}</td>
                <td className="p-4 text-right space-x-2">
                  <button onClick={() => handleEdit(head)} className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg"><Edit size={16} /></button>
                  <button onClick={() => setHeads(heads.filter(h => h.id !== head.id))} className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg"><Trash2 size={16} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}