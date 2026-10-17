const mongoose = require('mongoose');

const INCIDENT_TYPES = ['fire', 'accident', 'flood', 'collapse', 'rescue', 'other'];
const INCIDENT_STATUS = ['pending', 'dispatched', 'resolved', 'closed'];

const geolocationSchema = new mongoose.Schema({
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  accuracy: { type: Number },
  address: { type: String },
});

const incidentSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: INCIDENT_TYPES,
      required: true,
    },
    description: { type: String, trim: true },
    geolocation: {
      type: geolocationSchema,
      required: true,
    },
    mediaUrl: { type: String }, // URL of uploaded photo/video
    mediaType: { type: String, enum: ['image', 'video', null] },
    voiceUrl: { type: String }, // URL of uploaded voice note
    status: {
      type: String,
      enum: INCIDENT_STATUS,
      default: 'pending',
    },
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    governorate: { type: String, required: true }, // Denormalized for fast query
    assignedUnit: { type: String },
    resolvedAt: { type: Date },
    parentIncident: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Incident',
      default: null,
    },
  },
  { timestamps: true }
);

// Index for geo queries and governorate filtering
incidentSchema.index({ governorate: 1, createdAt: -1 });
incidentSchema.index({ reporter: 1 });

module.exports = mongoose.model('Incident', incidentSchema);
