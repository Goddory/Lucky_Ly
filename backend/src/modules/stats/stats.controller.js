import { getOverviewStats, getChartData } from './stats.service.js';

const ALLOWED_METRICS = new Set(['users', 'active_users', 'locked_users', 'designs']);
const ALLOWED_PERIODS = new Set(['year', 'month', 'day']);

function toSingleString(value) {
  if (value == null) return undefined;
  if (Array.isArray(value)) return null;
  return String(value).trim();
}

function parseIntegerParam(rawValue, fallback, min, max) {
  if (rawValue === undefined) return fallback;
  if (!/^\d+$/.test(rawValue)) return null;

  const parsed = Number.parseInt(rawValue, 10);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) return null;
  return parsed;
}

function isValidIsoDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;

  const d = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(d.getTime())) return false;
  return d.toISOString().slice(0, 10) === value;
}

export async function overview(req, res, next) {
  try {
    const stats = await getOverviewStats();
    res.json({ stats });
  } catch (err) {
    next(err);
  }
}

export async function chart(req, res, next) {
  try {
    const metricRaw = toSingleString(req.query.metric) ?? 'users';
    const periodRaw = toSingleString(req.query.period) ?? 'month';
    const yearRaw = toSingleString(req.query.year);
    const monthRaw = toSingleString(req.query.month);
    const startDateRaw = toSingleString(req.query.startDate);

    if (metricRaw === null || periodRaw === null || yearRaw === null || monthRaw === null || startDateRaw === null) {
      return res.status(400).json({ message: 'Invalid query parameters format.' });
    }

    const metric = metricRaw.toLowerCase();
    const period = periodRaw.toLowerCase();

    if (!ALLOWED_METRICS.has(metric)) {
      return res.status(400).json({
        message: 'Invalid metric parameter. Allowed values: users, active_users, locked_users, designs.'
      });
    }

    if (!ALLOWED_PERIODS.has(period)) {
      return res.status(400).json({
        message: 'Invalid period parameter. Allowed values: day, month, year.'
      });
    }

    const now = new Date();
    const currentYear = parseIntegerParam(yearRaw, now.getFullYear(), 1970, 9999);
    if (currentYear === null) {
      return res.status(400).json({ message: 'Invalid year parameter. Use an integer from 1970 to 9999.' });
    }

    const currentMonth = parseIntegerParam(monthRaw, now.getMonth() + 1, 1, 12);
    if (currentMonth === null) {
      return res.status(400).json({ message: 'Invalid month parameter. Use an integer from 1 to 12.' });
    }

    let startDate;
    if (startDateRaw !== undefined) {
      if (!isValidIsoDate(startDateRaw)) {
        return res.status(400).json({ message: 'Invalid startDate parameter. Use YYYY-MM-DD.' });
      }
      startDate = startDateRaw;
    }

    const data = await getChartData(metric, period, currentYear, currentMonth, startDate);
    return res.json({ metric, period, data });
  } catch (err) {
    return next(err);
  }
}
