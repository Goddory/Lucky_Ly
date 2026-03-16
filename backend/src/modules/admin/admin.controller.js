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
        const { search, status, limit, offset } = req.query;
        const result = await adminService.listUsers({ 
            search: search || '', 
            status: status || '',
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
        const { status, reason } = req.body;
        
        if (!['ACTIVE', 'BLOCKED'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        if (status === 'BLOCKED' && (!reason || reason.trim() === '')) {
            return res.status(400).json({ message: 'Lý do khóa tài khoản là bắt buộc' });
        }

        const result = await adminService.updateUserStatus(id, status, status === 'BLOCKED' ? reason : null);
        if (!result) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({ message: `User status updated to ${status}`, user: result });
    } catch (err) {
        next(err);
    }
};

export async function updateBalance(req, res, next) {
    try {
        const { id } = req.params;
        const { amount, type } = req.body; // type: 'ADD' or 'SUBTRACT'

        if (!amount || isNaN(amount) || amount <= 0) {
            return res.status(400).json({ message: 'Số tiền không hợp lệ' });
        }

        if (!['ADD', 'SUBTRACT'].includes(type)) {
            return res.status(400).json({ message: 'Loại thao tác không hợp lệ' });
        }

        const result = await adminService.updateUserBalance(id, amount, type);
        res.json({ message: 'Cập nhật số dư thành công', balance: result.balance });
    } catch (err) {
        next(err);
    }
}
