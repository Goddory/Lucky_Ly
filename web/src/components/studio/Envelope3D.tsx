'use client';

import React, { useState } from 'react';

export default function Envelope3D() {
    const [rotation, setRotation] = useState({ x: 0, y: 0 });
    const [isDragging, setIsDragging] = useState(false);
    const [lastPos, setLastPos] = useState({ x: 0, y: 0 });

    const handlePointerDown = (e: React.PointerEvent) => {
        setIsDragging(true);
        setLastPos({ x: e.clientX, y: e.clientY });
    };

    const handlePointerMove = (e: React.PointerEvent) => {
        if (!isDragging) return;
        const deltaX = e.clientX - lastPos.x;
        const deltaY = e.clientY - lastPos.y;

        setRotation(prev => ({
            x: prev.x - deltaY * 0.5,
            y: prev.y + deltaX * 0.5
        }));
        setLastPos({ x: e.clientX, y: e.clientY });
    };

    const handlePointerUp = () => {
        setIsDragging(false);
    };

    return (
        <div
            className="w-full h-[400px] flex items-center justify-center perspective-1000 cursor-grab active:cursor-grabbing"
            onPointerDown={handlePointerDown}
            onPointerMove={handlePointerMove}
            onPointerUp={handlePointerUp}
            onPointerLeave={handlePointerUp}
        >
            <div
                className="relative w-64 h-80 preserve-3d transition-transform duration-100 ease-out"
                style={{ transform: `rotateX(${rotation.x}deg) rotateY(${rotation.y}deg)` }}
            >
                {/* Front Face */}
                <div className="absolute inset-0 bg-red-festive rounded-2xl border-2 border-gold/30 flex flex-col items-center justify-center backface-hidden shadow-2xl">
                    <div className="w-24 h-24 rounded-full border-4 border-gold/50 flex items-center justify-center bg-gold/10 overflow-hidden mb-4">
                        {/* Character/Face Placeholder */}
                        <div className="w-full h-full bg-gradient-to-tr from-gold/40 to-white/20 animate-pulse" />
                    </div>
                    <div className="text-gold font-bold text-xl tracking-widest">LUCKY LY</div>
                    <div className="mt-4 text-gold/80 text-[10px] uppercase font-medium">Chúc Mừng Năm Mới</div>

                    {/* Decorative Corner */}
                    <div className="absolute top-2 left-2 w-8 h-8 border-t-2 border-l-2 border-gold/40" />
                    <div className="absolute bottom-2 right-2 w-8 h-8 border-b-2 border-r-2 border-gold/40" />
                </div>

                {/* Back Face */}
                <div className="absolute inset-0 bg-red-festive rounded-2xl border-2 border-gold/30 flex flex-col items-center justify-center backface-hidden shadow-2xl [transform:rotateY(180deg)]">
                    <div className="w-12 h-12 rounded-full bg-gold/20 flex items-center justify-center border border-gold/40 mb-2">
                        <div className="w-6 h-1 bg-gold rounded-full" />
                    </div>
                    <div className="text-gold/60 text-[8px] uppercase tracking-tighter italic px-4 text-center">
                        Bản quyền thiết kế bởi Lucky Ly Studio
                    </div>
                </div>

                {/* Side Edges (Mocking thickness) */}
                <div className="absolute top-0 bottom-0 left-[-1px] w-[2px] bg-red-800 [transform:rotateY(-90deg)]" />
                <div className="absolute top-0 bottom-0 right-[-1px] w-[2px] bg-red-800 [transform:rotateY(90deg)]" />
            </div>

            {/* Control Hint */}
            <div className="absolute bottom-4 left-1/2 -translate-x-1/2 text-[10px] text-zinc-500 uppercase tracking-widest animate-bounce">
                Vuốt để xoay 360°
            </div>
        </div>
    );
}
