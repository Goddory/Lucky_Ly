'use client';

import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

import DashboardWallet from '@/components/dashboard/DashboardWallet';
import QuickActions from '@/components/dashboard/QuickActions';
import BottomNav from '@/components/layout/BottomNav';
import { User, Sparkles, ShieldCheck } from 'lucide-react';
import Link from 'next/link';

export default function DashboardPage() {
    const { user, loading, logout } = useAuth();
    const router = useRouter();

    useEffect(() => {
        if (!loading && !user) {
            router.push('/login');
        }
    }, [user, loading, router]);

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-zinc-950">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-teal"></div>
            </div>
        );
    }

    if (!user) return null;

    return (
        <div className="min-h-screen bg-zinc-950 text-white pb-32">
            <div className="max-w-md mx-auto pt-12 px-6">
                <header className="flex justify-between items-center mb-10">
                    <div>
                        <p className="text-zinc-500 text-sm font-medium">Chào buổi tối,</p>
                        <h1 className="text-2xl font-bold tracking-tight text-glow-teal">{user.fullName} 👋</h1>
                    </div>
                    <div className="flex items-center gap-2">
                        {user.role === 'ADMIN' && (
                            <Link
                                href="/admin"
                                className="p-2 bg-teal/10 border border-teal/20 rounded-full hover:bg-teal/20 transition-all group"
                                title="Admin Panel"
                            >
                                <ShieldCheck size={20} className="text-teal group-hover:scale-110 transition-transform" />
                            </Link>
                        )}
                        <button
                            onClick={() => logout()}
                            className="p-2 bg-zinc-900 border border-white/5 rounded-full hover:bg-zinc-800 transition-all hover:scale-105"
                            title="Đăng xuất"
                        >
                            <User size={20} className="text-zinc-400" />
                        </button>
                    </div>
                </header>

                <main className="space-y-8">
                    {/* Wallet Section */}
                    <div className="animate-in fade-in slide-in-from-bottom-4 duration-700 delay-100">
                        <DashboardWallet />
                    </div>

                    {/* Quick Actions Grid */}
                    <div className="animate-in fade-in slide-in-from-bottom-4 duration-700 delay-200">
                        <QuickActions />
                    </div>

                    {/* Promo Card Example */}
                    <div className="glass p-6 rounded-3xl relative overflow-hidden group cursor-pointer animate-in fade-in slide-in-from-bottom-4 duration-700 delay-300">
                        <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                            <Sparkles size={80} className="text-gold" />
                        </div>
                        <h3 className="text-lg font-bold mb-2">Sự kiện Tết Nguyên Đán</h3>
                        <p className="text-sm text-zinc-400 mb-4">Mở lì xì AR ngay - Nhận quà cực khủng!</p>
                        <button className="px-5 py-2 bg-white text-black text-xs font-bold rounded-full hover:bg-gold hover:text-white transition-all">
                            KHÁM PHÁ NGAY
                        </button>
                    </div>
                </main>
            </div>

            <BottomNav />
        </div>
    );
}
