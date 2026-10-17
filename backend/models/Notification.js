const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    body: { type: String, required: true, trim: true },
    targetType: {
      type: String,
      enum: ['all', 'region', 'user', 'volunteers', 'non_volunteers'],
      required: true,
      default: 'all',
    },
    governorate: { type: String, trim: true }, // Populate if targetType is 'region'
    userPhone: { type: String, trim: true },   // Populate if targetType is 'user'
  },
  { timestamps: true }
);

// Index for query performance
notificationSchema.index({ targetType: 1 });
notificationSchema.index({ governorate: 1 });
notificationSchema.index({ userPhone: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
