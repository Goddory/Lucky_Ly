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
        <div className="min-h-screen flex items-center justify-center bg-zinc-950 px-4 scroll-smooth">
            <div className="w-full max-w-sm p-8 space-y-10 glass rounded-[40px] relative overflow-hidden group">
                {/* Decorative background elements */}
                <div className="absolute top-[-50px] right-[-50px] w-32 h-32 bg-teal/10 blur-[80px] rounded-full" />
                <div className="absolute bottom-[-50px] left-[-50px] w-32 h-32 bg-gold/10 blur-[80px] rounded-full" />

                <div className="text-center relative z-10">
                    <div className="w-16 h-16 bg-teal shadow-glow-teal rounded-2xl flex items-center justify-center mx-auto mb-6 transform transition-transform group-hover:rotate-12 duration-500">
                        <span className="text-2xl font-bold text-white">L</span>
                    </div>
                    <h2 className="text-2xl font-bold text-white tracking-tight text-glow-teal uppercase">Lucky Ly</h2>
                    <p className="mt-2 text-zinc-500 text-sm">Chào mừng bạn gia nhập Lucky Ly Studio</p>
                </div>

                {registered && (
                    <div className="p-3 text-xs text-teal bg-teal/10 border border-teal/20 rounded-2xl animate-in fade-in slide-in-from-top-2">
                        Đăng ký thành công! Hãy đăng nhập để bắt đầu.
                    </div>
                )}

                <form className="space-y-6 relative z-10" onSubmit={handleSubmit}>
                    {error && (
                        <div className="p-3 text-xs text-red-festive bg-red-festive/10 border border-red-festive/20 rounded-2xl animate-shake">
                            {error}
                        </div>
                    )}

                    <div className="space-y-5">
                        <div className="group/field">
                            <label className="block text-[10px] font-bold text-zinc-500 uppercase tracking-widest ml-1 mb-2">Username / Email</label>
                            <input
                                name="identifier"
                                type="text"
                                required
                                className="w-full px-5 py-3 bg-white/5 border border-white/5 text-white rounded-2xl focus:bg-white/10 focus:border-teal/30 focus:shadow-glow-teal outline-none transition-all placeholder:text-zinc-700 text-sm"
                                placeholder="Tên đăng nhập hoặc email"
                                value={formData.identifier}
                                onChange={handleChange}
                            />
                        </div>

                        <div className="group/field">
                            <label className="block text-[10px] font-bold text-zinc-500 uppercase tracking-widest ml-1 mb-2">Mật khẩu</label>
                            <input
                                name="password"
                                type="password"
                                required
                                className="w-full px-5 py-3 bg-white/5 border border-white/5 text-white rounded-2xl focus:bg-white/10 focus:border-teal/30 focus:shadow-glow-teal outline-none transition-all placeholder:text-zinc-700 text-sm"
                                placeholder="••••••••"
                                value={formData.password}
                                onChange={handleChange}
                            />
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={isLoading}
                        className="w-full py-4 px-4 bg-teal hover:bg-[#00c5d1] text-white font-bold rounded-2xl shadow-glow-teal active:scale-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed text-sm tracking-widest"
                    >
                        {isLoading ? 'ĐANG XỬ LÝ...' : 'ĐĂNG NHẬP'}
                    </button>
                </form>

                <p className="text-center text-zinc-500 text-xs relative z-10 font-medium">
                    Chưa có tài khoản?{' '}
                    <Link href="/register" className="text-gold hover:text-white transition-colors">
                        Đăng ký ngay
                    </Link>
                </p>
            </div>
        </div>
    );
}
