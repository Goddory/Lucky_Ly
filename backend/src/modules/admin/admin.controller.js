import * as adminService from './admin.service.js';

export const getStats = async (req, res, next) => {
    try {
        const { period = 'month' } = req.query; // day, month, year
        const stats = await adminService.getStats(period);
        res.json(stats);
    } catch (err) {
        next(err);
    }
};

export const updateTheme = async (req, res, next) => {
    try {
        const themeConfig = req.body;
        const result = await adminService.updateSystemTheme(themeConfig);
        res.json({ message: 'Theme updated successfully', theme: result });
    } catch (err) {
        next(err);
    }
};
