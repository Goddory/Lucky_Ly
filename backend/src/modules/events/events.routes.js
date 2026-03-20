import express from 'express';
import * as eventsController from './events.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';

const router = express.Router();

// All events routes require authentication
router.use(authenticateToken);

router.post('/', eventsController.createEvent);
router.get('/', eventsController.listEvents);
router.delete('/:id', eventsController.removeEvent);

export default router;
