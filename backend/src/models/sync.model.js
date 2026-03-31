import mongoose from 'mongoose';

// Avatar Sync
const avatarSyncSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  localId: { type: String, required: true },
  url: { type: String },
  localPath: { type: String },
  clientUpdatedAt: { type: Date, required: true },
  isDeleted: { type: Boolean, default: false }
}, { timestamps: true });
avatarSyncSchema.index({ userId: 1, localId: 1 }, { unique: true });

// User Sync (Profile info)
const userSyncSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true }, // The ID of the user record
  fullName: { type: String },
  email: { type: String },
  avatarUrl: { type: String },
  clientUpdatedAt: { type: Date, required: true }
}, { timestamps: true });
userSyncSchema.index({ userId: 1 }, { unique: true });

// Design Sync
const designSyncSchema = new mongoose.Schema({
  userId: { type: String, required: true, index: true },
  localId: { type: String, required: true },
  title: { type: String },
  data: { type: String }, // JSON blob or text data
  clientUpdatedAt: { type: Date, required: true },
  isDeleted: { type: Boolean, default: false }
}, { timestamps: true });
designSyncSchema.index({ userId: 1, localId: 1 }, { unique: true });

export const AvatarSync = mongoose.model('AvatarSync', avatarSyncSchema);
export const UserSync = mongoose.model('UserSync', userSyncSchema);
export const DesignSync = mongoose.model('DesignSync', designSyncSchema);
