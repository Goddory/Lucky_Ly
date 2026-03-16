'use client';

import React from 'react';
import { Gift, Wallet, CreditCard, PiggyBank, Sparkles } from 'lucide-react';

interface WalletCardProps {
  title: string;
  balance: string;
  icon: React.ElementType;
  color: string;
  isSpecial?: boolean;
}

const WalletCard: React.FC<WalletCardProps> = ({ title, balance, icon: Icon, color, isSpecial }) => {
  return (
    <div className={`
      relative min-w-[160px] h-[100px] p-4 rounded-2xl flex flex-col justify-between
      transition-all duration-300 ease-out cursor-pointer
      hover:translate-y-[-6px] hover:scale-[1.03]
      ${isSpecial ? 'bg-gradient-to-br from-gold/20 to-teal/20 border-gold/30 shadow-glow-gold' : 'glass border-white/10'}
      group
    `}>
      <div className="flex justify-between items-start">
        <div className={`p-2 rounded-lg ${isSpecial ? 'bg-gold/20' : 'bg-teal/10'}`}>
          <Icon size={18} className={isSpecial ? 'text-gold' : 'text-teal'} />
        </div>
        {isSpecial && <Sparkles size={14} className="text-gold animate-pulse" />}
      </div>
      
      <div>
        <p className="text-[10px] uppercase tracking-wider text-zinc-400 group-hover:text-zinc-200 transition-colors">
          {title}
        </p>
        <p className={`text-sm font-bold truncate ${isSpecial ? 'text-gold' : 'text-white'}`}>
          {balance}
        </p>
      </div>

      {/* Hover Highlight Overlay */}
      <div className="absolute inset-0 rounded-2xl bg-white/5 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
    </div>
  );
};

export default function DashboardWallet() {
  const wallets = [
    { title: 'Ví Lucky Ly', balance: '1.250.000đ', icon: Wallet },
    { title: 'Ví Trả Sau', balance: '5.000.000đ', icon: CreditCard },
    { title: 'Túi Thần Tài', balance: '842.000đ', icon: PiggyBank },
    { title: 'Celebrate', balance: 'Sự kiện AR', icon: Gift, isSpecial: true },
  ];

  return (
    <div className="w-full">
      <h2 className="text-xs font-bold text-teal uppercase tracking-[0.2em] mb-4 px-1">
        Tài chính của tôi
      </h2>
      <div className="flex gap-4 overflow-x-auto pb-4 no-scrollbar scroll-smooth snap-x snap-mandatory">
        {wallets.map((wallet, index) => (
          <div key={index} className="snap-start">
            <WalletCard {...wallet} />
          </div>
        ))}
      </div>
    </div>
  );
}
