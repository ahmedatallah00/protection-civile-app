const mongoose = require('mongoose');

const liveSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    videoUrl: { type: String, required: true },
    isActive: { type: Boolean, default: true },
    streamId: { type: String },
    frameCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Live', liveSchema);
