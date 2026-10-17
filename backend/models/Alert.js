const mongoose = require('mongoose');

const SEVERITY_LEVELS = ['low', 'medium', 'high', 'critical'];

const alertSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    governorate: { type: String, required: true, trim: true }, // zone-based
    severity: {
      type: String,
      enum: SEVERITY_LEVELS,
      required: true,
      default: 'medium',
    },
    category: {
      type: String,
      enum: ['flood', 'fire', 'weather', 'earthquake', 'pollution', 'general'],
      default: 'general',
    },
    isActive: { type: Boolean, default: true },
    expiryDate: { type: Date, required: true },
    source: { type: String, default: 'Protection Civile Tunisie' },
    createdBy: { type: String, default: 'System' },
  },
  { timestamps: true }
);

// Index for zone-based lookups
alertSchema.index({ governorate: 1, isActive: 1 });
alertSchema.index({ expiryDate: 1 }, { expireAfterSeconds: 0 }); // TTL index

module.exports = mongoose.model('Alert', alertSchema);
