"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Car, ShieldCheck } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({ adminId: '', password: '', type: 'DMT' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await fetch('http://localhost:3000/auth/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });

      if (!response.ok) throw new Error('Invalid Credentials');

      const data = await response.json();
      
      // Token eka localStorage eke save kirima
      localStorage.setItem('accessToken', data.accessToken);
      localStorage.setItem('userRole', data.user.role);

      // Role eka anuwa dashboard ekata redirect kirima
      if (data.user.role === 'DMT_ADMIN') {
        router.push('/dmt-dashboard');
      } else {
        router.push('/police-dashboard');
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex h-screen bg-slate-900 items-center justify-center p-4">
      <div className="w-full max-w-md bg-slate-800 border border-slate-700 rounded-3xl p-8 shadow-2xl">
        <div className="flex flex-col items-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-br from-blue-600 to-cyan-500 rounded-2xl flex items-center justify-center mb-4">
            <Car size={32} className="text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">Auto-Ledger</h1>
          <p className="text-slate-400 text-sm">Admin Access Portal</p>
        </div>

        {error && <div className="bg-red-500/10 border border-red-500/50 text-red-400 p-3 rounded-xl mb-4 text-sm text-center">{error}</div>}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="text-xs text-slate-400 font-bold uppercase ml-1">Admin ID</label>
            <input 
              type="text" 
              required
              className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-white focus:border-cyan-500 outline-none"
              onChange={(e) => setFormData({...formData, adminId: e.target.value})}
            />
          </div>
          <div>
            <label className="text-xs text-slate-400 font-bold uppercase ml-1">Password</label>
            <input 
              type="password" 
              required
              className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-white focus:border-cyan-500 outline-none"
              onChange={(e) => setFormData({...formData, password: e.target.value})}
            />
          </div>
          <div>
            <label className="text-xs text-slate-400 font-bold uppercase ml-1">Admin Department</label>
            <select 
              className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-white focus:border-cyan-500 outline-none"
              onChange={(e) => setFormData({...formData, type: e.target.value})}
            >
              <option value="DMT">DMT (Motor Traffic)</option>
              <option value="POLICE">Sri Lanka Police</option>
            </select>
          </div>

          <button 
            type="submit" 
            disabled={loading}
            className="w-full bg-cyan-600 hover:bg-cyan-500 text-white font-bold py-3 rounded-xl transition-all flex justify-center items-center mt-6 disabled:opacity-50"
          >
            {loading ? 'Authenticating...' : <><ShieldCheck size={18} className="mr-2" /> Secure Login</>}
          </button>
        </form>
      </div>
    </div>
  );
}