const mongoose = require('mongoose');

const safetyTipSchema = new mongoose.Schema({
  title: { type: String, required: true },
  category: { type: String, required: true },
  description: { type: String, required: true },
  dos: [{ type: String }],
  donts: [{ type: String }],
  iconName: { type: String, required: true }, // e.g., 'local_fire_department', 'water_damage'
  
  titleAr: { type: String, required: true },
  categoryAr: { type: String, required: true },
  descriptionAr: { type: String, required: true },
  dosAr: [{ type: String }],
  dontsAr: [{ type: String }]
}, { timestamps: true });

module.exports = mongoose.model('SafetyTip', safetyTipSchema);
