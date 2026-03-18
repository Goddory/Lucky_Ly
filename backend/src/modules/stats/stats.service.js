import { pool } from '../../db/pool.js';

// Lấy tổng quan thống kê (4 chỉ số chính)
export async function getOverviewStats() {
  const stats = { total_users: 0, active_users: 0, locked_users: 0, total_designs: 0 };

  try {
    const r1 = await pool.query('SELECT COUNT(*)::int AS c FROM users');
    stats.total_users = r1.rows[0].c;
  } catch (e) { console.error('Stats: total_users query failed', e.message); }

  try {
    const r2 = await pool.query('SELECT COUNT(*)::int AS c FROM users WHERE is_active = true');
    stats.active_users = r2.rows[0].c;
  } catch (e) { console.error('Stats: active_users query failed', e.message); }

  try {
    const r3 = await pool.query('SELECT COUNT(*)::int AS c FROM users WHERE is_active = false');
    stats.locked_users = r3.rows[0].c;
  } catch (e) { console.error('Stats: locked_users query failed', e.message); }

  try {
    const r4 = await pool.query('SELECT COUNT(*)::int AS c FROM designs');
    stats.total_designs = r4.rows[0].c;
  } catch (e) { console.error('Stats: total_designs query failed (table may not exist)', e.message); }

  console.log('📊 Overview stats:', stats);
  return stats;
}

// Lấy dữ liệu biểu đồ theo metric + period
export async function getChartData(metric, period, year, month, startDate) {
  let query = '';
  const params = [];

  // For day mode, use startDate or default to 6 days ago
  const dayStart = startDate || new Date(Date.now() - 6 * 86400000).toISOString().split('T')[0];

  if (metric === 'users') {
    if (period === 'year') {
      params.push(parseInt(year));
      query = `
        SELECT EXTRACT(MONTH FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE EXTRACT(YEAR FROM created_at) = $1
        GROUP BY label
        ORDER BY label
      `;
    } else if (period === 'month') {
      params.push(parseInt(year), parseInt(month));
      query = `
        SELECT EXTRACT(DAY FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE EXTRACT(YEAR FROM created_at) = $1
          AND EXTRACT(MONTH FROM created_at) = $2
        GROUP BY label
        ORDER BY label
      `;
    } else {
      params.push(dayStart);
      query = `
        SELECT created_at::date AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE created_at::date >= $1::date
          AND created_at::date <= ($1::date + INTERVAL '6 days')
        GROUP BY label
        ORDER BY label
      `;
    }
  } else if (metric === 'active_users') {
    if (period === 'year') {
      params.push(parseInt(year));
      query = `
        SELECT EXTRACT(MONTH FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE is_active = true AND EXTRACT(YEAR FROM created_at) = $1
        GROUP BY label
        ORDER BY label
      `;
    } else if (period === 'month') {
      params.push(parseInt(year), parseInt(month));
      query = `
        SELECT EXTRACT(DAY FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE is_active = true
          AND EXTRACT(YEAR FROM created_at) = $1
          AND EXTRACT(MONTH FROM created_at) = $2
        GROUP BY label
        ORDER BY label
      `;
    } else {
      params.push(dayStart);
      query = `
        SELECT created_at::date AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE is_active = true
          AND created_at::date >= $1::date
          AND created_at::date <= ($1::date + INTERVAL '6 days')
        GROUP BY label
        ORDER BY label
      `;
    }
  } else if (metric === 'locked_users') {
    if (period === 'year') {
      params.push(parseInt(year));
      query = `
        SELECT EXTRACT(MONTH FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE is_active = false AND EXTRACT(YEAR FROM created_at) = $1
        GROUP BY label
        ORDER BY label
      `;
    } else if (period === 'month') {
      params.push(parseInt(year), parseInt(month));
      query = `
        SELECT EXTRACT(DAY FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE is_active = false
          AND EXTRACT(YEAR FROM created_at) = $1
          AND EXTRACT(MONTH FROM created_at) = $2
        GROUP BY label
        ORDER BY label
      `;
    } else {
      params.push(dayStart);
      query = `
        SELECT created_at::date AS label,
               COUNT(*)::int AS value
        FROM users
        WHERE is_active = false
          AND created_at::date >= $1::date
          AND created_at::date <= ($1::date + INTERVAL '6 days')
        GROUP BY label
        ORDER BY label
      `;
    }
  } else if (metric === 'designs') {
    if (period === 'year') {
      params.push(parseInt(year));
      query = `
        SELECT EXTRACT(MONTH FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM designs
        WHERE EXTRACT(YEAR FROM created_at) = $1
        GROUP BY label
        ORDER BY label
      `;
    } else if (period === 'month') {
      params.push(parseInt(year), parseInt(month));
      query = `
        SELECT EXTRACT(DAY FROM created_at)::int AS label,
               COUNT(*)::int AS value
        FROM designs
        WHERE EXTRACT(YEAR FROM created_at) = $1
          AND EXTRACT(MONTH FROM created_at) = $2
        GROUP BY label
        ORDER BY label
      `;
    } else {
      params.push(dayStart);
      query = `
        SELECT created_at::date AS label,
               COUNT(*)::int AS value
        FROM designs
        WHERE created_at::date >= $1::date
          AND created_at::date <= ($1::date + INTERVAL '6 days')
        GROUP BY label
        ORDER BY label
      `;
    }
  }

  if (!query) return [];
  const result = await pool.query(query, params);
  return result.rows.map(r => ({ label: String(r.label), value: parseInt(r.value) }));
}
