import mongoose from 'mongoose';

const avatarSyncSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true
  },
  localId: {
    type: String,
    required: true
  },
  url: {
    type: String,
  },
  localPath: {
    type: String,
  },
  clientUpdatedAt: {
    type: Date,
    required: true
  },
  isDeleted: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

// Tối ưu query đồng bộ
avatarSyncSchema.index({ userId: 1, updatedAt: 1 });

export const AvatarSync = mongoose.model('AvatarSync', avatarSyncSchema);
