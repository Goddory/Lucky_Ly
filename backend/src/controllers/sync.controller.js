import { AvatarSync } from '../models/avatar_sync.model.js';

/**
 * PUSH API: Client gửi các record (chưa được sync) lên Server
 * Body expect: { records: [{ localId, url, localPath, clientUpdatedAt, isDeleted }] }
 */
export const pushSyncData = async (req, res) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const { records } = req.body;
    if (!Array.isArray(records)) {
      return res.status(400).json({ message: 'Invalid records format. Array required.' });
    }

    const bulkOps = records.map(record => ({
      updateOne: {
        filter: { userId, localId: record.localId },
        update: {
          $set: {
            url: record.url,
            localPath: record.localPath,
            clientUpdatedAt: record.clientUpdatedAt,
            isDeleted: record.isDeleted || false
          }
        },
        upsert: true
      }
    }));

    if (bulkOps.length > 0) {
      await AvatarSync.bulkWrite(bulkOps);
    }

    res.json({ success: true, syncedCount: bulkOps.length });
  } catch (error) {
    console.error('[Sync Push Error]:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

/**
 * PULL API: Client yêu cầu tải các record bị thay đổi sau lastSyncTime
 * Query expect: ?lastSyncTime=2024-01-01T00:00:00Z
 */
export const pullSyncData = async (req, res) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const lastSyncTime = req.query.lastSyncTime;
    
    // Nếu client gửi lastSyncTime, lấy các records update sau đó, nếu không lấy tất cả
    const filter = { userId };
    if (lastSyncTime) {
      filter.updatedAt = { $gt: new Date(lastSyncTime) };
    }

    const updates = await AvatarSync.find(filter).lean();

    res.json({
      success: true,
      data: updates,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('[Sync Pull Error]:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};
