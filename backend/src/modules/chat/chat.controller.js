import * as chatService from './chat.service.js';

export const getRoomOrCreate = async (req, res, next) => {
  try {
    const { otherUserId } = req.body;
    if (!otherUserId) return res.status(400).json({ message: 'otherUserId is required' });

    const roomId = await chatService.getOrCreatePrivateRoom(req.user.userId, otherUserId);
    res.status(200).json({ room_id: roomId });
  } catch (error) {
    next(error);
  }
};

export const postMessage = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const { content, messageType, giftId, receiverId } = req.body;

    if (!content && messageType !== 'gift') {
      return res.status(400).json({ message: 'content is required' });
    }
    if (!receiverId) {
      return res.status(400).json({ message: 'receiverId is required' });
    }

    const message = await chatService.sendMessage(
      roomId, req.user.userId, receiverId,
      content, messageType || 'text', giftId || null
    );
    res.status(201).json(message);
  } catch (error) {
    next(error);
  }
};

export const getMessages = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const { limit, beforeId } = req.query;

    const messages = await chatService.getMessages(
      roomId, req.user.userId,
      limit ? parseInt(limit) : 50,
      beforeId || null
    );
    res.status(200).json(messages);
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (req, res, next) => {
  try {
    await chatService.markMessagesAsRead(req.params.roomId, req.user.userId);
    res.status(200).json({ message: 'Messages marked as read' });
  } catch (error) {
    next(error);
  }
};

export const listRooms = async (req, res, next) => {
  try {
    const rooms = await chatService.getUserRooms(req.user.userId);
    res.status(200).json(rooms);
  } catch (error) {
    next(error);
  }
};
