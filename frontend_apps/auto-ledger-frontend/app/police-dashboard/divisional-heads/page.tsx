"use client";

import React, { useEffect, useState } from "react";
import {
  Users,
  PlusCircle,
  MapPin,
  AlertCircle,
  CheckCircle2,
  X,
  Power,
  Eye,
  EyeOff,
} from "lucide-react";
import { api } from "@/lib/api";

interface DivisionalHeadInfo {
  divisional_Head_Id: string;
  name: string;
}

interface Division {
  division_Id: string;
  division_Name: string;
  divisionalHeads?: DivisionalHeadInfo[];
}

interface DivisionalHead {
  divisional_Head_Id: string;
  name: string;
  username: string;
  email: string;
  is_Active: boolean;
  division?: {
    division_Name: string;
  };
}

interface ApiError {
  response?: {
    data?: {
      message?: string;
    };
  };
}

export default function ManageHeads() {
  const [divisions, setDivisions] = useState<Division[]>([]);
  const [heads, setHeads] = useState<DivisionalHead[]>([]);
  const [headPasswords, setHeadPasswords] = useState<Record<string, string>>(
    {},
  );

  const [showPassword, setShowPassword] = useState(false);

  const [headForm, setHeadForm] = useState({
    name: "",
    divisionName: "",
    email: "",
    username: "",
    passwordStr: "",
  });

  const [toast, setToast] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  const showToast = (type: "success" | "error", message: string) => {
    setToast({ type, message });

    setTimeout(() => {
      setToast(null);
    }, 5000);
  };

  const loadData = async () => {
    try {
      const [divRes, headRes] = await Promise.all([
        api.get<Division[]>("/officers/divisions"),
        api.get<DivisionalHead[]>("/officers/divisional-heads"),
      ]);

      setDivisions(divRes.data);
      setHeads(headRes.data);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    async function fetchData() {
      await loadData();
    }

    void fetchData();
  }, []);

  const handleHeadSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const submittedUsername = headForm.username;
    const submittedPassword = headForm.passwordStr;

    try {
      await api.post("/officers/head", {
        divisionName: headForm.divisionName,
        username: submittedUsername,
        email: headForm.email,
        name: headForm.name,
        passwordStr: submittedPassword,
      });

      setHeadPasswords((currentPasswords) => ({
        ...currentPasswords,
        [submittedUsername]: submittedPassword,
      }));

      showToast(
        "success",
        "New Divisional Head registered and activated! Active Head replaced, unresolved tasks, active shifts and officers transferred automatically.",
      );

      setHeadForm({
        name: "",
        divisionName: "",
        email: "",
        username: "",
        passwordStr: "",
      });

      setShowPassword(false);

      await loadData();
    } catch (err: unknown) {
      const error = err as ApiError;

      showToast(
        "error",
        error.response?.data?.message || "Error registering head",
      );
    }
  };

  const handleToggleStatus = async (id: string, currentStatus: boolean) => {
    try {
      if (currentStatus) {
        if (
          !window.confirm(
            "Are you sure you want to disable this Divisional Head?",
          )
        ) {
          return;
        }

        await api.patch(`/officers/head/${id}/disable`);

        showToast("success", "Divisional Head disabled successfully.");
      } else {
        if (
          !window.confirm(
            "Activating this Head will automatically disable the currently active Head in this division. All traffic officers, unresolved fines, and active ongoing shifts will be transferred automatically, while future shifts will be canceled. Continue?",
          )
        ) {
          return;
        }

        await api.patch(`/officers/head/${id}/activate`);

        showToast(
          "success",
          "Divisional Head activated! All officers, unresolved tasks, and active shifts transferred to new DH.",
        );
      }

      await loadData();
    } catch (err: unknown) {
      const error = err as ApiError;

      showToast(
        "error",
        error.response?.data?.message || "Error updating status",
      );
    }
  };

  return (
    <div className="space-y-8 animate-in slide-in-from-right-8 duration-500 relative">
      {toast && (
        <div
          className={`fixed top-6 right-6 z-50 flex items-center p-4 rounded-2xl shadow-2xl border backdrop-blur-xl max-w-md ${
            toast.type === "error"
              ? "bg-red-950/90 border-red-500/50 text-red-200"
              : "bg-emerald-950/90 border-emerald-500/50 text-emerald-200"
          }`}
        >
          {toast.type === "error" ? (
            <AlertCircle
              className="text-red-400 mr-3 flex-shrink-0"
              size={20}
            />
          ) : (
            <CheckCircle2
              className="text-emerald-400 mr-3 flex-shrink-0"
              size={20}
            />
          )}

          <span className="text-xs font-bold tracking-wide leading-relaxed">
            {toast.message}
          </span>

          <button
            type="button"
            onClick={() => setToast(null)}
            className="ml-4 p-1 rounded-lg hover:bg-white/10 text-slate-400 hover:text-white"
          >
            <X size={14} />
          </button>
        </div>
      )}

      <form
        onSubmit={handleHeadSubmit}
        className="bg-[#0b1c3b]/60 p-8 rounded-3xl border border-[#1a2f5c] shadow-xl backdrop-blur-sm"
      >
        <h3 className="text-lg font-bold text-amber-500 mb-6 flex items-center">
          <Users className="mr-2" size={18} />
          Register Divisional Head
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Full Name *
            </label>

            <input
              required
              value={headForm.name}
              onChange={(e) =>
                setHeadForm({
                  ...headForm,
                  name: e.target.value,
                })
              }
              type="text"
              placeholder="e.g. SSP Anura Jayasinghe"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white"
            />
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase flex items-center">
              <MapPin size={12} className="mr-1 text-amber-500" />
              Assign to Division *
            </label>

            <select
              required
              value={headForm.divisionName}
              onChange={(e) =>
                setHeadForm({
                  ...headForm,
                  divisionName: e.target.value,
                })
              }
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white"
            >
              <option value="" disabled>
                -- Select a Division --
              </option>

              {divisions.map((div) => {
                const activeHead =
                  div.divisionalHeads && div.divisionalHeads.length > 0
                    ? div.divisionalHeads[0].name
                    : null;

                return (
                  <option
                    key={div.division_Id}
                    value={div.division_Name}
                    className="text-white bg-[#030508]"
                  >
                    {div.division_Name} ({div.division_Id}){" "}
                    {activeHead
                      ? ` - [ Current DH: ${activeHead} ]`
                      : " - [ Vacant ]"}
                  </option>
                );
              })}
            </select>
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Username *
            </label>

            <input
              required
              value={headForm.username}
              onChange={(e) =>
                setHeadForm({
                  ...headForm,
                  username: e.target.value,
                })
              }
              type="text"
              placeholder="Enter divisional head username"
              autoComplete="off"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white"
            />
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Password *
            </label>

            <div className="relative">
              <input
                required
                value={headForm.passwordStr}
                onChange={(e) =>
                  setHeadForm({
                    ...headForm,
                    passwordStr: e.target.value,
                  })
                }
                type={showPassword ? "text" : "password"}
                placeholder="Enter divisional head password"
                autoComplete="new-password"
                className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 pr-12 text-sm focus:border-amber-500 outline-none text-white"
              />

              <button
                type="button"
                onClick={() => setShowPassword((currentValue) => !currentValue)}
                className="absolute inset-y-0 right-0 flex items-center justify-center px-4 text-slate-400 hover:text-amber-500 transition-colors"
                aria-label={showPassword ? "Hide password" : "Show password"}
                title={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <div className="space-y-2 md:col-span-2">
            <label className="text-[11px] font-bold text-slate-400 uppercase">
              Official Email *
            </label>

            <input
              required
              value={headForm.email}
              onChange={(e) =>
                setHeadForm({
                  ...headForm,
                  email: e.target.value,
                })
              }
              type="email"
              placeholder="dh.colombo@police.lk"
              className="w-full bg-[#050d1a] border border-[#1a2f5c] rounded-xl p-3 text-sm focus:border-amber-500 outline-none text-white"
            />
          </div>
        </div>

        <div className="flex justify-end border-t border-[#1a2f5c] pt-6">
          <button
            type="submit"
            className="bg-amber-600 hover:bg-amber-500 text-white px-8 py-3 rounded-xl font-bold flex items-center shadow-lg shadow-amber-900/40 transition-all"
          >
            <PlusCircle size={18} className="mr-2" />
            Register & Activate Head
          </button>
        </div>
      </form>

      <div className="bg-[#0b1c3b]/60 border border-[#1a2f5c] rounded-3xl overflow-hidden backdrop-blur-xl shadow-xl">
        <table className="w-full text-left text-sm">
          <thead className="bg-[#050d1a] text-slate-400 text-xs uppercase tracking-widest">
            <tr>
              <th className="p-4">Name</th>
              <th className="p-4">Username</th>
              <th className="p-4">Password</th>
              <th className="p-4">Division</th>
              <th className="p-4">Status</th>
              <th className="p-4 text-center">Action</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-[#1a2f5c]">
            {heads.map((head) => (
              <tr
                key={head.divisional_Head_Id}
                className="hover:bg-[#132752]/50 transition-all"
              >
                <td className="p-4 font-bold text-white">{head.name}</td>

                <td className="p-4 font-mono font-bold text-blue-400">
                  {head.username}
                </td>

                <td className="p-4 font-mono font-bold text-amber-400">
                  {headPasswords[head.username] || "Not available"}
                </td>

                <td className="p-4">
                  <span className="bg-[#1a2f5c] px-2 py-1 rounded text-amber-400 text-xs border border-amber-500/20">
                    {head.division?.division_Name}
                  </span>
                </td>

                <td className="p-4">
                  {head.is_Active ? (
                    <span className="text-emerald-400 text-xs bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-1 rounded-md font-bold">
                      Active DH
                    </span>
                  ) : (
                    <span className="text-red-400 text-xs bg-red-500/10 border border-red-500/20 px-2.5 py-1 rounded-md font-bold">
                      Inactive / Inactive History
                    </span>
                  )}
                </td>

                <td className="p-4 text-center">
                  <button
                    type="button"
                    onClick={() =>
                      handleToggleStatus(
                        head.divisional_Head_Id,
                        head.is_Active,
                      )
                    }
                    className={`p-2 rounded-lg transition-colors ${
                      head.is_Active
                        ? "text-red-400 hover:bg-red-500/20 hover:text-red-300"
                        : "text-emerald-400 hover:bg-emerald-500/20 hover:text-emerald-300"
                    }`}
                    title={
                      head.is_Active
                        ? "Disable Head"
                        : "Activate Head & Transfer Resources"
                    }
                  >
                    <Power size={18} />
                  </button>
                </td>
              </tr>
            ))}

            {heads.length === 0 && (
              <tr>
                <td
                  colSpan={6}
                  className="p-8 text-center text-slate-500 font-bold uppercase text-xs"
                >
                  No divisional heads registered.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
