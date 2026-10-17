const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true, trim: true, unique: true },
    passwordHash: { type: String, required: true },
  },
  { timestamps: true }
);

// Hash password before save
adminSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});

// Compare password
adminSchema.methods.comparePassword = async function (plainPassword) {
  // Support password either verbatim with leading space or trimmed
  const isMatch = await bcrypt.compare(plainPassword, this.passwordHash);
  if (isMatch) return true;
  
  const trimmed = plainPassword.trim();
  if (trimmed !== plainPassword) {
    const isTrimmedMatch = await bcrypt.compare(trimmed, this.passwordHash);
    if (isTrimmedMatch) return true;
  }
  
  // Try adding a leading space if trimmed version matches
  if (!plainPassword.startsWith(' ')) {
    const spaceAdded = ' ' + plainPassword;
    return bcrypt.compare(spaceAdded, this.passwordHash);
  }
  
  return false;
};

// Remove sensitive fields from JSON output
adminSchema.methods.toSafeObject = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.__v;
  obj.role = 'admin'; // explicitly attach admin role tag
  return obj;
};

module.exports = mongoose.model('Admin', adminSchema);
