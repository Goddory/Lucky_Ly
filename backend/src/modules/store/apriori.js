/**
 * Apriori Algorithm - Tự implement
 * Tìm frequent itemsets và association rules từ transaction data.
 * Dùng để gợi ý combo/bundle cross-sell cho cửa hàng.
 */

/**
 * Tạo tất cả các tổ hợp k phần tử từ mảng items.
 */
function combinations(items, k) {
  const result = [];
  if (k === 1) return items.map((item) => [item]);

  items.forEach((item, i) => {
    const rest = items.slice(i + 1);
    const combos = combinations(rest, k - 1);
    combos.forEach((combo) => result.push([item, ...combo]));
  });

  return result;
}

/**
 * Chuyển itemset thành key string để so sánh.
 */
function itemsetKey(itemset) {
  return [...itemset].sort().join('|');
}

/**
 * Đếm support count của một itemset trong danh sách transactions.
 */
function countSupport(transactions, itemset) {
  return transactions.filter((txn) =>
    itemset.every((item) => txn.includes(item))
  ).length;
}

/**
 * Thuật toán Apriori chính.
 * @param {string[][]} transactions - Mảng các giao dịch, mỗi giao dịch là mảng tên item.
 * @param {number} minSupport - Support tối thiểu (0-1).
 * @param {number} minConfidence - Confidence tối thiểu (0-1).
 * @param {number} maxK - Kích thước tối đa của itemset.
 * @returns {{ frequentItemsets: object[], rules: object[] }}
 */
export function apriori(transactions, minSupport = 0.1, minConfidence = 0.5, maxK = 4) {
  const totalTxn = transactions.length;
  if (totalTxn === 0) return { frequentItemsets: [], rules: [] };

  const minSupportCount = Math.ceil(minSupport * totalTxn);

  // Bước 1: Tìm tất cả unique items
  const allItems = [...new Set(transactions.flat())].sort();

  // Bước 2: Tìm frequent 1-itemsets
  let currentFrequent = [];
  const allFrequentItemsets = [];

  allItems.forEach((item) => {
    const count = countSupport(transactions, [item]);
    if (count >= minSupportCount) {
      currentFrequent.push({
        items: [item],
        support: count / totalTxn,
        count
      });
    }
  });

  allFrequentItemsets.push(...currentFrequent);

  // Bước 3: Lặp tìm frequent k-itemsets (k = 2, 3, ...)
  let k = 2;
  while (currentFrequent.length > 0 && k <= maxK) {
    const frequentItems = [...new Set(currentFrequent.flatMap((f) => f.items))].sort();

    const candidates = combinations(frequentItems, k);
    const nextFrequent = [];

    candidates.forEach((candidate) => {
      const count = countSupport(transactions, candidate);
      if (count >= minSupportCount) {
        nextFrequent.push({
          items: candidate,
          support: count / totalTxn,
          count
        });
      }
    });

    allFrequentItemsets.push(...nextFrequent);
    currentFrequent = nextFrequent;
    k++;
  }

  // Bước 4: Sinh Association Rules từ frequent itemsets (size >= 2)
  const rules = [];
  const supportMap = new Map();

  allFrequentItemsets.forEach((fi) => {
    supportMap.set(itemsetKey(fi.items), fi);
  });

  allFrequentItemsets
    .filter((fi) => fi.items.length >= 2)
    .forEach((fi) => {
      const items = fi.items;

      // Tạo tất cả phân hoạch không rỗng: antecedent => consequent
      for (let i = 1; i < items.length; i++) {
        const antecedents = combinations(items, i);

        antecedents.forEach((antecedent) => {
          const consequent = items.filter((item) => !antecedent.includes(item));
          if (consequent.length === 0) return;

          const antecedentData = supportMap.get(itemsetKey(antecedent));
          const consequentData = supportMap.get(itemsetKey(consequent));

          if (!antecedentData || !consequentData) return;

          const confidence = fi.support / antecedentData.support;
          const lift = confidence / consequentData.support;

          if (confidence >= minConfidence) {
            rules.push({
              antecedent,
              consequent,
              support: Math.round(fi.support * 10000) / 10000,
              confidence: Math.round(confidence * 10000) / 10000,
              lift: Math.round(lift * 10000) / 10000
            });
          }
        });
      }
    });

  // Sắp xếp rules theo lift giảm dần
  rules.sort((a, b) => b.lift - a.lift || b.confidence - a.confidence);

  return {
    frequentItemsets: allFrequentItemsets.filter((fi) => fi.items.length >= 2),
    rules
  };
}

/**
 * Chuyển dữ liệu CSV retail_sales thành transactions cho Apriori.
 * Mỗi transaction_id = một giao dịch chứa nhiều items.
 */
export function csvToTransactions(rows) {
  const txnMap = new Map();

  rows.forEach((row) => {
    const txnId = row.transaction_id;
    const productName = row.product_name;

    if (!txnMap.has(txnId)) {
      txnMap.set(txnId, new Set());
    }
    txnMap.get(txnId).add(productName);
  });

  return Array.from(txnMap.values()).map((set) => [...set]);
}

/**
 * Tạo gợi ý combo/bundle từ association rules.
 */
export function generateComboSuggestions(rules, topN = 10) {
  return rules.slice(0, topN).map((rule, index) => ({
    id: index + 1,
    bundleName: `Combo: ${[...rule.antecedent, ...rule.consequent].join(' + ')}`,
    items: [...rule.antecedent, ...rule.consequent],
    antecedent: rule.antecedent,
    consequent: rule.consequent,
    support: rule.support,
    confidence: rule.confidence,
    lift: rule.lift,
    suggestedDiscount: rule.lift > 2 ? 20 : rule.lift > 1.5 ? 15 : 10
  }));
}
