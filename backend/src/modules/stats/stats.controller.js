import { getOverviewStats, getChartData } from './stats.service.js';

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
    const { metric = 'users', period = 'month', year, month, startDate } = req.query;
    const currentYear = year || new Date().getFullYear();
    const currentMonth = month || (new Date().getMonth() + 1);

    const data = await getChartData(metric, period, currentYear, currentMonth, startDate);
    res.json({ metric, period, data });
  } catch (err) {
    next(err);
  }
}
