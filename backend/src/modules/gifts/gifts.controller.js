import * as giftsService from './gifts.service.js';
import * as userService from '../user/user.service.js';
import { notifyGiftReceived, notifyGiftClaimed } from '../../services/notification.service.js';

export const sendGift = async (req, res, next) => {
  try {
    const senderId = req.user.userId;
    const { receiverEmail, theme, modelId, stickers, message } = req.body;

    if (!receiverEmail || !theme || !modelId) {
      return res.status(400).json({ message: 'receiverEmail, theme, and modelId are required.' });
    }

    if (!['tet', 'valentine'].includes(theme)) {
      return res.status(400).json({ message: 'Invalid theme. Must be "tet" or "valentine".' });
    }

    const gift = await giftsService.createGift(senderId, {
      receiverEmail,
      theme,
      modelId,
      stickers,
      message
    });

    res.status(201).json({ message: 'Gift sent successfully', gift });
  } catch (error) {
    next(error);
  }
};

export const createGiftLink = async (req, res, next) => {
  try {
    const senderId = req.user.userId;
    const { itemType, amount, maxReceivers, message } = req.body;

    const gift = await giftsService.createGiftLink(senderId, { itemType, amount, maxReceivers, message });
    res.status(201).json({ message: 'Gift link created (valid 24h)', gift });
  } catch (error) {
    next(error);
  }
};

export const claimGift = async (req, res, next) => {
  try {
    const { token } = req.params;
    const receiverId = req.user.userId;
    const result = await giftsService.claimGift(token, receiverId);

    // Notify sender that their gift was claimed
    const receiver = await userService.getUserProfile(receiverId);
    notifyGiftClaimed(result.senderId, receiver.username || 'Someone', result.giftId).catch(() => {});
    // Notify receiver confirmation
    notifyGiftReceived(receiverId, 'Gift', result.giftId).catch(() => {});

    res.status(200).json({ message: 'Gift claimed successfully!', result });
  } catch (error) {
    next(error);
  }
};

export const cancelGift = async (req, res, next) => {
  try {
    const giftId = parseInt(req.params.id);
    const senderId = req.user.userId;
    const result = await giftsService.cancelGift(giftId, senderId);
    res.status(200).json({ message: 'Gift cancelled successfully', gift: result });
  } catch (error) {
    next(error);
  }
};

export const previewGiftByToken = async (req, res, next) => {
  try {
    const gift = await giftsService.getGiftByToken(req.params.token);
    if (!gift) return res.status(404).json({ message: 'Gift not found' });

    const isExpired = new Date() > new Date(gift.expires_at);
    res.status(200).json({
      ...gift,
      is_expired: isExpired,
      claimable: !isExpired && !gift.is_cancelled && gift.current_receivers < gift.max_receivers
    });
  } catch (error) {
    next(error);
  }
};

export const listReceivedGifts = async (req, res, next) => {
  try {
    const sender = await userService.getUserProfile(req.user.userId);
    const gifts = await giftsService.getReceivedGifts(sender.email);
    res.status(200).json(gifts);
  } catch (error) {
    next(error);
  }
};

export const listSentGifts = async (req, res, next) => {
  try {
    const gifts = await giftsService.getSentGifts(req.user.userId);
    res.status(200).json(gifts);
  } catch (error) {
    next(error);
  }
};

export const getGiftDetail = async (req, res, next) => {
  try {
    const sender = await userService.getUserProfile(req.user.userId);
    const gift = await giftsService.getGiftByIdForUser(
      req.params.id,
      req.user.userId,
      sender.email
    );

    if (!gift) {
      return res.status(404).json({ message: 'Gift not found.' });
    }
    res.status(200).json(gift);
  } catch (error) {
    next(error);
  }
};

export const openGift = async (req, res, next) => {
  try {
    const sender = await userService.getUserProfile(req.user.userId);
    const gift = await giftsService.markAsOpened(req.params.id, sender.email);
    if (!gift) {
      return res.status(404).json({ message: 'Gift not found or already opened.' });
    }
    res.status(200).json({ message: 'Gift opened!', gift });
  } catch (error) {
    next(error);
  }
};

export const getPendingCount = async (req, res, next) => {
  try {
    const sender = await userService.getUserProfile(req.user.userId);
    const count = await giftsService.countPendingGifts(sender.email);
    res.status(200).json({ count });
  } catch (error) {
    next(error);
  }
};
