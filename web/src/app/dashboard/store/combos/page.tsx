'use client';

import { useEffect, useState } from 'react';
import axios from 'axios';
import { Sparkles, ArrowRight, TrendingUp, Package, Percent } from 'lucide-react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

interface Rule {
  antecedent: string[];
  consequent: string[];
  support: number;
  confidence: number;
  lift: number;
}

interface Combo {
  id: number;
  bundleName: string;
  items: string[];
  support: number;
  confidence: number;
  lift: number;
  suggestedDiscount: number;
}

interface AprioriResult {
  rules: Rule[];
  combos: Combo[];
  transactionCount: number;
  frequentItemsets: any[];
}

// Demo data khi API chưa sẵn sàng
const DEMO_RESULT: AprioriResult = {
  transactionCount: 30,
  frequentItemsets: [],
  rules: [
    { antecedent: ['Thiệp Chúc Mừng Sinh Nhật'], consequent: ['Hoa Hồng Virtual'], support: 0.2667, confidence: 0.7273, lift: 1.2727 },
    { antecedent: ['Socola Virtual Box'], consequent: ['Hoa Hồng Virtual'], support: 0.2667, confidence: 0.7273, lift: 1.2727 },
    { antecedent: ['Hoa Hồng Virtual'], consequent: ['Socola Virtual Box'], support: 0.2667, confidence: 0.4667, lift: 1.2727 },
    { antecedent: ['Thiệp Valentine'], consequent: ['Hoa Hồng Virtual'], support: 0.2000, confidence: 0.75, lift: 1.3125 },
    { antecedent: ['Gấu Bông AR'], consequent: ['Hoa Hồng Virtual'], support: 0.1667, confidence: 0.625, lift: 1.0938 },
    { antecedent: ['Pháo Hoa 3D Effect'], consequent: ['Thiệp Chúc Mừng Sinh Nhật'], support: 0.1333, confidence: 0.5, lift: 1.3636 },
    { antecedent: ['Gấu Bông AR', 'Hoa Hồng Virtual'], consequent: ['Thiệp Valentine'], support: 0.1, confidence: 0.6, lift: 2.25 },
    { antecedent: ['Hoa Hồng Virtual', 'Socola Virtual Box'], consequent: ['Thiệp Valentine'], support: 0.1333, confidence: 0.5, lift: 1.875 },
  ],
  combos: [
    { id: 1, bundleName: 'Combo: Gấu Bông AR + Hoa Hồng Virtual + Thiệp Valentine', items: ['Gấu Bông AR', 'Hoa Hồng Virtual', 'Thiệp Valentine'], support: 0.1, confidence: 0.6, lift: 2.25, suggestedDiscount: 20 },
    { id: 2, bundleName: 'Combo: Hoa Hồng Virtual + Socola Virtual Box + Thiệp Valentine', items: ['Hoa Hồng Virtual', 'Socola Virtual Box', 'Thiệp Valentine'], support: 0.1333, confidence: 0.5, lift: 1.875, suggestedDiscount: 15 },
    { id: 3, bundleName: 'Combo: Pháo Hoa 3D Effect + Thiệp Chúc Mừng Sinh Nhật', items: ['Pháo Hoa 3D Effect', 'Thiệp Chúc Mừng Sinh Nhật'], support: 0.1333, confidence: 0.5, lift: 1.3636, suggestedDiscount: 10 },
    { id: 4, bundleName: 'Combo: Thiệp Valentine + Hoa Hồng Virtual', items: ['Thiệp Valentine', 'Hoa Hồng Virtual'], support: 0.2, confidence: 0.75, lift: 1.3125, suggestedDiscount: 10 },
    { id: 5, bundleName: 'Combo: Thiệp Chúc Mừng Sinh Nhật + Hoa Hồng Virtual', items: ['Thiệp Chúc Mừng Sinh Nhật', 'Hoa Hồng Virtual'], support: 0.2667, confidence: 0.7273, lift: 1.2727, suggestedDiscount: 10 },
  ],
};

export default function CombosPage() {
  const [result, setResult] = useState<AprioriResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [minSupport, setMinSupport] = useState(0.1);
  const [minConfidence, setMinConfidence] = useState(0.5);

  useEffect(() => { runApriori(); }, []);

  async function runApriori() {
    setLoading(true);
    try {
      const res = await axios.get(`${API_URL}/store/apriori?minSupport=${minSupport}&minConfidence=${minConfidence}`);
      setResult(res.data);
    } catch {
      setResult(DEMO_RESULT);
    } finally { setLoading(false); }
  }

  async function handleCreateBundle(combo: Combo) {
    try {
      await axios.post(`${API_URL}/store/combos`, {
        items: combo.items,
        support: combo.support,
        confidence: combo.confidence,
        lift: combo.lift,
        bundleName: combo.bundleName,
        discountPercent: combo.suggestedDiscount,
        isActive: true,
      });
      alert(`✅ Đã tạo bundle: ${combo.bundleName}`);
    } catch {
      alert(`🎉 Bundle "${combo.bundleName}" đã được tạo (demo mode)`);
    }
  }

  function getLiftColor(lift: number) {
    if (lift >= 2) return 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20';
    if (lift >= 1.5) return 'text-cyan-400 bg-cyan-500/10 border-cyan-500/20';
    if (lift >= 1) return 'text-amber-400 bg-amber-500/10 border-amber-500/20';
    return 'text-zinc-400 bg-zinc-500/10 border-zinc-500/20';
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-96 gap-4">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-emerald-500"></div>
        <p className="text-zinc-500 text-sm">Đang chạy thuật toán Apriori...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-700">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Gợi ý Combo / Bundle</h1>
        <p className="text-zinc-500 mt-1">Thuật toán Apriori tìm các sản phẩm thường mua cùng nhau → gợi ý cross-sell</p>
      </div>

      {/* Parameters */}
      <div className="bg-zinc-900/50 border border-white/5 rounded-2xl p-5 backdrop-blur-sm">
        <h3 className="text-sm font-semibold mb-3 flex items-center gap-2">
          <Sparkles size={16} className="text-emerald-400" /> Tham số thuật toán
        </h3>
        <div className="flex gap-4 flex-wrap items-end">
          <div>
            <label className="text-xs text-zinc-500 block mb-1">Min Support</label>
            <input
              type="number"
              value={minSupport}
              onChange={e => setMinSupport(parseFloat(e.target.value) || 0.1)}
              step={0.05}
              min={0.01}
              max={1}
              className="px-3 py-2 bg-zinc-800 border border-white/10 rounded-lg text-sm w-28 focus:outline-none focus:border-emerald-500/50"
            />
          </div>
          <div>
            <label className="text-xs text-zinc-500 block mb-1">Min Confidence</label>
            <input
              type="number"
              value={minConfidence}
              onChange={e => setMinConfidence(parseFloat(e.target.value) || 0.5)}
              step={0.05}
              min={0.01}
              max={1}
              className="px-3 py-2 bg-zinc-800 border border-white/10 rounded-lg text-sm w-28 focus:outline-none focus:border-emerald-500/50"
            />
          </div>
          <button
            onClick={runApriori}
            className="px-5 py-2 bg-emerald-500 text-white rounded-lg text-sm font-semibold hover:bg-emerald-600 transition-all"
          >
            🔄 Chạy lại
          </button>
          <span className="text-xs text-zinc-500">
            Dữ liệu: {result?.transactionCount || 0} giao dịch
          </span>
        </div>
      </div>

      {/* Combo Suggestions */}
      <div>
        <h3 className="text-lg font-semibold mb-4">🎁 Gợi ý Bundle ({result?.combos?.length || 0})</h3>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {result?.combos?.map((combo, i) => (
            <div
              key={combo.id}
              className="bg-zinc-900/50 border border-white/5 rounded-2xl p-5 backdrop-blur-sm hover:border-emerald-500/20 transition-all hover:scale-[1.01]"
              style={{ animationDelay: `${i * 80}ms` }}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <Package size={16} className="text-emerald-400" />
                  <span className="text-xs text-zinc-500">Bundle #{combo.id}</span>
                </div>
                <span className={`px-2 py-0.5 rounded text-xs font-semibold border ${getLiftColor(combo.lift)}`}>
                  Lift: {combo.lift.toFixed(2)}
                </span>
              </div>

              {/* Items */}
              <div className="flex items-center flex-wrap gap-2 mb-4">
                {combo.items.map((item, j) => (
                  <span key={j} className="px-3 py-1.5 bg-zinc-800 rounded-lg text-xs font-medium">
                    {item}
                  </span>
                ))}
              </div>

              {/* Metrics */}
              <div className="grid grid-cols-3 gap-3 mb-4">
                <div className="text-center p-2 bg-zinc-800/50 rounded-lg">
                  <p className="text-xs text-zinc-500">Support</p>
                  <p className="text-sm font-bold text-emerald-400">{(combo.support * 100).toFixed(1)}%</p>
                </div>
                <div className="text-center p-2 bg-zinc-800/50 rounded-lg">
                  <p className="text-xs text-zinc-500">Confidence</p>
                  <p className="text-sm font-bold text-cyan-400">{(combo.confidence * 100).toFixed(1)}%</p>
                </div>
                <div className="text-center p-2 bg-zinc-800/50 rounded-lg">
                  <p className="text-xs text-zinc-500">Giảm giá</p>
                  <p className="text-sm font-bold text-amber-400">{combo.suggestedDiscount}%</p>
                </div>
              </div>

              <button
                onClick={() => handleCreateBundle(combo)}
                className="w-full py-2.5 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 rounded-xl text-xs font-semibold hover:bg-emerald-500/20 transition-all flex items-center justify-center gap-2"
              >
                🚀 Tạo Bundle này
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Association Rules Table */}
      <div className="bg-zinc-900/50 border border-white/5 rounded-2xl overflow-hidden backdrop-blur-sm">
        <div className="p-5 border-b border-white/5">
          <h3 className="text-lg font-semibold">📊 Association Rules ({result?.rules?.length || 0})</h3>
          <p className="text-xs text-zinc-500 mt-1">Luật kết hợp tìm được từ thuật toán Apriori</p>
        </div>
        <table className="w-full">
          <thead>
            <tr className="border-b border-white/5">
              <th className="text-left px-5 py-3 text-xs font-semibold text-zinc-500">Antecedent (Nếu mua)</th>
              <th className="text-center px-2 py-3 text-xs font-semibold text-zinc-500"></th>
              <th className="text-left px-5 py-3 text-xs font-semibold text-zinc-500">Consequent (Thì mua)</th>
              <th className="text-right px-5 py-3 text-xs font-semibold text-zinc-500">Support</th>
              <th className="text-right px-5 py-3 text-xs font-semibold text-zinc-500">Confidence</th>
              <th className="text-right px-5 py-3 text-xs font-semibold text-zinc-500">Lift</th>
            </tr>
          </thead>
          <tbody>
            {result?.rules?.map((rule, i) => (
              <tr key={i} className="border-b border-white/5 hover:bg-white/[0.02] transition-colors">
                <td className="px-5 py-3">
                  <div className="flex gap-1 flex-wrap">
                    {rule.antecedent.map((a, j) => (
                      <span key={j} className="px-2 py-0.5 bg-cyan-500/10 border border-cyan-500/20 rounded text-xs text-cyan-400">{a}</span>
                    ))}
                  </div>
                </td>
                <td className="px-2 py-3 text-center">
                  <ArrowRight size={14} className="text-zinc-600 mx-auto" />
                </td>
                <td className="px-5 py-3">
                  <div className="flex gap-1 flex-wrap">
                    {rule.consequent.map((c, j) => (
                      <span key={j} className="px-2 py-0.5 bg-emerald-500/10 border border-emerald-500/20 rounded text-xs text-emerald-400">{c}</span>
                    ))}
                  </div>
                </td>
                <td className="px-5 py-3 text-right text-xs font-mono">{(rule.support * 100).toFixed(1)}%</td>
                <td className="px-5 py-3 text-right text-xs font-mono">{(rule.confidence * 100).toFixed(1)}%</td>
                <td className="px-5 py-3 text-right">
                  <span className={`px-2 py-0.5 rounded text-xs font-bold border ${getLiftColor(rule.lift)}`}>
                    {rule.lift.toFixed(2)}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
