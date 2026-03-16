import express from 'express';
import * as designsController from './designs.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';

const router = express.Router();

// All design routes require authentication
router.use(authenticateToken);

router.post('/', designsController.saveDesign);
router.get('/', designsController.listUserDesigns);
router.get('/:id', designsController.getOneDesign);
router.delete('/:id', designsController.removeDesign);

export default router;
