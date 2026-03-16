'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import axios from 'axios';
import { 
    Users, 
    TrendingUp, 
    DollarSign, 
    Palette, 
    ChevronLeft, 
    BarChart3,
    Check
} from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

const themes = [
    { id: 'default', name: 'Mặc định', primary: '#0077B6', accent: '#E9C46A' },
    { id: 'tet', name: 'Tết Nguyên Đán', primary: '#D00000', accent: '#FFD700' },
    { id: 'summer', name: 'Mùa hè rực rỡ', primary: '#FFB703', accent: '#219EBC' },
    { id: 'moon', name: 'Trung thu', primary: '#023047', accent: '#FFB703' },
];

export default function AdminPage() {
    const { user, loading } = useAuth();
    const router = useRouter();
    const [stats, setStats] = useState(null);
    const [period, setPeriod] = useState('month');
    const [selectedTheme, setSelectedTheme] = useState('default');
    const [isUpdating, setIsUpdating] = useState(false);

    useEffect(() => {
        if (!loading && (!user || user.role !== 'ADMIN')) {
            router.push('/dashboard');
        }
    }, [user, loading, router]);

    useEffect(() => {
        if (user?.role === 'ADMIN') {
            fetchStats();
        }
    }, [user, period]);

    const fetchStats = async () => {
        try {
            const response = await axios.get(`${API_URL}/admin/stats?period=${period}`);
            setStats(response.data);
        } catch (error) {
            console.error('Failed to fetch stats', error);
        }
    };

    const handleThemeUpdate = async (theme) => {
        setIsUpdating(true);
        try {
            await axios.post(`${API_URL}/admin/theme`, theme);
            setSelectedTheme(theme.id);
            // In a real app, we might want to trigger a global refresh or use a ThemeContext
            alert('Đã cập nhật chủ đề hệ thống!');
        } catch (error) {
            alert('Lỗi khi cập nhật chủ đề');
        } finally {
            setIsUpdating(false);
        }
    };

    if (loading || !user || user.role !== 'ADMIN') {
        return <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-teal"></div>
        </div>;
    }

    return (
        <div className="min-h-screen bg-zinc-950 text-white pb-20">
            <div className="max-w-md mx-auto pt-12 px-6">
                <header className="flex items-center gap-4 mb-10">
                    <button 
                        onClick={() => router.push('/dashboard')}
                        className="p-2 bg-zinc-900 rounded-xl hover:bg-zinc-800 transition-all"
                    >
                        <ChevronLeft size={20} />
                    </button>
                    <h1 className="text-2xl font-bold tracking-tight">Admin Dashboard</h1>
                </header>

                <main className="space-y-8">
                    {/* Stats Section */}
                    <section className="space-y-4">
                        <div className="flex justify-between items-center">
                            <h2 className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Thống kê hệ thống</h2>
                            <select 
                                value={period}
                                onChange={(e) => setPeriod(e.target.value)}
                                className="bg-zinc-900 text-xs border-none rounded-lg px-2 py-1 focus:ring-1 focus:ring-teal"
                            >
                                <option value="day">Hôm nay</option>
                                <option value="month">Tháng này</option>
                                <option value="year">Năm này</option>
                            </select>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="glass p-5 rounded-3xl space-y-2">
                                <Users className="text-teal mb-2" size={20} />
                                <p className="text-2xl font-bold">{stats?.userCount || 0}</p>
                                <p className="text-[10px] text-zinc-500 uppercase font-medium">Người dùng mới</p>
                            </div>
                            <div className="glass p-5 rounded-3xl space-y-2">
                                <TrendingUp className="text-gold mb-2" size={20} />
                                <p className="text-2xl font-bold">{stats?.transactionCount || 0}</p>
                                <p className="text-[10px] text-zinc-500 uppercase font-medium">Giao dịch</p>
                            </div>
                        </div>

                        <div className="glass p-5 rounded-3xl flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <div className="w-10 h-10 rounded-2xl bg-teal/10 flex items-center justify-center">
                                    <DollarSign className="text-teal" size={20} />
                                </div>
                                <div>
                                    <p className="text-xl font-bold">{stats?.totalVolume?.toLocaleString('vi-VN')}đ</p>
                                    <p className="text-[10px] text-zinc-500 uppercase font-medium">Tổng doanh thu</p>
                                </div>
                            </div>
                            <BarChart3 className="text-zinc-800" size={32} />
                        </div>
                    </section>

                    {/* Theme Section */}
                    <section className="space-y-4">
                        <h2 className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Quản lý chủ đề</h2>
                        <div className="grid grid-cols-1 gap-3">
                            {themes.map((theme) => (
                                <button
                                    key={theme.id}
                                    onClick={() => handleThemeUpdate(theme)}
                                    disabled={isUpdating}
                                    className={`
                                        p-4 rounded-2xl border transition-all flex items-center justify-between
                                        ${selectedTheme === theme.id 
                                            ? 'bg-zinc-800 border-teal/50 shadow-glow-teal/10' 
                                            : 'bg-zinc-900/50 border-white/5 hover:border-white/10'}
                                    `}
                                >
                                    <div className="flex items-center gap-3">
                                        <div className="flex gap-1">
                                            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: theme.primary }} />
                                            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: theme.accent }} />
                                        </div>
                                        <span className="text-sm font-medium">{theme.name}</span>
                                    </div>
                                    {selectedTheme === theme.id && <Check size={16} className="text-teal" />}
                                </button>
                            ))}
                        </div>
                    </section>
                </main>
            </div>
        </div>
    );
}
