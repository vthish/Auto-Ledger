"use client";

import React, { useState } from 'react';
import { Users, CreditCard, ShieldCheck, Edit, Trash2, Save, X, Car, Bike, Truck, Bus, Tractor, Accessibility } from 'lucide-react';

export default function ManageLicensesPage() {
  const [drivers, setDrivers] = useState([
    { 
      id: 1, fullName: 'Nimal Perera', userId: '851234567V', dob: '1985-05-12', bloodGroup: 'O+', address: 'Colombo', licenseNo: 'B5544123', issueDate: '2024-01-10', expiryDate: '2032-01-10',
      categories: { 'A1': { checked: true, transmission: 'Manual', issue: '2024-01-10', expiry: '2032-01-10' }, 'B': { checked: true, transmission: 'Auto', issue: '2024-01-10', expiry: '2032-01-10' } }
    },
  ]);

  const [formData, setFormData] = useState({
    userId: '', fullName: '', dob: '', address: '', bloodGroup: 'O+', licenseNo: '', issueDate: '', expiryDate: '', categories: {} as any
  });
  
  const [editingId, setEditingId] = useState<number | null>(null);

  // Aluth Image ekata anuwa Categories 15 ma methana thiyenawa
  const vehicleCategories = [
    { class: 'A1', desc: 'Light Motor Cycles', icon: <Bike size={16}/> },
    { class: 'A', desc: 'Motor Cycles', icon: <Bike size={16}/> },
    { class: 'B1', desc: 'Motor Tricycles', icon: <Car size={16}/> },
    { class: 'B', desc: 'Dual Purpose Vehicles', icon: <Car size={16}/> },
    { class: 'B2', desc: 'Light Motor Vehicles', icon: <Car size={16}/> },
    { class: 'C1', desc: 'Light Motor Lorry', icon: <Truck size={16}/> },
    { class: 'C', desc: 'Motor Lorry', icon: <Truck size={16}/> },
    { class: 'CE', desc: 'Heavy Motor Lorry', icon: <Truck size={16}/> },
    { class: 'D1', desc: 'Light Motor Coach', icon: <Bus size={16}/> },
    { class: 'D', desc: 'Motor Coach', icon: <Bus size={16}/> },
    { class: 'DE', desc: 'Heavy Motor Coach', icon: <Bus size={16}/> },
    { class: 'G1', desc: 'Land Tractor', icon: <Tractor size={16}/> },
    { class: 'G', desc: 'Tractor with Trailer', icon: <Tractor size={16}/> },
    { class: 'J', desc: 'Special Purpose Vehicle', icon: <Truck size={16}/> },
    { class: 'H', desc: 'Invalid Carriages', icon: <Accessibility size={16}/> },
  ];

  const handleCategoryChange = (catClass: string, field: string, value: any) => {
    setFormData(prev => ({
      ...prev, categories: {
        ...prev.categories, [catClass]: { ...prev.categories[catClass], [field]: value }
      }
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingId) {
      setDrivers(drivers.map(d => d.id === editingId ? { ...d, ...formData } : d));
      alert("License Successfully Updated!");
      setEditingId(null);
    } else {
      setDrivers([...drivers, { id: Date.now(), ...formData }]);
      alert("License Successfully Issued!");
    }
    setFormData({ userId: '', fullName: '', dob: '', address: '', bloodGroup: 'O+', licenseNo: '', issueDate: '', expiryDate: '', categories: {} });
  };

  const handleEdit = (driver: any) => {
    setFormData({ 
      userId: driver.userId, fullName: driver.fullName, dob: driver.dob, address: driver.address, 
      bloodGroup: driver.bloodGroup, licenseNo: driver.licenseNo, issueDate: driver.issueDate, expiryDate: driver.expiryDate,
      categories: driver.categories || {} 
    });
    setEditingId(driver.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancel = () => {
    setEditingId(null);
    setFormData({ userId: '', fullName: '', dob: '', address: '', bloodGroup: 'O+', licenseNo: '', issueDate: '', expiryDate: '', categories: {} });
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-700 pb-10">
      
      {/* ADD / EDIT FORM */}
      <form onSubmit={handleSubmit} className="bg-[#141414]/80 p-8 rounded-[32px] border border-red-900/30 shadow-xl backdrop-blur-sm">
        <div className="flex justify-between items-center border-b border-red-900/30 pb-4 mb-6">
          <h3 className="text-xl font-bold text-red-500 flex items-center">
            <CreditCard className="mr-3" size={20} /> 
            {editingId ? 'Update Driver License' : 'Issue New Digital License'}
          </h3>
          {editingId && <button type="button" onClick={handleCancel} className="text-slate-400 hover:text-red-400 flex items-center text-sm font-bold bg-white/5 px-3 py-1.5 rounded-lg"><X size={16} className="mr-1"/> Cancel Edit</button>}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Section 1: Personal Info */}
          <div className="md:col-span-2 space-y-4">
            <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-2 flex items-center"><Users size={16} className="mr-2 text-red-500"/> Personal Details</h4>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1 col-span-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase">Full Name <span className="text-red-500">*</span></label>
                <input required value={formData.fullName} onChange={(e) => setFormData({...formData, fullName: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white" />
              </div>
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-slate-400 uppercase">NIC Number <span className="text-red-500">*</span></label>
                <input required value={formData.userId} onChange={(e) => setFormData({...formData, userId: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white" />
              </div>
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-slate-400 uppercase">Blood Group <span className="text-red-500">*</span></label>
                <select required value={formData.bloodGroup} onChange={(e) => setFormData({...formData, bloodGroup: e.target.value})} className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white">
                  <option>O+</option><option>O-</option><option>A+</option><option>A-</option><option>B+</option><option>B-</option><option>AB+</option><option>AB-</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-slate-400 uppercase">Date of Birth <span className="text-red-500">*</span></label>
                <input required value={formData.dob} onChange={(e) => setFormData({...formData, dob: e.target.value})} type="date" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-slate-300" />
              </div>
              <div className="space-y-1 col-span-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase">Address <span className="text-red-500">*</span></label>
                <input required value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white" />
              </div>
            </div>
          </div>

          {/* Section 2: License Info */}
          <div className="space-y-4">
            <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-2 flex items-center"><ShieldCheck size={16} className="mr-2 text-red-500"/> License Info</h4>
            <div className="space-y-4">
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-slate-400 uppercase">License Number <span className="text-red-500">*</span></label>
                <input required value={formData.licenseNo} onChange={(e) => setFormData({...formData, licenseNo: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm font-mono text-red-400 focus:border-red-500 outline-none" />
              </div>
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-slate-400 uppercase">Issue Date <span className="text-red-500">*</span></label>
                <input required value={formData.issueDate} onChange={(e) => setFormData({...formData, issueDate: e.target.value})} type="date" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-slate-300" />
              </div>
              <div className="space-y-1">
                <label className="text-[10px] font-bold text-slate-400 uppercase">Expiry Date <span className="text-red-500">*</span></label>
                <input required value={formData.expiryDate} onChange={(e) => setFormData({...formData, expiryDate: e.target.value})} type="date" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-slate-300" />
              </div>
            </div>
          </div>
        </div>

        {/* Section 3: Vehicle Categories (15 Categories) */}
        <div className="mt-8 pt-6 border-t border-red-900/30">
          <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-4 flex items-center"><Car size={16} className="mr-2 text-red-500"/> Allowed Vehicle Categories</h4>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {vehicleCategories.map((cat) => {
              const catData = formData.categories[cat.class] || {};
              const isChecked = catData.checked || false;
              return (
                <div key={cat.class} className={`border rounded-xl p-4 transition-all duration-300 ${isChecked ? 'bg-red-900/10 border-red-500/50' : 'bg-[#0a0a0a] border-red-900/30'}`}>
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <label className="flex items-center cursor-pointer group flex-1">
                      <input type="checkbox" checked={isChecked} onChange={(e) => handleCategoryChange(cat.class, 'checked', e.target.checked)} className="w-5 h-5 rounded border-red-900 text-red-500 bg-[#141414] focus:ring-red-500" />
                      <div className="ml-4 flex items-center">
                        <span className={`w-10 h-10 rounded-xl flex items-center justify-center border ${isChecked ? 'bg-red-500/20 text-red-400 border-red-500/30' : 'bg-[#141414] text-slate-400 border-red-900/30'}`}>{cat.icon}</span>
                        <div className="ml-3"><span className={`font-black text-lg ${isChecked ? 'text-white' : 'text-slate-300'}`}>{cat.class}</span><span className="block text-[11px] text-slate-400">{cat.desc}</span></div>
                      </div>
                    </label>
                    {isChecked && (
                      <select value={catData.transmission || 'Manual'} onChange={(e) => handleCategoryChange(cat.class, 'transmission', e.target.value)} className="bg-[#141414] border border-red-900/50 text-red-400 text-xs rounded-lg px-2 py-1.5 outline-none">
                        <option value="Manual">Manual</option><option value="Auto">Auto</option>
                      </select>
                    )}
                  </div>
                  {isChecked && (
                    <div className="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-red-900/30">
                      <div className="space-y-1"><label className="text-[10px] font-bold text-slate-400 uppercase">Issue Date</label><input required type="date" value={catData.issue || ''} onChange={(e) => handleCategoryChange(cat.class, 'issue', e.target.value)} className="w-full bg-[#0a0a0a] border border-red-900/50 rounded-lg px-2 py-1.5 text-xs text-slate-200 outline-none" /></div>
                      <div className="space-y-1"><label className="text-[10px] font-bold text-slate-400 uppercase">Expiry Date</label><input required type="date" value={catData.expiry || ''} onChange={(e) => handleCategoryChange(cat.class, 'expiry', e.target.value)} className="w-full bg-[#0a0a0a] border border-red-900/50 rounded-lg px-2 py-1.5 text-xs text-slate-200 outline-none" /></div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        <div className="flex justify-end pt-6 mt-6 border-t border-red-900/30">
          <button type="submit" className="bg-red-600 hover:bg-red-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-red-900/40">
            {editingId ? <><Save size={18} className="mr-2" /> Update License</> : <><ShieldCheck size={18} className="mr-2" /> Issue License</>}
          </button>
        </div>
      </form>

      {/* TABLE: Manage Licenses */}
      <div className="bg-[#141414]/80 border border-red-900/20 rounded-3xl overflow-hidden backdrop-blur-xl">
        <div className="p-6 border-b border-red-900/20 bg-black/20">
          <h3 className="text-lg font-bold text-white flex items-center"><Users className="mr-2 text-red-500" size={18} /> Issued Licenses Directory</h3>
        </div>
        <table className="w-full text-left text-sm">
          <thead className="bg-[#0a0a0a] text-slate-400 text-xs uppercase tracking-widest border-b border-red-900/20">
            <tr><th className="p-4">License No</th><th className="p-4">Driver Name</th><th className="p-4">NIC</th><th className="p-4">Classes</th><th className="p-4 text-right">Actions</th></tr>
          </thead>
          <tbody className="divide-y divide-red-900/10">
            {drivers.map(driver => (
              <tr key={driver.id} className="hover:bg-[#1a0505] transition-all">
                <td className="p-4 font-mono font-bold text-red-400">{driver.licenseNo}</td>
                <td className="p-4 font-bold text-white">{driver.fullName}</td>
                <td className="p-4 text-slate-300">{driver.userId}</td>
                <td className="p-4">
                  <div className="flex flex-wrap gap-1">
                    {Object.entries(driver.categories || {}).filter(([_, data]: any) => data.checked).map(([catClass]) => (
                      <span key={catClass} className="bg-red-900/30 text-red-400 px-2 py-0.5 rounded text-[10px] font-bold border border-red-500/20">{catClass}</span>
                    ))}
                  </div>
                </td>
                <td className="p-4 text-right space-x-2">
                  <button onClick={() => handleEdit(driver)} className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg transition-colors"><Edit size={16} /></button>
                  <button onClick={() => setDrivers(drivers.filter(d => d.id !== driver.id))} className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg transition-colors"><Trash2 size={16} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

    </div>
  );
}