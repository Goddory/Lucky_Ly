"""
K-Means Clustering + Churn Prediction for Lucky Ly Marketing Admin.
Reads from datasets/ and exports cluster_results.json.
Usage: py scripts/clustering_analysis.py
"""
import csv
import json
import math
import os
import random

random.seed(42)
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_csv(path):
    with open(path, encoding='utf-8') as f:
        return list(csv.DictReader(f))


def safe_float(v, default=0.0):
    try:
        return float(v)
    except (ValueError, TypeError):
        return default


def safe_int(v, default=0):
    try:
        return int(v)
    except (ValueError, TypeError):
        return default


# ─── Load datasets ───────────────────────────────────────────────
campaign_path = os.path.join(BASE, 'datasets', 'Campain Dataset', 'marketing_campaign.csv')
demo_path = os.path.join(BASE, 'datasets', 'Campain Dataset', 'customer_demographics.csv')
promo_path = os.path.join(BASE, 'datasets', 'luckyly_promotions.csv')

campaign_data = read_csv(campaign_path) if os.path.exists(campaign_path) else []
demo_data = read_csv(demo_path) if os.path.exists(demo_path) else []
promo_data = read_csv(promo_path) if os.path.exists(promo_path) else []

print(f"Loaded: campaign={len(campaign_data)}, demographics={len(demo_data)}, promotions={len(promo_data)}")


# ─── Build user feature vectors from luckyly_promotions ──────────
users = {}
for row in promo_data:
    uid = row.get('user_id', '')
    if uid not in users:
        users[uid] = {
            'user_id': uid,
            'age': safe_int(row.get('user_age')),
            'is_student': safe_int(row.get('is_student')),
            'spending': safe_float(row.get('spending_monthly')),
            'days_inactive': safe_int(row.get('days_since_last_login')),
            'wallet': safe_float(row.get('wallet_balance')),
            'vouchers_received': 0,
            'vouchers_used': 0,
        }
    users[uid]['vouchers_received'] += 1
    if str(row.get('is_used', '0')) == '1':
        users[uid]['vouchers_used'] += 1

user_list = list(users.values())
print(f"Unique users: {len(user_list)}")


# ─── Enrich with campaign spending patterns ──────────────────────
campaign_spending = {}
for row in campaign_data:
    total_spend = sum([
        safe_float(row.get('MntWines')),
        safe_float(row.get('MntFruits')),
        safe_float(row.get('MntMeatProducts')),
        safe_float(row.get('MntFishProducts')),
        safe_float(row.get('MntSweetProducts')),
        safe_float(row.get('MntGoldProds')),
    ])
    campaign_spending.setdefault('avg_income', []).append(safe_float(row.get('Income')))
    campaign_spending.setdefault('avg_spend', []).append(total_spend)
    campaign_spending.setdefault('recency', []).append(safe_int(row.get('Recency')))

campaign_stats = {
    'avg_income': sum(campaign_spending.get('avg_income', [0])) / max(len(campaign_spending.get('avg_income', [1])), 1),
    'avg_spend': sum(campaign_spending.get('avg_spend', [0])) / max(len(campaign_spending.get('avg_spend', [1])), 1),
    'avg_recency': sum(campaign_spending.get('recency', [0])) / max(len(campaign_spending.get('recency', [1])), 1),
}


# ─── K-Means Clustering (3 clusters, manual) ────────────────────
def normalize(values):
    mn, mx = min(values), max(values)
    rng = mx - mn if mx != mn else 1
    return [(v - mn) / rng for v in values]


def euclidean(a, b):
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


features = []
for u in user_list:
    features.append([
        u['spending'],
        u['days_inactive'],
        u['wallet'],
        u['age'],
        u['vouchers_used'] / max(u['vouchers_received'], 1),
    ])

# Normalize each feature dimension
if features:
    dims = len(features[0])
    for d in range(dims):
        col = [f[d] for f in features]
        normed = normalize(col)
        for i, v in enumerate(normed):
            features[i][d] = v

K = 3
centroids = random.sample(features, min(K, len(features)))

for _ in range(50):
    assignments = []
    for pt in features:
        dists = [euclidean(pt, c) for c in centroids]
        assignments.append(dists.index(min(dists)))

    new_centroids = []
    for k in range(K):
        members = [features[i] for i in range(len(features)) if assignments[i] == k]
        if members:
            new_centroids.append([sum(col) / len(col) for col in zip(*members)])
        else:
            new_centroids.append(centroids[k])
    
    if new_centroids == centroids:
        break
    centroids = new_centroids

# Assign labels
for i, u in enumerate(user_list):
    u['cluster'] = assignments[i] if i < len(assignments) else 0


# ─── Name clusters by characteristics ───────────────────────────
cluster_profiles = {}
for k in range(K):
    members = [u for u in user_list if u['cluster'] == k]
    if not members:
        continue
    avg_spend = sum(m['spending'] for m in members) / len(members)
    avg_age = sum(m['age'] for m in members) / len(members)
    student_pct = sum(1 for m in members if m['is_student']) / len(members)
    avg_inactive = sum(m['days_inactive'] for m in members) / len(members)
    avg_wallet = sum(m['wallet'] for m in members) / len(members)
    usage_rate = sum(m['vouchers_used'] for m in members) / max(sum(m['vouchers_received'] for m in members), 1)

    cluster_profiles[k] = {
        'count': len(members),
        'avg_spending': round(avg_spend, 2),
        'avg_age': round(avg_age, 1),
        'student_pct': round(student_pct * 100, 1),
        'avg_days_inactive': round(avg_inactive, 1),
        'avg_wallet': round(avg_wallet, 2),
        'voucher_usage_rate': round(usage_rate * 100, 1),
    }

# Sort by avg_spending to assign labels
sorted_clusters = sorted(cluster_profiles.items(), key=lambda x: x[1]['avg_spending'])
NAMES = ['Student Budget', 'Casual User', 'Active Spender']
cluster_names = {}
for idx, (k, _) in enumerate(sorted_clusters):
    cluster_names[k] = NAMES[idx] if idx < len(NAMES) else f'Cluster {k}'


# ─── Churn detection ────────────────────────────────────────────
CHURN_DAYS_THRESHOLD = 30
CHURN_WALLET_THRESHOLD = 50

churn_users = []
for u in user_list:
    if u['days_inactive'] > CHURN_DAYS_THRESHOLD and u['wallet'] < CHURN_WALLET_THRESHOLD:
        churn_users.append({
            'user_id': u['user_id'],
            'age': u['age'],
            'is_student': bool(u['is_student']),
            'days_inactive': u['days_inactive'],
            'wallet': u['wallet'],
            'spending': u['spending'],
            'cluster': cluster_names.get(u['cluster'], f"Cluster {u['cluster']}"),
        })


# ─── Build output ───────────────────────────────────────────────
output = {
    'generated_at': __import__('datetime').datetime.now().isoformat(),
    'datasets_used': {
        'marketing_campaign': len(campaign_data),
        'customer_demographics': len(demo_data),
        'luckyly_promotions': len(promo_data),
    },
    'campaign_stats': campaign_stats,
    'clusters': [],
    'churn_users': churn_users[:50],
    'total_churn': len(churn_users),
    'churn_rate': round(len(churn_users) / max(len(user_list), 1) * 100, 1),
}

for k in range(K):
    profile = cluster_profiles.get(k, {})
    output['clusters'].append({
        'id': k,
        'name': cluster_names.get(k, f'Cluster {k}'),
        **profile,
    })

out_path = os.path.join(BASE, 'scripts', 'cluster_results.json')
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print(f"\n{'='*50}")
print(f"Clusters:")
for c in output['clusters']:
    print(f"  [{c['id']}] {c['name']}: {c.get('count', 0)} users, avg spend ${c.get('avg_spending', 0)}")
print(f"Churn risk: {output['total_churn']} users ({output['churn_rate']}%)")
print(f"Output: {out_path}")
