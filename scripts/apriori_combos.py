import csv
import json
import itertools
from collections import defaultdict
import os

def generate_combo_rules():
    dataset_path = os.path.join(os.path.dirname(__file__), '..', 'datasets', 'Store Dataset', 'retail_sales.csv')
    output_path = os.path.join(os.path.dirname(__file__), 'combo_rules.json')

    # Read the dataset
    transactions = defaultdict(list)
    
    with open(dataset_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            txn_id = row['transaction_id']
            product = row['product_name']
            transactions[txn_id].append(product)
            
    # List of unique transactions (each transaction is a set of items)
    txn_list = list(transactions.values())
    total_txns = len(txn_list)
    
    # 1. Calculate item support (frequency)
    item_counts = defaultdict(int)
    for txn in txn_list:
        unique_items = set(txn)
        for item in unique_items:
            item_counts[item] += 1
            
    # 2. Calculate pair support
    pair_counts = defaultdict(int)
    for txn in txn_list:
        unique_items = sorted(list(set(txn)))
        # all combinations of 2 items
        for pair in itertools.combinations(unique_items, 2):
            pair_counts[pair] += 1
            
    # 3. Generate rules A -> B and B -> A
    min_support_count = 2 # Minimum 2 transactions
    min_confidence = 0.3 # Minimum 30% confidence
    
    rules = []
    
    for (item_a, item_b), count in pair_counts.items():
        if count >= min_support_count:
            # Rule A -> B
            conf_a_b = count / item_counts[item_a]
            if conf_a_b >= min_confidence:
                rules.append({
                    "antecedent": item_a,
                    "consequent": item_b,
                    "support": count / total_txns,
                    "confidence": conf_a_b,
                    "lift": conf_a_b / (item_counts[item_b] / total_txns)
                })
                
            # Rule B -> A
            conf_b_a = count / item_counts[item_b]
            if conf_b_a >= min_confidence:
                rules.append({
                    "antecedent": item_b,
                    "consequent": item_a,
                    "support": count / total_txns,
                    "confidence": conf_b_a,
                    "lift": conf_b_a / (item_counts[item_a] / total_txns)
                })
                
    # Sort rules by confidence and lift
    rules.sort(key=lambda x: (x['confidence'], x['lift']), reverse=True)
    
    result = {
        "metadata": {
            "total_transactions": total_txns,
            "rules_generated": len(rules)
        },
        "rules": rules
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
        
    print(f"Generated {len(rules)} combo rules to {output_path}")

if __name__ == "__main__":
    generate_combo_rules()
