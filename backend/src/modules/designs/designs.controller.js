import * as designsService from './designs.service.js';

export const saveDesign = async (req, res, next) => {
    try {
        const userId = req.user.userId; // Populated by authenticateToken
        const { name, type, config, image_url } = req.body;

        if (!type || !config) {
            return res.status(400).json({ message: 'Type and config are required.' });
        }

        const design = await designsService.createDesign(userId, { name, type, config, image_url });
        res.status(201).json({
            message: 'Design saved successfully',
            design
        });
    } catch (error) {
        next(error);
    }
};

export const listUserDesigns = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const designs = await designsService.getUserDesigns(userId);
        res.status(200).json(designs);
    } catch (error) {
        next(error);
    }
};

export const getOneDesign = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const design = await designsService.getDesignById(id, userId);

        if (!design) {
            return res.status(404).json({ message: 'Design not found.' });
        }

        res.status(200).json(design);
    } catch (error) {
        next(error);
    }
};

export const removeDesign = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const deletedDesign = await designsService.deleteDesign(id, userId);

        if (!deletedDesign) {
            return res.status(404).json({ message: 'Design not found or unauthorized.' });
        }

        res.status(200).json({ message: 'Design deleted successfully' });
    } catch (error) {
        next(error);
    }
};
