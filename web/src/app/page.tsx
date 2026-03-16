'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';

export default function RootPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to dashboard as it's the main app interface now
    router.push('/dashboard');
  }, [router]);

  return (
    <div className="min-h-screen bg-zinc-950 flex flex-col items-center justify-center text-white">
      <div className="flex flex-col items-center gap-4 animate-in fade-in zoom-in duration-1000">
        <div className="w-16 h-16 rounded-3xl bg-teal shadow-glow-teal flex items-center justify-center animate-pulse">
          <span className="text-2xl font-bold">L</span>
        </div>
        <h1 className="text-xl font-medium tracking-[0.2em] uppercase text-zinc-500">Lucky Ly</h1>
        <Loader2 className="animate-spin text-teal/50 mt-4" size={24} />
      </div>
    </div>
  );
}
