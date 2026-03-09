'use client';

import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function RegisterPage() {
    const [formData, setFormData] = useState({
        username: '',
        email: '',
        password: '',
        full_name: '',
    });
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { register } = useAuth();
    const router = useRouter();

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await register(formData);
            router.push('/login?registered=true');
        } catch (err) {
            setError(err.response?.data?.message || 'Có lỗi xảy ra khi đăng ký. Vui lòng thử lại.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-zinc-950 px-4">
            <div className="w-full max-w-md p-8 space-y-8 bg-zinc-900/50 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl">
                <div className="text-center">
                    <h2 className="text-3xl font-bold text-white tracking-tight">Tạo tài khoản</h2>
                    <p className="mt-2 text-zinc-400">Tham gia Lucky Ly ngay hôm nay</p>
                </div>

                <form className="space-y-6" onSubmit={handleSubmit}>
                    {error && (
                        <div className="p-3 text-sm text-red-400 bg-red-400/10 border border-red-400/20 rounded-lg">
                            {error}
                        </div>
                    )}

                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-zinc-300 ml-1 mb-1.5">Họ và tên</label>
                            <input
                                name="full_name"
                                type="text"
                                required
                                className="w-full px-4 py-3 bg-zinc-800/50 border border-white/5 text-white rounded-xl focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 outline-none transition-all placeholder:text-zinc-600"
                                placeholder="Nguyễn Văn A"
                                value={formData.full_name}
                                onChange={handleChange}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-300 ml-1 mb-1.5">Tên người dùng</label>
                            <input
                                name="username"
                                type="text"
                                required
                                className="w-full px-4 py-3 bg-zinc-800/50 border border-white/5 text-white rounded-xl focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 outline-none transition-all placeholder:text-zinc-600"
                                placeholder="username123"
                                value={formData.username}
                                onChange={handleChange}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-300 ml-1 mb-1.5">Email</label>
                            <input
                                name="email"
                                type="email"
                                required
                                className="w-full px-4 py-3 bg-zinc-800/50 border border-white/5 text-white rounded-xl focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 outline-none transition-all placeholder:text-zinc-600"
                                placeholder="example@gmail.com"
                                value={formData.email}
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
                        {isLoading ? 'Đang xử lý...' : 'Đăng ký ngay'}
                    </button>
                </form>

                <p className="text-center text-zinc-500 text-sm">
                    Đã có tài khoản?{' '}
                    <Link href="/login" className="text-emerald-400 hover:text-emerald-300 font-medium transition-colors">
                        Đăng nhập
                    </Link>
                </p>
            </div>
        </div>
    );
}
