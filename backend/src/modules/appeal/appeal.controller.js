import * as appealService from './appeal.service.js';

export const submitAppeal = async (req, res, next) => {
    try {
        const userId = req.user.user_id || req.user.sub || req.user.userId;
        const { reason } = req.body;

        if (!reason || reason.trim() === '') {
            return res.status(400).json({ message: 'Nội dung kháng cáo không được để trống' });
        }

        // Check if user already has a pending appeal
        const latest = await appealService.getLatestAppealByUser(userId);
        if (latest && latest.status === 'PENDING') {
            return res.status(400).json({ message: 'Bạn đã có một đơn kháng cáo đang chờ xử lý' });
        }

        const appeal = await appealService.createAppeal(userId, reason);
        res.status(201).json({ message: 'Đơn kháng cáo đã được gửi thành công', appeal });
    } catch (err) {
        next(err);
    }
};

export const listAppeals = async (req, res, next) => {
    try {
        const { status = 'PENDING', limit = 10, offset = 0 } = req.query;
        const result = await appealService.listAppeals({ status, limit, offset });
        res.json(result);
    } catch (err) {
        next(err);
    }
};

export const respondToAppeal = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status, adminNote } = req.body;

        if (!['APPROVED', 'REJECTED'].includes(status)) {
            return res.status(400).json({ message: 'Trạng thái phản hồi không hợp lệ' });
        }

        const appeal = await appealService.respondToAppeal(id, status, adminNote);
        res.json({ message: `Đơn kháng cáo đã được ${status === 'APPROVED' ? 'chấp nhận' : 'từ chối'}`, appeal });
    } catch (err) {
        next(err);
    }
};

export const getMyLatestAppeal = async (req, res, next) => {
    try {
        const userId = req.user.user_id || req.user.sub || req.user.userId;
        const appeal = await appealService.getLatestAppealByUser(userId);
        res.json(appeal || null);
    } catch (err) {
        next(err);
    }
};
