import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import * as friendsController from './friends.controller.js';

const router = Router();

router.use(requireAuth);

router.get('/list', friendsController.listFriends);
router.get('/requests/sent', friendsController.listSentRequests);
router.get('/requests/received', friendsController.listReceivedRequests);
router.get('/search', friendsController.searchUsers);

router.post('/request', friendsController.sendRequest);
router.patch('/request/:id/accept', friendsController.acceptRequest);
router.patch('/request/:id/decline', friendsController.declineRequest);
router.delete('/:friendId', friendsController.removeFriend);

export default router;
