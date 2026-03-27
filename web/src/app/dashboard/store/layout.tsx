'use client';

import { useAuth } from '@/context/AuthContext';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect } from 'react';
import Link from 'next/link';
import {
  LayoutDashboard,
  Package,
  Tags,
  BarChart3,
  Sparkles,
  LogOut,
  ChevronRight
} from 'lucide-react';

const navItems = [
  { href: '/dashboard/store', label: 'Tổng quan', icon: LayoutDashboard },
  { href: '/dashboard/store/inventory', label: 'Kho quà ảo', icon: Package },
  { href: '/dashboard/store/pricing', label: 'Giá & Hiệu ứng', icon: Tags },
  { href: '/dashboard/store/revenue', label: 'Doanh thu', icon: BarChart3 },
  { href: '/dashboard/store/combos', label: 'Gợi ý Combo', icon: Sparkles },
];

export default function StoreLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth() as any;
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
    if (!loading && user && user.role !== 'store_creator' && user.role !== 'admin') {
      router.push('/dashboard');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-zinc-950">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-emerald-500"></div>
      </div>
    );
  }

  if (!user) return null;

  return (
    <div className="min-h-screen bg-zinc-950 text-white flex">
      {/* Sidebar */}
      <aside className="w-64 bg-zinc-900/50 border-r border-white/5 flex flex-col fixed h-full backdrop-blur-xl z-30">
        <div className="p-6 border-b border-white/5">
          <h2 className="text-lg font-bold bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">
            🎁 Store Creator
          </h2>
          <p className="text-xs text-zinc-500 mt-1">{user.email || user.username}</p>
        </div>

        <nav className="flex-1 p-3 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 group ${
                  isActive
                    ? 'bg-emerald-500/15 text-emerald-400 shadow-lg shadow-emerald-500/5'
                    : 'text-zinc-400 hover:bg-white/5 hover:text-white'
                }`}
              >
                <Icon size={18} className={isActive ? 'text-emerald-400' : 'text-zinc-500 group-hover:text-zinc-300'} />
                <span>{item.label}</span>
                {isActive && <ChevronRight size={14} className="ml-auto text-emerald-500/50" />}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-white/5">
          <button
            onClick={() => {
              logout();
              router.push('/login');
            }}
            className="flex items-center gap-3 w-full px-4 py-3 rounded-xl text-sm text-zinc-400 hover:bg-red-500/10 hover:text-red-400 transition-all"
          >
            <LogOut size={18} />
            <span>Đăng xuất</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 ml-64 min-h-screen">
        <div className="p-8 max-w-7xl mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
