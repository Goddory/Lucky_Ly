import * as friendsService from './friends.service.js';
import { notifyFriendRequest, notifyFriendAccepted } from '../../services/notification.service.js';

export const sendRequest = async (req, res, next) => {
  try {
    const result = await friendsService.sendFriendRequest(req.user.userId, parseInt(req.body.friendId));
    notifyFriendRequest(parseInt(req.body.friendId), req.user.username || 'Someone').catch(() => {});
    res.status(201).json({ message: 'Friend request sent', request: result });
  } catch (error) {
    next(error);
  }
};

export const acceptRequest = async (req, res, next) => {
  try {
    const result = await friendsService.acceptFriendRequest(parseInt(req.params.id), req.user.userId);
    notifyFriendAccepted(result.user_id, req.user.username || 'Someone').catch(() => {});
    res.status(200).json({ message: 'Friend request accepted', friendship: result });
  } catch (error) {
    next(error);
  }
};

export const declineRequest = async (req, res, next) => {
  try {
    const result = await friendsService.declineFriendRequest(parseInt(req.params.id), req.user.userId);
    res.status(200).json({ message: 'Friend request declined', request: result });
  } catch (error) {
    next(error);
  }
};

export const removeFriend = async (req, res, next) => {
  try {
    await friendsService.unfriend(req.user.userId, parseInt(req.params.friendId));
    res.status(200).json({ message: 'Unfriended successfully' });
  } catch (error) {
    next(error);
  }
};

export const listFriends = async (req, res, next) => {
  try {
    const friends = await friendsService.getFriendsList(req.user.userId);
    res.status(200).json(friends);
  } catch (error) {
    next(error);
  }
};

export const listSentRequests = async (req, res, next) => {
  try {
    const requests = await friendsService.getSentRequests(req.user.userId);
    res.status(200).json(requests);
  } catch (error) {
    next(error);
  }
};

export const listReceivedRequests = async (req, res, next) => {
  try {
    const requests = await friendsService.getReceivedRequests(req.user.userId);
    res.status(200).json(requests);
  } catch (error) {
    next(error);
  }
};

export const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ message: 'Search query must be at least 2 characters' });
    }
    const users = await friendsService.searchUsers(q.trim(), req.user.userId);
    res.status(200).json(users);
  } catch (error) {
    next(error);
  }
};
