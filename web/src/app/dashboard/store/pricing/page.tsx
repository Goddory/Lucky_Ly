'use client';

import { useEffect, useState } from 'react';
import axios from 'axios';
import { Tags, Sparkles, Check, X } from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

const EFFECT_ICONS: Record<string, string> = {
  sparkle: '✨', glow: '🌟', bounce: '🏀', shimmer: '💫', pulse: '💓',
  explosion: '💥', rain: '🌧️', float: '🎈', wave: '🌊', rotate: '🔄',
  shine: '☀️', heart_float: '💕', firework: '🎆', unwrap: '🎁', sunshine: '🌻',
  candle_blow: '🕯️', sprinkle: '🍬', none: '⬜'
};

interface Item {
  item_id: string;
  item_name: string;
  category: string;
  effect_type: string;
  price: number;
  stock: number;
}

export default function PricingPage() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editPrice, setEditPrice] = useState('');
  const [editEffect, setEditEffect] = useState('');

  useEffect(() => { fetchItems(); }, []);

  async function fetchItems() {
    try {
      const res = await axios.get(`${API_URL}/store/inventory`);
      setItems(res.data.items);
    } catch {
      setItems([
        { item_id: '1', item_name: 'Hoa Hồng Virtual', category: 'Hoa', effect_type: 'glow', price: 45000, stock: 800 },
        { item_id: '2', item_name: 'Gấu Bông AR', category: 'Thú Nhồi Bông', effect_type: 'bounce', price: 120000, stock: 150 },
        { item_id: '3', item_name: 'Thiệp Valentine', category: 'Thiệp', effect_type: 'heart_float', price: 30000, stock: 350 },
        { item_id: '4', item_name: 'Socola Virtual Box', category: 'Socola', effect_type: 'unwrap', price: 65000, stock: 300 },
        { item_id: '5', item_name: 'Pháo Hoa 3D', category: 'Hiệu Ứng', effect_type: 'explosion', price: 35000, stock: 600 },
        { item_id: '6', item_name: 'Vương Miện AR', category: 'Phụ Kiện', effect_type: 'shine', price: 85000, stock: 80 },
        { item_id: '7', item_name: 'Bóng Bay Virtual', category: 'Trang Trí', effect_type: 'float', price: 15000, stock: 1000 },
        { item_id: '8', item_name: 'Bánh Kem Virtual', category: 'Bánh', effect_type: 'candle_blow', price: 75000, stock: 180 },
        { item_id: '9', item_name: 'Nhẫn AR Magic', category: 'Phụ Kiện', effect_type: 'rotate', price: 150000, stock: 60 },
        { item_id: '10', item_name: 'Confetti Rain', category: 'Hiệu Ứng', effect_type: 'rain', price: 25000, stock: 400 },
      ]);
    } finally { setLoading(false); }
  }

  function startEdit(item: Item) {
    setEditingId(item.item_id);
    setEditPrice(String(item.price));
    setEditEffect(item.effect_type);
  }

  async function saveEdit(item: Item) {
    try {
      await axios.put(`${API_URL}/store/inventory/${item.item_id}`, {
        price: parseFloat(editPrice),
        effectType: editEffect
      });
      fetchItems();
    } catch {
      setItems(prev => prev.map(i =>
        i.item_id === item.item_id ? { ...i, price: parseFloat(editPrice) || i.price, effect_type: editEffect || i.effect_type } : i
      ));
    }
    setEditingId(null);
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-emerald-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-700">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Giá & Hiệu ứng</h1>
        <p className="text-zinc-500 mt-1">Cập nhật giá bán và hiệu ứng cho từng vật phẩm</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {items.map((item, i) => {
          const isEditing = editingId === item.item_id;
          return (
            <div
              key={item.item_id}
              className={`bg-zinc-900/50 border rounded-2xl p-5 backdrop-blur-sm transition-all duration-300 hover:scale-[1.02] ${
                isEditing ? 'border-emerald-500/30 shadow-lg shadow-emerald-500/10' : 'border-white/5'
              }`}
              style={{ animationDelay: `${i * 50}ms` }}
            >
              {/* Header */}
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="font-semibold text-sm">{item.item_name}</h3>
                  <span className="text-xs text-zinc-500">{item.category}</span>
                </div>
                <span className="text-2xl" title={item.effect_type}>
                  {EFFECT_ICONS[item.effect_type] || '✨'}
                </span>
              </div>

              {/* Price */}
              <div className="mb-4">
                <label className="text-xs text-zinc-500 mb-1 block flex items-center gap-1">
                  <Tags size={12} /> Giá bán
                </label>
                {isEditing ? (
                  <input
                    type="number"
                    value={editPrice}
                    onChange={e => setEditPrice(e.target.value)}
                    className="w-full px-3 py-2 bg-zinc-800 border border-emerald-500/30 rounded-lg text-sm font-semibold focus:outline-none"
                    autoFocus
                  />
                ) : (
                  <p className="text-xl font-bold text-emerald-400">{Number(item.price).toLocaleString()}đ</p>
                )}
              </div>

              {/* Effect */}
              <div className="mb-4">
                <label className="text-xs text-zinc-500 mb-1 block flex items-center gap-1">
                  <Sparkles size={12} /> Hiệu ứng
                </label>
                {isEditing ? (
                  <select
                    value={editEffect}
                    onChange={e => setEditEffect(e.target.value)}
                    className="w-full px-3 py-2 bg-zinc-800 border border-emerald-500/30 rounded-lg text-sm focus:outline-none"
                  >
                    {Object.entries(EFFECT_ICONS).map(([key, icon]) => (
                      <option key={key} value={key}>{icon} {key}</option>
                    ))}
                  </select>
                ) : (
                  <span className="px-3 py-1.5 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs text-emerald-400 inline-flex items-center gap-1">
                    {EFFECT_ICONS[item.effect_type]} {item.effect_type}
                  </span>
                )}
              </div>

              {/* Stock info */}
              <div className="flex items-center justify-between text-xs text-zinc-500 mb-4">
                <span>Tồn kho: {Number(item.stock).toLocaleString()}</span>
              </div>

              {/* Actions */}
              <div className="flex gap-2">
                {isEditing ? (
                  <>
                    <button
                      onClick={() => saveEdit(item)}
                      className="flex-1 py-2 bg-emerald-500 text-white rounded-lg text-xs font-semibold hover:bg-emerald-600 transition-colors flex items-center justify-center gap-1"
                    >
                      <Check size={14} /> Lưu
                    </button>
                    <button
                      onClick={() => setEditingId(null)}
                      className="flex-1 py-2 bg-zinc-800 text-zinc-300 rounded-lg text-xs font-medium hover:bg-zinc-700 transition-colors flex items-center justify-center gap-1"
                    >
                      <X size={14} /> Hủy
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => startEdit(item)}
                    className="w-full py-2 bg-zinc-800 text-zinc-300 rounded-lg text-xs font-medium hover:bg-zinc-700 transition-colors"
                  >
                    Chỉnh sửa giá & hiệu ứng
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
