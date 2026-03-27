'use client';

import { useEffect, useState } from 'react';
import axios from 'axios';
import {
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import { TrendingUp, DollarSign, ShoppingCart, Activity } from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

const COLORS = ['#10b981', '#06b6d4', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316'];

// Demo data khi API chưa sẵn sàng
const DEMO_DAILY = [
  { date: '01/03', revenue: 450000, orders: 12 },
  { date: '05/03', revenue: 680000, orders: 18 },
  { date: '08/03', revenue: 920000, orders: 25 },
  { date: '10/03', revenue: 780000, orders: 21 },
  { date: '12/03', revenue: 1150000, orders: 32 },
  { date: '15/03', revenue: 890000, orders: 24 },
  { date: '18/03', revenue: 1250000, orders: 35 },
  { date: '20/03', revenue: 1050000, orders: 28 },
  { date: '22/03', revenue: 1380000, orders: 38 },
  { date: '25/03', revenue: 1520000, orders: 42 },
];

const DEMO_TOP_PRODUCTS = [
  { item_name: 'Hoa Hồng Virtual', sold_count: 672, price: 45000 },
  { item_name: 'Pháo Hoa 3D', sold_count: 478, price: 35000 },
  { item_name: 'Bóng Bay Virtual', sold_count: 456, price: 15000 },
  { item_name: 'Thiệp Sinh Nhật', sold_count: 387, price: 25000 },
  { item_name: 'Thiệp Tết', sold_count: 356, price: 35000 },
];

const DEMO_CATEGORIES = [
  { category: 'Thiệp', item_count: 3, potential_revenue: 31075000 },
  { category: 'Hoa', item_count: 3, potential_revenue: 46730000 },
  { category: 'Hiệu Ứng', item_count: 3, potential_revenue: 31965000 },
  { category: 'Trang Trí', item_count: 3, potential_revenue: 24920000 },
  { category: 'Thú Nhồi Bông', item_count: 2, potential_revenue: 19805000 },
  { category: 'Socola', item_count: 2, potential_revenue: 27315000 },
  { category: 'Phụ Kiện', item_count: 2, potential_revenue: 9525000 },
  { category: 'Bánh', item_count: 2, potential_revenue: 17805000 },
];

export default function RevenuePage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => { fetchRevenue(); }, []);

  async function fetchRevenue() {
    try {
      const res = await axios.get(`${API_URL}/store/revenue`);
      setData(res.data);
    } catch {
      setData({
        summary: { total_revenue: 10820000, total_orders: 275 },
        daily: DEMO_DAILY,
        topProducts: DEMO_TOP_PRODUCTS,
        categoryBreakdown: DEMO_CATEGORIES,
      });
    } finally { setLoading(false); }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-emerald-500"></div>
      </div>
    );
  }

  const totalRevenue = Number(data?.summary?.total_revenue || 0);
  const totalOrders = Number(data?.summary?.total_orders || 0);
  const avgValue = totalOrders > 0 ? Math.round(totalRevenue / totalOrders) : 0;

  const kpiCards = [
    { label: 'Tổng doanh thu', value: `${(totalRevenue / 1000000).toFixed(1)}M đ`, icon: DollarSign, color: 'emerald' },
    { label: 'Tổng đơn hàng', value: totalOrders.toLocaleString(), icon: ShoppingCart, color: 'cyan' },
    { label: 'Giá trị TB/đơn', value: `${avgValue.toLocaleString()}đ`, icon: Activity, color: 'amber' },
    { label: 'Tăng trưởng', value: '+23%', icon: TrendingUp, color: 'emerald' },
  ];

  const colorMap: Record<string, string> = {
    emerald: 'from-emerald-500/20 to-emerald-500/5 border-emerald-500/20 text-emerald-400',
    cyan: 'from-cyan-500/20 to-cyan-500/5 border-cyan-500/20 text-cyan-400',
    amber: 'from-amber-500/20 to-amber-500/5 border-amber-500/20 text-amber-400',
  };

  const pieData = (data?.categoryBreakdown || DEMO_CATEGORIES).map((c: any) => ({
    name: c.category,
    value: Number(c.potential_revenue || 0)
  }));

  const customTooltip = ({ active, payload, label }: any) => {
    if (active && payload?.length) {
      return (
        <div className="bg-zinc-800 border border-white/10 rounded-xl p-3 shadow-xl">
          <p className="text-xs text-zinc-400">{label}</p>
          {payload.map((p: any, i: number) => (
            <p key={i} className="text-sm font-semibold" style={{ color: p.color }}>
              {p.name}: {typeof p.value === 'number' ? p.value.toLocaleString() : p.value}
              {p.name === 'revenue' ? 'đ' : ''}
            </p>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-700">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Thống kê doanh thu</h1>
        <p className="text-zinc-500 mt-1">Phân tích hiệu suất bán hàng của cửa hàng</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {kpiCards.map((card, i) => {
          const Icon = card.icon;
          return (
            <div
              key={card.label}
              className={`bg-gradient-to-br ${colorMap[card.color]} border rounded-2xl p-5 backdrop-blur-sm transition-all duration-300 hover:scale-[1.02]`}
            >
              <div className="flex items-center gap-2 mb-2">
                <Icon size={18} className="opacity-70" />
                <span className="text-xs text-zinc-400">{card.label}</span>
              </div>
              <p className="text-2xl font-bold text-white">{card.value}</p>
            </div>
          );
        })}
      </div>

      {/* Line Chart - Doanh thu theo ngày */}
      <div className="bg-zinc-900/50 border border-white/5 rounded-2xl p-6 backdrop-blur-sm">
        <h3 className="text-lg font-semibold mb-4">📈 Doanh thu theo ngày</h3>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data?.daily || DEMO_DAILY}>
            <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
            <XAxis dataKey="date" stroke="#71717a" fontSize={12} />
            <YAxis stroke="#71717a" fontSize={12} tickFormatter={(v) => `${(v/1000000).toFixed(1)}M`} />
            <Tooltip content={customTooltip} />
            <Line type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={3} dot={{ fill: '#10b981', r: 4 }} activeDot={{ r: 6 }} name="revenue" />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bar Chart - Top sản phẩm */}
        <div className="bg-zinc-900/50 border border-white/5 rounded-2xl p-6 backdrop-blur-sm">
          <h3 className="text-lg font-semibold mb-4">🏆 Top sản phẩm bán chạy</h3>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={data?.topProducts || DEMO_TOP_PRODUCTS} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#27272a" />
              <XAxis type="number" stroke="#71717a" fontSize={12} />
              <YAxis dataKey="item_name" type="category" stroke="#71717a" fontSize={11} width={120} />
              <Tooltip content={customTooltip} />
              <Bar dataKey="sold_count" fill="#10b981" radius={[0, 6, 6, 0]} name="Đã bán" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Pie Chart - Phân bổ category */}
        <div className="bg-zinc-900/50 border border-white/5 rounded-2xl p-6 backdrop-blur-sm">
          <h3 className="text-lg font-semibold mb-4">🥧 Phân bổ theo danh mục</h3>
          <ResponsiveContainer width="100%" height={280}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                paddingAngle={3}
                dataKey="value"
                label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                labelLine={false}
              >
                {pieData.map((_: any, index: number) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip content={customTooltip} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
