'use client';

import React from 'react';
import { Home, Ticket, QrCode, Clock, User } from 'lucide-react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function BottomNav() {
    const pathname = usePathname();

    const navItems = [
        { label: 'Trang chủ', icon: Home, href: '/dashboard' },
        { label: 'Ưu đãi', icon: Ticket, href: '/dashboard/offers' },
        { label: 'QR', icon: QrCode, href: '/dashboard/scan', isCenter: true },
        { label: 'Lịch sử', icon: Clock, href: '/dashboard/history' },
        { label: 'Tôi', icon: User, href: '/dashboard/profile' },
    ];

    return (
        <div className="fixed bottom-0 left-0 right-0 z-50 px-6 pb-8 pointer-events-none">
            <div className="max-w-md mx-auto h-20 glass rounded-[32px] pointer-events-auto flex items-center justify-around px-2 relative">
                {navItems.map((item, index) => {
                    const isActive = pathname === item.href;
                    const Icon = item.icon;

                    if (item.isCenter) {
                        return (
                            <div key={index} className="relative -top-8 transition-transform hover:scale-110 active:scale-95 duration-300">
                                <div className="w-16 h-16 rounded-full bg-teal shadow-glow-teal flex items-center justify-center border-4 border-zinc-950">
                                    <Icon size={28} className="text-white" />
                                </div>
                            </div>
                        );
                    }

                    return (
                        <Link
                            key={index}
                            href={item.href}
                            className="flex flex-col items-center gap-1 group transition-all"
                        >
                            <div className={`
                p-2 rounded-xl transition-all duration-300
                group-hover:bg-teal/10 group-active:scale-90
              `}>
                                <Icon
                                    size={22}
                                    className={`transition-colors duration-300 ${isActive ? 'text-teal' : 'text-zinc-500 group-hover:text-zinc-300'}`}
                                />
                            </div>
                            <span className={`text-[10px] font-medium transition-colors ${isActive ? 'text-teal' : 'text-zinc-500'}`}>
                                {item.label}
                            </span>

                            {isActive && (
                                <div className="w-1 h-1 rounded-full bg-teal animate-pulse" />
                            )}
                        </Link>
                    );
                })}
            </div>
        </div>
    );
}
