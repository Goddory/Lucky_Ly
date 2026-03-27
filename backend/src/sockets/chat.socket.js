import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import * as chatService from '../modules/chat/chat.service.js';

let io;

export function initSocketServer(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: env.corsOrigin,
      methods: ['GET', 'POST']
    }
  });

  // JWT auth middleware for socket connections
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
    if (!token) return next(new Error('Authentication required'));

    try {
      const decoded = jwt.verify(token, env.jwt.accessSecret);
      socket.userId = decoded.sub || decoded.userId;
      socket.username = decoded.username;
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`🔌 Socket connected: user ${socket.userId}`);

    // Auto-join personal room for direct notifications
    socket.join(`user_${socket.userId}`);

    // Join a chat room
    socket.on('join_room', (roomId) => {
      socket.join(`room_${roomId}`);
      console.log(`📍 User ${socket.userId} joined room ${roomId}`);
    });

    // Leave a chat room
    socket.on('leave_room', (roomId) => {
      socket.leave(`room_${roomId}`);
    });

    // Send message through socket
    socket.on('send_message', async (data, callback) => {
      try {
        const { roomId, receiverId, content, messageType, giftId } = data;

        const message = await chatService.sendMessage(
          roomId, socket.userId, receiverId,
          content, messageType || 'text', giftId || null
        );

        // Broadcast to the room (all participants)
        io.to(`room_${roomId}`).emit('new_message', {
          ...message,
          sender_name: socket.username
        });

        // Also notify receiver's personal room (for badge count)
        io.to(`user_${receiverId}`).emit('message_notification', {
          roomId,
          senderId: socket.userId,
          senderName: socket.username,
          content: messageType === 'gift' ? '🎁 Bạn nhận được một món quà!' : content,
          messageType
        });

        if (callback) callback({ success: true, message });
      } catch (err) {
        console.error('Socket send_message error:', err.message);
        if (callback) callback({ success: false, error: err.message });
      }
    });

    // Mark messages as read
    socket.on('mark_read', async (roomId) => {
      try {
        await chatService.markMessagesAsRead(roomId, socket.userId);
        io.to(`room_${roomId}`).emit('messages_read', {
          roomId,
          readBy: socket.userId
        });
      } catch (err) {
        console.error('Socket mark_read error:', err.message);
      }
    });

    // Typing indicator
    socket.on('typing', ({ roomId }) => {
      socket.to(`room_${roomId}`).emit('user_typing', {
        userId: socket.userId,
        username: socket.username
      });
    });

    socket.on('stop_typing', ({ roomId }) => {
      socket.to(`room_${roomId}`).emit('user_stop_typing', {
        userId: socket.userId
      });
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: user ${socket.userId}`);
    });
  });

  return io;
}

export function getIO() {
  if (!io) throw new Error('Socket.io not initialized');
  return io;
}

// Emit events to specific users (used by notification service)
export function emitToUser(userId, event, data) {
  if (!io) return;
  io.to(`user_${userId}`).emit(event, data);
}
