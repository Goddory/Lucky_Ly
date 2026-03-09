'use client';

import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

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
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-emerald-500"></div>
            </div>
        );
    }

    if (!user) return null;

    return (
        <div className="min-h-screen bg-zinc-950 text-white p-8">
            <div className="max-w-4xl mx-auto">
                <header className="flex justify-between items-center mb-12">
                    <div>
                        <h1 className="text-4xl font-bold tracking-tight">Trang quản trị</h1>
                        <p className="text-zinc-400 mt-1">Chào mừng quay lại, {user.fullName}!</p>
                    </div>
                    <button
                        onClick={() => logout()}
                        className="px-4 py-2 bg-zinc-800 hover:bg-zinc-700 border border-white/5 rounded-lg transition-colors"
                    >
                        Đăng xuất
                    </button>
                </header>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="p-6 bg-zinc-900/50 border border-white/5 rounded-2xl">
                        <h3 className="text-lg font-semibold mb-2">Thông tin tài khoản</h3>
                        <div className="space-y-1 text-zinc-400">
                            <p>Username: {user.username}</p>
                            <p>Email: {user.email}</p>
                        </div>
                    </div>

                    <div className="p-6 bg-emerald-900/10 border border-emerald-500/20 rounded-2xl">
                        <h3 className="text-lg font-semibold text-emerald-400 mb-2">Trạng thái</h3>
                        <p className="text-zinc-400">Tài khoản của bạn đã được xác thực bảo mật thông qua JWT Cookie.</p>
                    </div>
                </div>
            </div>
        </div>
    );
}
