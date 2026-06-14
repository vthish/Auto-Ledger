"use client";

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Users, Search, Eye, X, CreditCard, MapPin, Calendar, Droplet, Car, Bike, Truck, Bus, Tractor, Accessibility, Edit } from 'lucide-react';

export default function IssuedLicensesPage() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDriver, setSelectedDriver] = useState<any>(null);
  const [drivers, setDrivers] = useState<any[]>([]);

  const vehicleCategoriesList = [
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

  // Default initial data if LocalStorage is empty
  const defaultDrivers = [
    { 
      id: 1, fullName: 'Nimal Perera', userId: '851234567V', dob: '1985-05-12', bloodGroup: 'O+', address: '123 Galle Rd, Colombo 03', licenseNo: 'B5544123', issueDate: '2024-01-10', profilePic: 'https://i.pravatar.cc/150?u=nimal',
      categories: { 'A1': { checked: true, transmission: 'Manual', issue: '2024-01-10', expiry: '2032-01-10' }, 'B': { checked: true, transmission: 'Auto', issue: '2024-01-10', expiry: '2032-01-10' }, 'B2': { checked: true, transmission: 'Auto', issue: '2024-05-15', expiry: '2032-01-10' } }
    },
    { 
      id: 2, fullName: 'Kasun Silva', userId: '921234567V', dob: '1992-08-22', bloodGroup: 'A+', address: '45 Kandy Rd, Peradeniya', licenseNo: 'B5544456', issueDate: '2022-05-11', profilePic: 'https://i.pravatar.cc/150?u=kasun',
      categories: { 'A': { checked: true, transmission: 'Manual', issue: '2022-05-11', expiry: '2030-05-11' } }
    },
  ];

  useEffect(() => {
    const localData = localStorage.getItem('dmtDrivers');
    if (localData) {
      setDrivers(JSON.parse(localData));
    } else {
      setDrivers(defaultDrivers);
      localStorage.setItem('dmtDrivers', JSON.stringify(defaultDrivers));
    }
  }, []);

  const handleEditRedirect = (driver: any) => {
    localStorage.setItem('editDriver', JSON.stringify(driver));
    router.push('/dmt-dashboard/add-driver');
  };

  const filteredDrivers = drivers.filter(d => 
    d.userId.toLowerCase().includes(searchQuery.toLowerCase()) || 
    d.licenseNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
    d.fullName.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6 animate-in slide-in-from-right-8 duration-700 pb-10">
      <div className="bg-[#141414]/80 border border-red-900/20 rounded-3xl p-6 backdrop-blur-xl shadow-xl flex flex-col md:flex-row justify-between items-center gap-4">
        <div>
          <h3 className="text-xl font-bold text-white flex items-center"><Users className="mr-2 text-red-500" size={24} /> Issued Licenses Directory</h3>
          <p className="text-sm text-slate-400 mt-1">Search, view and edit driver records.</p>
        </div>
        <div className="relative w-full md:w-96">
          <Search className="absolute left-4 top-3 text-slate-400" size={18} />
          <input type="text" placeholder="Search by NIC, License No or Name..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full bg-[#0a0a0a] border border-red-900/30 rounded-xl py-3 pl-12 pr-4 text-sm focus:border-red-500 outline-none text-white placeholder-slate-500 transition-all"/>
        </div>
      </div>

      <div className="bg-[#141414]/80 border border-red-900/20 rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#0a0a0a] text-slate-400 text-xs uppercase tracking-widest border-b border-red-900/20">
            <tr>
              <th className="p-4">Driver Name</th>
              <th className="p-4">NIC</th>
              <th className="p-4">License No</th>
              <th className="p-4">Allowed Classes</th>
              <th className="p-4 text-center">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-red-900/10">
            {filteredDrivers.length > 0 ? filteredDrivers.map(driver => (
              <tr key={driver.id} className="hover:bg-[#1a0505] transition-all">
                <td className="p-4 font-bold text-white flex items-center">
                  {driver.profilePic ? (
                    <img src={driver.profilePic} alt={driver.fullName} className="w-8 h-8 rounded-full mr-3 object-cover border border-red-900/50" />
                  ) : (
                    <div className="w-8 h-8 rounded-full mr-3 bg-red-900/20 border border-red-500/30 flex items-center justify-center font-bold text-xs text-red-400">{driver.fullName.charAt(0)}</div>
                  )}
                  {driver.fullName}
                </td>
                <td className="p-4 text-slate-300">{driver.userId}</td>
                <td className="p-4 font-mono font-bold text-red-400">{driver.licenseNo}</td>
                <td className="p-4">
                  <div className="flex flex-wrap gap-1">
                    {Object.entries(driver.categories || {}).filter(([_, data]: any) => data.checked).map(([catClass]) => (
                      <span key={catClass} className="bg-red-900/30 text-red-400 px-2 py-0.5 rounded text-[10px] font-bold border border-red-500/20">{catClass}</span>
                    ))}
                  </div>
                </td>
                <td className="p-4 text-center flex justify-center space-x-2">
                  <button onClick={() => setSelectedDriver(driver)} className="bg-red-600/10 hover:bg-red-600 text-red-500 hover:text-white border border-red-500/20 hover:border-red-600 px-3 py-2 rounded-lg font-bold transition-all text-xs flex items-center">
                    <Eye size={14} className="mr-1" /> View
                  </button>
                  {/* EDIT BUTTON EKA METHANA THIYENAWA */}
                  <button onClick={() => handleEditRedirect(driver)} className="bg-blue-600/10 hover:bg-blue-600 text-blue-500 hover:text-white border border-blue-500/20 hover:border-blue-600 px-3 py-2 rounded-lg font-bold transition-all text-xs flex items-center">
                    <Edit size={14} className="mr-1" /> Edit
                  </button>
                </td>
              </tr>
            )) : (
              <tr><td colSpan={5} className="p-8 text-center text-slate-500">No records found.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {selectedDriver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-[#0a0a0a] border border-red-900/50 rounded-[32px] w-full max-w-4xl max-h-[90vh] overflow-y-auto shadow-2xl custom-scrollbar relative">
            
            <div className="sticky top-0 bg-[#0a0a0a]/90 backdrop-blur-md p-6 border-b border-red-900/30 flex justify-between items-center z-10">
              <h3 className="text-xl font-black text-white flex items-center"><CreditCard className="mr-3 text-red-500"/> Digital License Record: {selectedDriver.licenseNo}</h3>
              <button onClick={() => setSelectedDriver(null)} className="p-2 text-slate-400 hover:text-white bg-[#141414] rounded-full hover:bg-red-600 transition-colors"><X size={20}/></button>
            </div>

            <div className="p-8 space-y-8">
              <div className="bg-[#141414] border border-red-900/20 p-6 rounded-2xl flex flex-col md:flex-row gap-8 items-center md:items-start">
                {selectedDriver.profilePic ? (
                  <img src={selectedDriver.profilePic} alt={selectedDriver.fullName} className="w-36 h-44 object-cover rounded-xl border border-red-900/50 shadow-lg" />
                ) : (
                  <div className="w-36 h-44 bg-[#0a0a0a] rounded-xl border border-red-900/30 flex flex-col items-center justify-center text-slate-600 overflow-hidden relative">
                    <Users size={48} className="text-red-900/30" />
                    <span className="text-[9px] text-slate-500 font-bold uppercase mt-2">No Photo</span>
                  </div>
                )}
                
                <div className="flex-1 grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4 text-sm w-full">
                  <div className="sm:col-span-2 border-b border-red-900/10 pb-2">
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider">Full Name</p>
                    <p className="font-black text-white text-xl">{selectedDriver.fullName}</p>
                  </div>
                  <div>
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider">NIC Number</p>
                    <p className="font-bold text-slate-200 text-base">{selectedDriver.userId}</p>
                  </div>
                  <div>
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider">License Number</p>
                    <p className="font-mono font-black text-red-400 text-base">{selectedDriver.licenseNo}</p>
                  </div>
                  <div>
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider flex items-center"><Calendar size={12} className="mr-1 text-red-500"/> Date of Birth</p>
                    <p className="font-bold text-slate-200">{selectedDriver.dob}</p>
                  </div>
                  <div>
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider flex items-center"><Droplet size={12} className="mr-1 text-red-500"/> Blood Group</p>
                    <p className="font-bold text-red-500 bg-red-500/10 px-2 py-0.5 rounded border border-red-500/20 w-fit text-xs">{selectedDriver.bloodGroup}</p>
                  </div>
                  <div className="sm:col-span-2">
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider flex items-center"><Calendar size={12} className="mr-1 text-red-500"/> Initial Issue Date</p>
                    <p className="font-bold text-slate-200">{selectedDriver.issueDate}</p>
                  </div>
                  <div className="sm:col-span-2">
                    <p className="text-[10px] text-slate-500 uppercase font-bold tracking-wider flex items-center"><MapPin size={12} className="mr-1 text-red-500"/> Permanent Address</p>
                    <p className="font-bold text-slate-300">{selectedDriver.address}</p>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="text-sm font-bold text-slate-300 uppercase tracking-widest mb-4 border-b border-red-900/20 pb-2 flex items-center"><Car size={16} className="mr-2 text-red-500"/> Authorized Vehicle Categories (15 Classes)</h4>
                
                {/* 3 Items per row explicitly via lg:grid-cols-3 */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {vehicleCategoriesList.map((cat) => {
                    const catData = (selectedDriver.categories || {})[cat.class] || {};
                    const isAuthorized = catData.checked || false;
                    return (
                      <div key={cat.class} className={`border rounded-xl p-4 flex flex-col justify-between transition-all duration-300 ${isAuthorized ? 'bg-red-900/10 border-red-500/40 shadow-md shadow-red-950/20' : 'bg-[#0a0a0a]/30 border-slate-900/40 opacity-30'}`}>
                        <div className="flex justify-between items-start">
                          <div className="flex items-center">
                            <span className={`w-9 h-9 rounded-xl flex items-center justify-center border ${isAuthorized ? 'bg-red-500/20 text-red-400 border-red-500/30' : 'bg-[#141414] text-slate-600 border-transparent'}`}>{cat.icon}</span>
                            <div className="ml-3">
                              <span className="font-black text-base text-white block leading-tight">{cat.class}</span>
                              <span className="text-[10px] text-slate-500 block">{cat.desc}</span>
                            </div>
                          </div>
                          {isAuthorized ? (
                            <span className="text-[9px] bg-red-500/20 text-red-400 px-2 py-0.5 rounded border border-red-500/30 font-bold uppercase tracking-wider">{catData.transmission}</span>
                          ) : (
                            <span className="text-[9px] bg-slate-900 text-slate-600 px-2 py-0.5 rounded font-bold uppercase tracking-wider">None</span>
                          )}
                        </div>
                        {isAuthorized && (
                          <div className="grid grid-cols-2 gap-2 mt-4 pt-3 border-t border-red-900/20 text-[11px]">
                            <div>
                              <span className="text-slate-500 block text-[9px] uppercase font-bold">Issue Date</span>
                              <span className="text-slate-300 font-medium">{catData.issue}</span>
                            </div>
                            <div>
                              <span className="text-red-400/70 block text-[9px] uppercase font-bold">Expiry Date</span>
                              <span className="text-red-400 font-bold">{catData.expiry}</span>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

          </div>
        </div>
      )}
    </div>
  );
}