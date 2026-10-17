const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const BLOOD_TYPES = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

const emergencyContactSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  phone: { type: String, required: true, trim: true },
});

const userSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true, trim: true },
    cin: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      uppercase: true,
    },
    phone: { type: String, required: true, trim: true },
    email: { type: String, required: false, trim: true, lowercase: true },
    passwordHash: { type: String, required: true },
    governorate: { type: String, required: true, trim: true },
    delegation: { type: String, required: true, trim: true },
    address: { type: String, trim: true },
    bloodType: {
      type: String,
      enum: BLOOD_TYPES,
      required: true,
    },
    age: { type: Number, required: true, min: 0 },
    medicalInfo: { type: String, trim: true, default: '' },
    emergencyContact: {
      type: emergencyContactSchema,
      required: true,
    },
    consentGiven: { type: Boolean, required: true, default: false },
    isVolunteer: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    isOnline: { type: Boolean, default: false },
    lastLatitude: { type: Number },
    lastLongitude: { type: Number },
    lastActiveAt: { type: Date },
  },
  { timestamps: true }
);

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});

// Compare password
userSchema.methods.comparePassword = async function (plainPassword) {
  return bcrypt.compare(plainPassword, this.passwordHash);
};

// Remove sensitive fields from JSON output
userSchema.methods.toSafeObject = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.__v;
  obj.role = 'user';
  return obj;
};

module.exports = mongoose.model('User', userSchema);
