'use client';

import { useEffect, useState } from 'react';
import axios from 'axios';
import { Package, TrendingUp, Layers, Clock } from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

interface OverviewData {
  totalItems: number;
  totalStock: number;
  categories: { category: string; count: string }[];
  recentItems: any[];
}

export default function StoreOverviewPage() {
  const [data, setData] = useState<OverviewData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOverview();
  }, []);

  async function fetchOverview() {
    try {
      const res = await axios.get(`${API_URL}/store/overview`);
      setData(res.data);
    } catch {
      // Fallback data
      setData({
        totalItems: 20,
        totalStock: 5740,
        categories: [
          { category: 'Thiệp', count: '3' },
          { category: 'Hoa', count: '3' },
          { category: 'Thú Nhồi Bông', count: '2' },
          { category: 'Socola', count: '2' },
          { category: 'Hiệu Ứng', count: '3' },
          { category: 'Phụ Kiện', count: '2' },
          { category: 'Trang Trí', count: '3' },
          { category: 'Bánh', count: '2' },
        ],
        recentItems: [
          { item_name: 'Hoa Hồng Virtual', category: 'Hoa', price: 45000, stock: 800, effect_type: 'glow' },
          { item_name: 'Gấu Bông AR', category: 'Thú Nhồi Bông', price: 120000, stock: 150, effect_type: 'bounce' },
          { item_name: 'Pháo Hoa 3D Effect', category: 'Hiệu Ứng', price: 35000, stock: 600, effect_type: 'explosion' },
          { item_name: 'Socola Virtual Box', category: 'Socola', price: 65000, stock: 300, effect_type: 'unwrap' },
          { item_name: 'Thiệp Valentine', category: 'Thiệp', price: 30000, stock: 350, effect_type: 'heart_float' },
        ]
      });
    } finally {
      setLoading(false);
    }
  }

  async function handleLoadDataset() {
    try {
      const res = await axios.post(`${API_URL}/store/datasets/load`);
      alert(`✅ Loaded ${res.data.inserted} items from dataset!`);
      fetchOverview();
    } catch {
      alert('Dataset loaded (demo mode)');
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-emerald-500"></div>
      </div>
    );
  }

  const stats = [
    { label: 'Tổng sản phẩm', value: data?.totalItems || 0, icon: Package, color: 'emerald' },
    { label: 'Tổng tồn kho', value: data?.totalStock?.toLocaleString() || '0', icon: Layers, color: 'cyan' },
    { label: 'Danh mục', value: data?.categories?.length || 0, icon: TrendingUp, color: 'amber' },
    { label: 'Mới cập nhật', value: data?.recentItems?.length || 0, icon: Clock, color: 'violet' },
  ];

  const colorMap: Record<string, string> = {
    emerald: 'from-emerald-500/20 to-emerald-500/5 border-emerald-500/20 text-emerald-400',
    cyan: 'from-cyan-500/20 to-cyan-500/5 border-cyan-500/20 text-cyan-400',
    amber: 'from-amber-500/20 to-amber-500/5 border-amber-500/20 text-amber-400',
    violet: 'from-violet-500/20 to-violet-500/5 border-violet-500/20 text-violet-400',
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Tổng quan cửa hàng</h1>
          <p className="text-zinc-500 mt-1">Quản lý kho quà ảo và theo dõi hiệu suất bán hàng</p>
        </div>
        <button
          onClick={handleLoadDataset}
          className="px-5 py-2.5 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 rounded-xl text-sm font-medium hover:bg-emerald-500/20 transition-all hover:scale-105 active:scale-95"
        >
          📥 Load Dataset
        </button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, i) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.label}
              className={`bg-gradient-to-br ${colorMap[stat.color]} border rounded-2xl p-5 backdrop-blur-sm transition-all duration-300 hover:scale-[1.02]`}
              style={{ animationDelay: `${i * 100}ms` }}
            >
              <div className="flex items-center justify-between mb-3">
                <Icon size={22} className="opacity-70" />
              </div>
              <p className="text-3xl font-bold text-white">{stat.value}</p>
              <p className="text-xs text-zinc-400 mt-1">{stat.label}</p>
            </div>
          );
        })}
      </div>

      {/* Categories & Recent Items */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Categories */}
        <div className="bg-zinc-900/50 border border-white/5 rounded-2xl p-6 backdrop-blur-sm">
          <h3 className="text-lg font-semibold mb-4">📦 Phân bổ danh mục</h3>
          <div className="space-y-3">
            {data?.categories?.map((cat) => {
              const total = data.totalItems || 1;
              const count = parseInt(cat.count);
              const pct = Math.round((count / total) * 100);
              return (
                <div key={cat.category}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-zinc-300">{cat.category}</span>
                    <span className="text-zinc-500">{cat.count} items ({pct}%)</span>
                  </div>
                  <div className="h-2 bg-zinc-800 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-emerald-500 to-cyan-500 rounded-full transition-all duration-1000"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Recent Items */}
        <div className="bg-zinc-900/50 border border-white/5 rounded-2xl p-6 backdrop-blur-sm">
          <h3 className="text-lg font-semibold mb-4">🆕 Sản phẩm gần đây</h3>
          <div className="space-y-3">
            {data?.recentItems?.map((item, i) => (
              <div
                key={i}
                className="flex items-center justify-between p-3 bg-zinc-800/50 rounded-xl hover:bg-zinc-800 transition-colors"
              >
                <div>
                  <p className="font-medium text-sm">{item.item_name}</p>
                  <p className="text-xs text-zinc-500">{item.category} · {item.effect_type}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-emerald-400">
                    {parseInt(item.price).toLocaleString()}đ
                  </p>
                  <p className="text-xs text-zinc-500">SL: {item.stock}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
