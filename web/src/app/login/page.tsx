'use client';

import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';

export default function LoginPage() {
    const [formData, setFormData] = useState({
        identifier: '',
        password: '',
    });
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { login } = useAuth();
    const router = useRouter();
    const searchParams = useSearchParams();
    const registered = searchParams.get('registered');

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await login(formData.identifier, formData.password);
            router.push('/dashboard');
        } catch (err) {
            setError(err.response?.data?.message || 'Thông tin đăng nhập không chính xác.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-zinc-950 px-4">
            <div className="w-full max-w-md p-8 space-y-8 bg-zinc-900/50 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl">
                <div className="text-center">
                    <h2 className="text-3xl font-bold text-white tracking-tight">Chào mừng quay lại</h2>
                    <p className="mt-2 text-zinc-400">Đăng nhập vào hệ thống Lucky Ly</p>
                </div>

                {registered && (
                    <div className="p-3 text-sm text-emerald-400 bg-emerald-400/10 border border-emerald-400/20 rounded-lg">
                        Đăng ký thành công! Hãy đăng nhập để bắt đầu.
                    </div>
                )}

                <form className="space-y-6" onSubmit={handleSubmit}>
                    {error && (
                        <div className="p-3 text-sm text-red-400 bg-red-400/10 border border-red-400/20 rounded-lg">
                            {error}
                        </div>
                    )}

                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-zinc-300 ml-1 mb-1.5">Username hoặc Email</label>
                            <input
                                name="identifier"
                                type="text"
                                required
                                className="w-full px-4 py-3 bg-zinc-800/50 border border-white/5 text-white rounded-xl focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 outline-none transition-all placeholder:text-zinc-600"
                                placeholder="example@gmail.com"
                                value={formData.identifier}
                                onChange={handleChange}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-300 ml-1 mb-1.5">Mật khẩu</label>
                            <input
                                name="password"
                                type="password"
                                required
                                className="w-full px-4 py-3 bg-zinc-800/50 border border-white/5 text-white rounded-xl focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 outline-none transition-all placeholder:text-zinc-600"
                                placeholder="••••••••"
                                value={formData.password}
                                onChange={handleChange}
                            />
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={isLoading}
                        className="w-full py-3 px-4 bg-emerald-600 hover:bg-emerald-500 text-white font-semibold rounded-xl shadow-lg shadow-emerald-600/20 active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {isLoading ? 'Đang xử lý...' : 'Đăng nhập'}
                    </button>
                </form>

                <p className="text-center text-zinc-500 text-sm">
                    Chưa có tài khoản?{' '}
                    <Link href="/register" className="text-emerald-400 hover:text-emerald-300 font-medium transition-colors">
                        Đăng ký ngay
                    </Link>
                </p>
            </div>
        </div>
    );
}
