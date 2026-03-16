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

export const listUsers = async (req, res, next) => {
    try {
        const { search, limit, offset } = req.query;
        const result = await adminService.listUsers({ 
            search: search || '', 
            limit: limit || 10, 
            offset: offset || 0 
        });
        res.json(result);
    } catch (err) {
        next(err);
    }
};

export const getUserDetails = async (req, res, next) => {
    try {
        const { id } = req.params;
        const user = await adminService.getUserDetails(id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json(user);
    } catch (err) {
        next(err);
    }
};

export const updateUserStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        
        if (!['ACTIVE', 'BLOCKED'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const result = await adminService.updateUserStatus(id, status);
        if (!result) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({ message: `User status updated to ${status}`, user: result });
    } catch (err) {
        next(err);
    }
};
