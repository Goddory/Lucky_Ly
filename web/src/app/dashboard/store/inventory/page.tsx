'use client';

import { useEffect, useState } from 'react';
import axios from 'axios';
import { Plus, Search, Trash2, Edit3, X, Check } from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

const CATEGORIES = ['Thiệp', 'Hoa', 'Thú Nhồi Bông', 'Socola', 'Hiệu Ứng', 'Phụ Kiện', 'Trang Trí', 'Bánh'];
const EFFECTS = ['none', 'sparkle', 'glow', 'bounce', 'shimmer', 'pulse', 'explosion', 'rain', 'float', 'wave', 'rotate', 'shine', 'heart_float', 'firework', 'unwrap', 'sunshine', 'candle_blow', 'sprinkle'];

interface StoreItem {
  item_id: string;
  item_name: string;
  category: string;
  effect_type: string;
  price: number;
  stock: number;
  description?: string;
  is_active: boolean;
}

export default function InventoryPage() {
  const [items, setItems] = useState<StoreItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState<StoreItem | null>(null);
  const [form, setForm] = useState({ itemName: '', category: 'Thiệp', effectType: 'sparkle', price: '', stock: '', description: '' });

  useEffect(() => { fetchItems(); }, []);

  async function fetchItems() {
    try {
      const res = await axios.get(`${API_URL}/store/inventory`);
      setItems(res.data.items);
    } catch {
      // Fallback demo data
      setItems([
        { item_id: '1', item_name: 'Hoa Hồng Virtual', category: 'Hoa', effect_type: 'glow', price: 45000, stock: 800, is_active: true },
        { item_id: '2', item_name: 'Gấu Bông AR', category: 'Thú Nhồi Bông', effect_type: 'bounce', price: 120000, stock: 150, is_active: true },
        { item_id: '3', item_name: 'Thiệp Valentine', category: 'Thiệp', effect_type: 'heart_float', price: 30000, stock: 350, is_active: true },
        { item_id: '4', item_name: 'Socola Virtual Box', category: 'Socola', effect_type: 'unwrap', price: 65000, stock: 300, is_active: true },
        { item_id: '5', item_name: 'Pháo Hoa 3D Effect', category: 'Hiệu Ứng', effect_type: 'explosion', price: 35000, stock: 600, is_active: true },
        { item_id: '6', item_name: 'Vương Miện AR', category: 'Phụ Kiện', effect_type: 'shine', price: 85000, stock: 80, is_active: true },
        { item_id: '7', item_name: 'Bóng Bay Virtual', category: 'Trang Trí', effect_type: 'float', price: 15000, stock: 1000, is_active: true },
        { item_id: '8', item_name: 'Bánh Kem Virtual 3D', category: 'Bánh', effect_type: 'candle_blow', price: 75000, stock: 180, is_active: true },
      ]);
    } finally {
      setLoading(false);
    }
  }

  async function handleSave() {
    try {
      if (editingItem) {
        await axios.put(`${API_URL}/store/inventory/${editingItem.item_id}`, form);
      } else {
        await axios.post(`${API_URL}/store/inventory`, form);
      }
      fetchItems();
    } catch {
      // Demo: add locally
      if (!editingItem) {
        setItems(prev => [...prev, {
          item_id: Date.now().toString(),
          item_name: form.itemName,
          category: form.category,
          effect_type: form.effectType,
          price: parseFloat(form.price) || 0,
          stock: parseInt(form.stock) || 0,
          is_active: true,
        }]);
      }
    }
    closeModal();
  }

  async function handleDelete(id: string) {
    if (!confirm('Xóa vật phẩm này?')) return;
    try {
      await axios.delete(`${API_URL}/store/inventory/${id}`);
      fetchItems();
    } catch {
      setItems(prev => prev.filter(i => i.item_id !== id));
    }
  }

  function openEditModal(item: StoreItem) {
    setEditingItem(item);
    setForm({
      itemName: item.item_name,
      category: item.category,
      effectType: item.effect_type,
      price: String(item.price),
      stock: String(item.stock),
      description: '',
    });
    setShowModal(true);
  }

  function closeModal() {
    setShowModal(false);
    setEditingItem(null);
    setForm({ itemName: '', category: 'Thiệp', effectType: 'sparkle', price: '', stock: '', description: '' });
  }

  const filteredItems = items.filter(i => {
    const matchSearch = !search || i.item_name.toLowerCase().includes(search.toLowerCase());
    const matchCat = !categoryFilter || i.category === categoryFilter;
    return matchSearch && matchCat;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-emerald-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-700">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Kho quà ảo</h1>
          <p className="text-zinc-500 mt-1">Quản lý vật phẩm trong cửa hàng của bạn</p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 text-white rounded-xl text-sm font-semibold hover:bg-emerald-600 transition-all hover:scale-105 active:scale-95 shadow-lg shadow-emerald-500/25"
        >
          <Plus size={18} /> Thêm mới
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Tìm vật phẩm..."
            className="w-full pl-10 pr-4 py-2.5 bg-zinc-900/50 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50 transition-colors"
          />
        </div>
        <select
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="px-4 py-2.5 bg-zinc-900/50 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50 appearance-none cursor-pointer"
        >
          <option value="">Tất cả danh mục</option>
          {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
      </div>

      {/* Item Table */}
      <div className="bg-zinc-900/50 border border-white/5 rounded-2xl overflow-hidden backdrop-blur-sm">
        <table className="w-full">
          <thead>
            <tr className="border-b border-white/5">
              <th className="text-left px-6 py-4 text-xs font-semibold uppercase text-zinc-500">Tên</th>
              <th className="text-left px-6 py-4 text-xs font-semibold uppercase text-zinc-500">Danh mục</th>
              <th className="text-left px-6 py-4 text-xs font-semibold uppercase text-zinc-500">Hiệu ứng</th>
              <th className="text-right px-6 py-4 text-xs font-semibold uppercase text-zinc-500">Giá</th>
              <th className="text-right px-6 py-4 text-xs font-semibold uppercase text-zinc-500">Tồn kho</th>
              <th className="text-right px-6 py-4 text-xs font-semibold uppercase text-zinc-500">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {filteredItems.map((item, i) => (
              <tr
                key={item.item_id}
                className="border-b border-white/5 hover:bg-white/[0.02] transition-colors"
                style={{ animationDelay: `${i * 50}ms` }}
              >
                <td className="px-6 py-4">
                  <p className="font-medium text-sm">{item.item_name}</p>
                </td>
                <td className="px-6 py-4">
                  <span className="px-3 py-1 bg-zinc-800 rounded-lg text-xs text-zinc-300">
                    {item.category}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className="px-3 py-1 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs text-emerald-400">
                    ✨ {item.effect_type}
                  </span>
                </td>
                <td className="px-6 py-4 text-right">
                  <span className="font-semibold text-sm">{Number(item.price).toLocaleString()}đ</span>
                </td>
                <td className="px-6 py-4 text-right">
                  <span className={`text-sm font-medium ${Number(item.stock) < 100 ? 'text-red-400' : 'text-zinc-300'}`}>
                    {Number(item.stock).toLocaleString()}
                  </span>
                </td>
                <td className="px-6 py-4 text-right">
                  <div className="flex gap-2 justify-end">
                    <button
                      onClick={() => openEditModal(item)}
                      className="p-2 hover:bg-zinc-800 rounded-lg transition-colors"
                      title="Sửa"
                    >
                      <Edit3 size={14} className="text-zinc-400" />
                    </button>
                    <button
                      onClick={() => handleDelete(item.item_id)}
                      className="p-2 hover:bg-red-500/10 rounded-lg transition-colors"
                      title="Xóa"
                    >
                      <Trash2 size={14} className="text-red-400" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredItems.length === 0 && (
          <div className="text-center py-12 text-zinc-500">
            <Package size={48} className="mx-auto mb-3 opacity-30" />
            <p>Chưa có vật phẩm nào</p>
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="bg-zinc-900 border border-white/10 rounded-2xl p-6 w-full max-w-lg shadow-2xl animate-in fade-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-lg font-bold">{editingItem ? 'Sửa vật phẩm' : 'Thêm vật phẩm mới'}</h3>
              <button onClick={closeModal} className="p-2 hover:bg-zinc-800 rounded-lg">
                <X size={18} />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="text-xs text-zinc-500 mb-1 block">Tên vật phẩm</label>
                <input
                  value={form.itemName}
                  onChange={e => setForm(f => ({ ...f, itemName: e.target.value }))}
                  className="w-full px-4 py-2.5 bg-zinc-800 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50"
                  placeholder="Nhập tên..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">Danh mục</label>
                  <select
                    value={form.category}
                    onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                    className="w-full px-4 py-2.5 bg-zinc-800 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50"
                  >
                    {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">Hiệu ứng</label>
                  <select
                    value={form.effectType}
                    onChange={e => setForm(f => ({ ...f, effectType: e.target.value }))}
                    className="w-full px-4 py-2.5 bg-zinc-800 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50"
                  >
                    {EFFECTS.map(e => <option key={e} value={e}>✨ {e}</option>)}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">Giá (VNĐ)</label>
                  <input
                    type="number"
                    value={form.price}
                    onChange={e => setForm(f => ({ ...f, price: e.target.value }))}
                    className="w-full px-4 py-2.5 bg-zinc-800 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50"
                    placeholder="25000"
                  />
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">Số lượng</label>
                  <input
                    type="number"
                    value={form.stock}
                    onChange={e => setForm(f => ({ ...f, stock: e.target.value }))}
                    className="w-full px-4 py-2.5 bg-zinc-800 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50"
                    placeholder="100"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs text-zinc-500 mb-1 block">Mô tả</label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  className="w-full px-4 py-2.5 bg-zinc-800 border border-white/10 rounded-xl text-sm focus:outline-none focus:border-emerald-500/50 resize-none"
                  rows={3}
                  placeholder="Mô tả vật phẩm..."
                />
              </div>
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={closeModal}
                className="flex-1 py-2.5 bg-zinc-800 text-zinc-300 rounded-xl text-sm font-medium hover:bg-zinc-700 transition-colors"
              >
                Hủy
              </button>
              <button
                onClick={handleSave}
                className="flex-1 py-2.5 bg-emerald-500 text-white rounded-xl text-sm font-semibold hover:bg-emerald-600 transition-colors flex items-center justify-center gap-2"
              >
                <Check size={16} />
                {editingItem ? 'Cập nhật' : 'Tạo mới'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
