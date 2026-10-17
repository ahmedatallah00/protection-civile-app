const mongoose = require('mongoose');

const recordedLiveSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    streamId: { type: String, required: true },
    frameCount: { type: Number, default: 0 },
    duration: { type: Number, default: 0 }, // in seconds
  },
  { timestamps: true }
);

module.exports = mongoose.model('RecordedLive', recordedLiveSchema);
