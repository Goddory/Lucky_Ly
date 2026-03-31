import { AvatarSync, UserSync, DesignSync } from '../models/sync.model.js';

/**
 * PUSH API: Client gửi các record (chưa được sync) lên Server
 * Endpoint: POST /api/sync/push/:type (type: avatars, users, designs)
 */
export const pushSyncData = async (req, res) => {
  try {
    const userId = req.user?.userId;
    const { type } = req.params;
    
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const { records } = req.body;
    if (!Array.isArray(records)) {
      return res.status(400).json({ message: 'Invalid records format. Array required.' });
    }

    let Model;
    let bulkOps = [];

    switch (type) {
      case 'avatars':
        Model = AvatarSync;
        bulkOps = records.map(record => ({
          updateOne: {
            filter: { userId, localId: record.localId || record.local_id },
            update: {
              $set: {
                url: record.url,
                localPath: record.localPath || record.local_path,
                clientUpdatedAt: record.clientUpdatedAt || record.client_updated_at,
                isDeleted: record.isDeleted || record.is_deleted || false
              }
            },
            upsert: true
          }
        }));
        break;

      case 'users':
        Model = UserSync;
        bulkOps = records.map(record => ({
          updateOne: {
            filter: { userId },
            update: {
              $set: {
                fullName: record.fullName || record.full_name,
                email: record.email,
                avatarUrl: record.avatarUrl || record.avatar_url,
                clientUpdatedAt: record.clientUpdatedAt || record.client_updated_at
              }
            },
            upsert: true
          }
        }));
        break;

      case 'designs':
        Model = DesignSync;
        bulkOps = records.map(record => ({
          updateOne: {
            filter: { userId, localId: record.localId || record.local_id },
            update: {
              $set: {
                title: record.title,
                data: record.data,
                clientUpdatedAt: record.clientUpdatedAt || record.client_updated_at,
                isDeleted: record.isDeleted || record.is_deleted || false
              }
            },
            upsert: true
          }
        }));
        break;

      default:
        return res.status(400).json({ message: 'Invalid sync type' });
    }

    if (bulkOps.length > 0) {
      await Model.bulkWrite(bulkOps);
    }

    res.json({ success: true, syncedCount: bulkOps.length });
  } catch (error) {
    console.error('[Sync Push Error]:', error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
};

/**
 * PULL API: Client yêu cầu tải các record bị thay đổi sau lastSyncTime
 * Endpoint: GET /api/sync/pull/all
 * Query expect: ?lastSyncTime=2024-01-01T00:00:00Z
 */
export const pullSyncData = async (req, res) => {
  try {
    const userId = req.user?.userId;
    const { type } = req.params;
    
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const lastSyncTime = req.query.lastSyncTime;
    const filter = { userId };
    if (lastSyncTime) {
      filter.updatedAt = { $gt: new Date(lastSyncTime) };
    }

    // If type is 'all', pull everything. Otherwise pull specific type.
    if (type === 'all') {
      const [avatars, users, designs] = await Promise.all([
        AvatarSync.find(filter).lean(),
        UserSync.find(filter).lean(),
        DesignSync.find(filter).lean()
      ]);

      return res.json({
        success: true,
        data: {
          avatars,
          users,
          designs
        },
        timestamp: new Date().toISOString()
      });
    }

    // Single type pull
    let Model;
    switch (type) {
      case 'avatars': Model = AvatarSync; break;
      case 'users': Model = UserSync; break;
      case 'designs': Model = DesignSync; break;
      default: return res.status(400).json({ message: 'Invalid sync type' });
    }

    const updates = await Model.find(filter).lean();
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
