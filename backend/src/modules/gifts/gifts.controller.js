import * as giftsService from './gifts.service.js';
import * as userService from '../user/user.service.js';

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
