'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ChevronLeft, Share2, Save, Loader2 } from 'lucide-react';
import Envelope3D from '@/components/studio/Envelope3D';
import StudioToolbar from '@/components/studio/StudioToolbar';
import * as designService from '@/services/designService';

export default function StudioPage() {
    const router = useRouter();
    const [isSaving, setIsSaving] = useState(false);
    const [designConfig, setDesignConfig] = useState({
        face_id: 'default',
        shell_id: 'red-festive',
        stickers: []
    });

    const handleSave = async () => {
        try {
            setIsSaving(true);
            await designService.saveDesign({
                name: 'My Custom Envelope',
                type: 'envelope',
                config: designConfig
            });
            alert('Đã lưu thiết kế thành công!');
        } catch (error) {
            console.error('Save failed:', error);
            alert('Không thể lưu thiết kế. Vui lòng thử lại.');
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="min-h-screen bg-zinc-950 text-white overflow-hidden flex flex-col">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 px-6 py-8 flex justify-between items-center bg-gradient-to-b from-zinc-950 to-transparent">
                <button
                    onClick={() => router.back()}
                    className="w-10 h-10 rounded-full glass flex items-center justify-center hover:bg-white/10 transition-all active:scale-95"
                >
                    <ChevronLeft size={20} />
                </button>

                <h1 className="text-sm font-bold tracking-[0.3em] uppercase text-zinc-400">
                    Studio <span className="text-teal">Sáng tạo</span>
                </h1>

                <div className="flex gap-2">
                    <button className="w-10 h-10 rounded-full glass flex items-center justify-center hover:bg-white/10 transition-all">
                        <Share2 size={18} />
                    </button>
                    <button
                        onClick={handleSave}
                        disabled={isSaving}
                        className="w-10 h-10 rounded-full glass border-teal/20 flex items-center justify-center hover:bg-teal/20 transition-all text-teal disabled:opacity-50"
                    >
                        {isSaving ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
                    </button>
                </div>
            </header>

            {/* Main Workspace */}
            <main className="flex-1 flex flex-col items-center justify-center pt-20 pb-40">
                <div className="w-full max-w-md px-6">
                    <Envelope3D />
                </div>
            </main>

            {/* Status Overlay */}
            <div className="fixed top-24 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full glass-dark border-teal/20 text-[10px] text-teal font-bold uppercase tracking-widest animate-pulse">
                Chế độ thiết kế 3D
            </div>

            <StudioToolbar />
        </div>
    );
}
