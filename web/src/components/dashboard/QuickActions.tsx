'use client';

import React from 'react';
import { Gift, PenTool, LayoutGrid, Users, History, User } from 'lucide-react';
import Link from 'next/link';

interface ActionItemProps {
    label: string;
    icon: React.ElementType;
    color: string;
    onClick?: () => void;
    href?: string;
}

const ActionItem: React.FC<ActionItemProps> = ({ label, icon: Icon, color, href }) => {
    const content = (
        <div className="flex flex-col items-center gap-2 group cursor-pointer w-[80px] shrink-0">
            <div className={`
        w-14 h-14 rounded-2xl flex items-center justify-center
        transition-all duration-300 ease-out
        group-hover:scale-110 group-active:scale-95
        group-hover:translate-y-[-4px]
        ${color} glass border-white/5 group-hover:border-white/20
      `}>
                <Icon size={24} className="text-white group-hover:drop-shadow-[0_0_8px_rgba(255,255,255,0.5)] transition-all" />
            </div>
            <span className="text-[11px] font-medium text-zinc-400 group-hover:text-white transition-colors text-center">
                {label}
            </span>
        </div>
    );

    if (href) {
        return <Link href={href}>{content}</Link>;
    }

    return content;
};

export default function QuickActions() {
    const actions = [
        { label: 'Tặng Quà', icon: Gift, color: 'bg-red-500/10' },
        { label: 'Studio', icon: PenTool, color: 'bg-teal/10', href: '/dashboard/studio' },
        { label: 'Tiện ích', icon: LayoutGrid, color: 'bg-zinc-800/50' },
        { label: 'Bạn bè', icon: Users, color: 'bg-zinc-800/50' },
        { label: 'Lịch sử', icon: History, color: 'bg-zinc-800/50' },
        { label: 'Cá nhân', icon: User, color: 'bg-zinc-800/50' },
    ];

    return (
        <div className="w-full mt-8">
            <div className="flex gap-4 overflow-x-auto pb-6 no-scrollbar snap-x">
                {actions.map((action, index) => (
                    <div key={index} className="snap-start">
                        <ActionItem {...action} />
                    </div>
                ))}
            </div>
        </div>
    );
}
