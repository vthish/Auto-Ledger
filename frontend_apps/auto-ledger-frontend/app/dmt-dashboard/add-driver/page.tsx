"use client";

import React, { useState, useEffect } from 'react';
import { Users, CreditCard, ShieldCheck, Save, X, Car, Bike, Truck, Bus, Tractor, Accessibility, UploadCloud, RefreshCw } from 'lucide-react';

export default function ManageLicensesPage() {
  const [drivers, setDrivers] = useState<any[]>([]);
  const [editingId, setEditingId] = useState<number | null>(null);

  const [formData, setFormData] = useState({
    userId: '', fullName: '', dob: '', address: '', bloodGroup: 'O+', licenseNo: '', issueDate: '', profilePic: '', categories: {} as any
  });

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

  // Load Data and Check for "Edit" request
  useEffect(() => {
    const localDrivers = localStorage.getItem('dmtDrivers');
    if (localDrivers) setDrivers(JSON.parse(localDrivers));

    const editData = localStorage.getItem('editDriver');
    if (editData) {
      const driver = JSON.parse(editData);
      setFormData({ ...driver });
      setEditingId(driver.id);
      localStorage.removeItem('editDriver'); // Load wunata passe remove karanawa
    }
  }, []);

  const handleCategoryChange = (catClass: string, field: string, value: any) => {
    setFormData(prev => ({
      ...prev, categories: { ...prev.categories, [catClass]: { ...prev.categories[catClass], [field]: value } }
    }));
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFormData({ ...formData, profilePic: URL.createObjectURL(e.target.files[0]) });
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    let updatedDrivers;
    if (editingId) {
      updatedDrivers = drivers.map(d => d.id === editingId ? { ...formData, id: editingId } : d);
      alert("License Successfully Updated!");
    } else {
      updatedDrivers = [...drivers, { ...formData, id: Date.now() }];
      alert("Digital License Successfully Issued!");
    }
    
    setDrivers(updatedDrivers);
    localStorage.setItem('dmtDrivers', JSON.stringify(updatedDrivers)); // Save to local storage
    handleClear();
  };

  const handleClear = () => {
    setEditingId(null);
    setFormData({ userId: '', fullName: '', dob: '', address: '', bloodGroup: 'O+', licenseNo: '', issueDate: '', profilePic: '', categories: {} });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-700 pb-10">
      <form onSubmit={handleSubmit} className="bg-[#141414]/80 p-8 rounded-[32px] border border-red-900/30 shadow-xl backdrop-blur-sm">
        <div className="flex justify-between items-center border-b border-red-900/30 pb-4 mb-6">
          <h3 className="text-xl font-bold text-red-500 flex items-center">
            <CreditCard className="mr-3" size={20} /> 
            {editingId ? 'Update Driver License details' : 'Issue New Digital License'}
          </h3>
          {editingId && <button type="button" onClick={handleClear} className="text-slate-400 hover:text-red-400 flex items-center text-sm font-bold bg-white/5 px-3 py-1.5 rounded-lg"><X size={16} className="mr-1"/> Cancel Edit</button>}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <div className="flex flex-col items-center space-y-4">
            <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest"><Users size={16} className="inline mr-2 text-red-500"/> Photograph</h4>
            <label className="w-40 h-48 border-2 border-dashed border-red-900/50 rounded-2xl flex flex-col items-center justify-center bg-[#0a0a0a] hover:bg-red-900/10 transition-colors cursor-pointer overflow-hidden group">
              <input type="file" accept="image/*" className="hidden" onChange={handleImageUpload} />
              {formData.profilePic ? (
                <img src={formData.profilePic} alt="Profile" className="w-full h-full object-cover" />
              ) : (
                <>
                  <UploadCloud size={32} className="text-red-500 mb-2 group-hover:scale-110 transition-transform" />
                  <span className="text-[10px] text-slate-400 font-bold uppercase text-center px-4">Upload Professional Photo</span>
                </>
              )}
            </label>
          </div>

          <div className="lg:col-span-3 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4 md:col-span-2">
              <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-2 border-b border-red-900/20 pb-2">Driver Details</h4>
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-slate-400 uppercase">Full Name <span className="text-red-500">*</span></label>
              <input required value={formData.fullName} onChange={(e) => setFormData({...formData, fullName: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white" />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-slate-400 uppercase">NIC Number <span className="text-red-500">*</span></label>
              <input required value={formData.userId} onChange={(e) => setFormData({...formData, userId: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white" />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-slate-400 uppercase">Date of Birth <span className="text-red-500">*</span></label>
              <input required value={formData.dob} onChange={(e) => setFormData({...formData, dob: e.target.value})} type="date" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-slate-300 [color-scheme:dark]" />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-slate-400 uppercase">Blood Group <span className="text-red-500">*</span></label>
              <select required value={formData.bloodGroup} onChange={(e) => setFormData({...formData, bloodGroup: e.target.value})} className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white">
                <option>O+</option><option>O-</option><option>A+</option><option>A-</option><option>B+</option><option>B-</option><option>AB+</option><option>AB-</option>
              </select>
            </div>
            <div className="space-y-1 md:col-span-2">
              <label className="text-[10px] font-bold text-slate-400 uppercase">Address <span className="text-red-500">*</span></label>
              <input required value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-white" />
            </div>

            <div className="space-y-4 md:col-span-2 mt-4">
              <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-2 border-b border-red-900/20 pb-2 flex items-center"><ShieldCheck size={16} className="mr-2 text-red-500"/> General License Info</h4>
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-slate-400 uppercase">License Number <span className="text-red-500">*</span></label>
              <input required value={formData.licenseNo} onChange={(e) => setFormData({...formData, licenseNo: e.target.value})} type="text" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm font-mono text-red-400 focus:border-red-500 outline-none" />
            </div>
            <div className="space-y-1">
              <label className="text-[10px] font-bold text-slate-400 uppercase">Initial Issue Date <span className="text-red-500">*</span></label>
              <input required value={formData.issueDate} onChange={(e) => setFormData({...formData, issueDate: e.target.value})} type="date" className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl p-3 text-sm focus:border-red-500 outline-none text-slate-300 [color-scheme:dark]" />
            </div>
          </div>
        </div>

        {/* Section 3: Vehicle Categories (Exact 3 items per row on large screens: lg:grid-cols-3) */}
        <div className="mt-8 pt-6 border-t border-red-900/30">
          <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-4 flex items-center"><Car size={16} className="mr-2 text-red-500"/> Allowed Vehicle Categories</h4>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
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
                      <div className="space-y-1"><label className="text-[10px] font-bold text-slate-400 uppercase">Issue Date</label><input required type="date" value={catData.issue || ''} onChange={(e) => handleCategoryChange(cat.class, 'issue', e.target.value)} className="w-full bg-[#0a0a0a] border border-red-900/50 rounded-lg px-2 py-1.5 text-xs text-slate-200 outline-none [color-scheme:dark]" /></div>
                      <div className="space-y-1"><label className="text-[10px] font-bold text-slate-400 uppercase">Expiry Date</label><input required type="date" value={catData.expiry || ''} onChange={(e) => handleCategoryChange(cat.class, 'expiry', e.target.value)} className="w-full bg-[#0a0a0a] border border-red-900/50 rounded-lg px-2 py-1.5 text-xs text-slate-200 outline-none [color-scheme:dark]" /></div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        <div className="flex justify-end space-x-4 pt-6 mt-6 border-t border-red-900/30">
          <button type="button" onClick={handleClear} className="px-6 py-3 rounded-xl font-bold text-sm text-slate-400 hover:text-white hover:bg-slate-800 transition-all flex items-center">
            <RefreshCw size={16} className="mr-2"/> Clear Form
          </button>
          <button type="submit" className="bg-red-600 hover:bg-red-500 text-white px-8 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-red-900/40">
            <ShieldCheck size={18} className="mr-2" /> {editingId ? 'Save Changes' : 'Issue Digital License'}
          </button>
        </div>
      </form>
    </div>
  );
}