'use client';

import React, { useState } from 'react';
import { User, Image as ImageIcon, Smile, Type } from 'lucide-react';

export default function StudioToolbar() {
    const [activeTab, setActiveTab] = useState('face');

    const tabs = [
        { id: 'face', label: 'Nhân vật', icon: User },
        { id: 'shell', label: 'Vỏ bao', icon: ImageIcon },
        { id: 'sticker', label: 'Sticker', icon: Smile },
        { id: 'text', label: 'Lời chúc', icon: Type },
    ];

    return (
        <div className="fixed bottom-0 left-0 right-0 z-50 px-4 pb-6 pointer-events-none">
            <div className="max-w-md mx-auto glass rounded-[32px] pointer-events-auto overflow-hidden">
                {/* Tab Content Placeholder */}
                <div className="h-24 px-6 flex items-center gap-4 overflow-x-auto no-scrollbar">
                    {[1, 2, 3, 4, 5, 6].map((i) => (
                        <div key={i} className="min-w-[56px] h-[56px] rounded-xl glass border-white/5 flex items-center justify-center hover:border-teal transition-all cursor-pointer group">
                            <div className="w-10 h-10 rounded-lg bg-zinc-800 group-hover:scale-110 transition-transform" />
                        </div>
                    ))}
                </div>

                {/* Navigation Tabs */}
                <div className="flex border-t border-white/5">
                    {tabs.map((tab) => {
                        const Icon = tab.icon;
                        const isActive = activeTab === tab.id;

                        return (
                            <button
                                key={tab.id}
                                onClick={() => setActiveTab(tab.id)}
                                className={`flex-1 py-4 flex flex-col items-center gap-1 transition-all ${isActive ? 'bg-white/5' : 'hover:bg-white/5'}`}
                            >
                                <Icon size={20} className={isActive ? 'text-teal' : 'text-zinc-500'} />
                                <span className={`text-[10px] font-medium ${isActive ? 'text-teal' : 'text-zinc-500'}`}>
                                    {tab.label}
                                </span>
                                {isActive && <div className="w-1 h-1 rounded-full bg-teal mt-1" />}
                            </button>
                        );
                    })}
                </div>
            </div>
        </div>
    );
}
