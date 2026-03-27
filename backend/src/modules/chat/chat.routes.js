import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import * as chatController from './chat.controller.js';

const router = Router();

router.use(requireAuth);

router.get('/rooms', chatController.listRooms);
router.post('/rooms', chatController.getRoomOrCreate);
router.get('/rooms/:roomId/messages', chatController.getMessages);
router.post('/rooms/:roomId/messages', chatController.postMessage);
router.patch('/rooms/:roomId/read', chatController.markAsRead);

export default router;
