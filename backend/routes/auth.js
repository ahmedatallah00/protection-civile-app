const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Admin = require('../models/Admin');
const OtpSession = require('../models/OtpSession');
const { authenticate, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Helper: Generate JWT
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// POST /auth/send-otp
router.post('/send-otp', async (req, res) => {
  try {
    const { phone, cin } = req.body;

    if (!phone || !cin) {
      return res.status(400).json({ success: false, message: 'Le numéro de téléphone et la CIN sont requis.' });
    }

    const cleanPhone = phone.trim().startsWith('+') ? phone.trim() : (phone.trim().length === 8 ? '+216' + phone.trim() : phone.trim());
    const cleanCin = cin.toUpperCase().trim();

    // Validate that CIN is unique
    const existingCin = await User.findOne({ cin: cleanCin });
    if (existingCin) {
      return res.status(400).json({ success: false, message: 'Un compte avec ce CIN existe déjà.' });
    }

    // Validate that Phone is unique
    const existingPhone = await User.findOne({ phone: cleanPhone });
    if (existingPhone) {
      return res.status(400).json({ success: false, message: 'Ce numéro de téléphone est déjà enregistré.' });
    }

    // Generate random 6-digit OTP code
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Set expiry (5 minutes from now)
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    // Save/Overwrite OTP session for this phone number
    await OtpSession.findOneAndDelete({ phone: cleanPhone });
    const otpSession = new OtpSession({
      phone: cleanPhone,
      code: otpCode,
      expiresAt,
    });
    await otpSession.save();

    // Print to server console (Simulated SMS Gateway)
    console.log(`\n======================================================`);
    console.log(`📱 SMS OTP Gateway Simulator:`);
    console.log(`   Pour le numéro: ${cleanPhone}`);
    console.log(`   Votre Code OTP: ${otpCode}`);
    console.log(`======================================================\n`);

    res.json({
      success: true,
      message: 'Code de vérification envoyé.',
      debugOtp: otpCode // Included in response payload for easier debug/testing
    });
  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi du code OTP.' });
  }
});

// POST /auth/register
router.post('/register', async (req, res) => {
  try {
    const {
      fullName,
      cin,
      phone,
      email,
      password,
      governorate,
      delegation,
      address,
      bloodType,
      age,
      medicalInfo,
      emergencyContact,
      consentGiven,
      otpCode,
      isVolunteer,
    } = req.body;

    // Validate required fields
    if (!fullName || !cin || !phone || !password || !governorate || !delegation || !bloodType || age === undefined || age === null || age === '' || !emergencyContact || !consentGiven) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
      });
    }

    if (!otpCode) {
      return res.status(400).json({
        success: false,
        message: 'Le code OTP de vérification est requis.',
      });
    }

    const cleanPhone = phone.trim().startsWith('+') ? phone.trim() : (phone.trim().length === 8 ? '+216' + phone.trim() : phone.trim());

    // Verify OTP session
    const otpSession = await OtpSession.findOne({ phone: cleanPhone });
    if (!otpSession) {
      return res.status(400).json({
        success: false,
        message: 'Aucun code OTP envoyé pour ce numéro ou le code a expiré.',
      });
    }

    if (otpSession.code !== otpCode.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Le code OTP saisi est incorrect.',
      });
    }

    if (!consentGiven) {
      return res.status(400).json({
        success: false,
        message: 'User consent is required',
      });
    }

    // Check CIN uniqueness
    const existingUser = await User.findOne({ cin: cin.toUpperCase() });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'A user with this CIN already exists',
      });
    }

    // OTP verified successfully! Delete it to prevent re-use
    await OtpSession.deleteOne({ _id: otpSession._id });

    // Create user (password will be hashed by pre-save hook)
    const user = new User({
      fullName: fullName.trim(),
      cin: cin.toUpperCase().trim(),
      phone: phone.trim().startsWith('+') ? phone.trim() : (phone.trim().length === 8 ? '+216' + phone.trim() : phone.trim()),
      email: email ? email.toLowerCase().trim() : undefined,
      passwordHash: password,
      governorate: governorate.trim(),
      delegation: delegation.trim(),
      address: address ? address.trim() : undefined,
      bloodType,
      age: parseInt(age),
      medicalInfo: medicalInfo ? medicalInfo.trim() : '',
      emergencyContact: {
        name: emergencyContact.name.trim(),
        phone: emergencyContact.phone.trim().startsWith('+') ? emergencyContact.phone.trim() : (emergencyContact.phone.trim().length === 8 ? '+216' + emergencyContact.phone.trim() : emergencyContact.phone.trim()),
      },
      consentGiven: true,
      isVolunteer: isVolunteer === true || isVolunteer === 'true',
    });

    await user.save();
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      token,
      user: user.toSafeObject(),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'CIN already registered' });
    }
    console.error('Register error:', error);
    res.status(500).json({ success: false, message: 'Server error during registration' });
  }
});

// POST /auth/login
router.post('/login', async (req, res) => {
  try {
    const { identifier, password } = req.body;

    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'CIN/Phone and password are required',
      });
    }

    // 1. Try to find in Admin collection first
    const escapedIdentifier = identifier.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    let user = await Admin.findOne({
      fullName: new RegExp('^' + escapedIdentifier + '$', 'i')
    });
    
    let isAdminUser = false;
    
    if (user) {
      const isPasswordValid = await user.comparePassword(password);
      if (isPasswordValid) {
        isAdminUser = true;
      } else {
        // Clear user if password didn't match to try citizen search
        user = null;
      }
    }

    // 2. If not an Admin, search in User (citizen) collection by phone number
    if (!isAdminUser) {
      const searchPhone = identifier.trim();
      const phoneConditions = [{ phone: searchPhone }];
      if (/^\d{8}$/.test(searchPhone)) {
        phoneConditions.push({ phone: '+216' + searchPhone });
      }

      user = await User.findOne({
        $or: phoneConditions
      });

      if (!user || !user.isActive) {
        return res.status(401).json({ success: false, message: 'Numéro de téléphone ou CIN incorrect' });
      }

      // Check if password matches their CIN (case-insensitive) OR their password hash
      const isCinMatch = (password.toUpperCase().trim() === user.cin);
      let isBcryptMatch = false;
      try {
        isBcryptMatch = await user.comparePassword(password);
      } catch (err) {
        // Ignore bcrypt compare failures
      }

      const isPasswordValid = isCinMatch || isBcryptMatch;
      if (!isPasswordValid) {
        return res.status(401).json({ success: false, message: 'Numéro de téléphone ou CIN incorrect' });
      }
    }

    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: user.toSafeObject(),
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
});

// GET /auth/users - Get all registered users (requires admin auth)
router.get('/users', authenticate, requireAdmin, async (req, res) => {
  try {
    const users = await User.find({ isActive: true })
      .select('-passwordHash')
      .sort({ createdAt: -1 });
    res.json({ success: true, users });
  } catch (error) {
    console.error('List users error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve users' });
  }
});

// GET /auth/me - Get current user profile
router.get('/me', authenticate, async (req, res) => {

  res.json({ success: true, user: req.user.toSafeObject ? req.user.toSafeObject() : req.user });
});

// PUT /auth/me - Update profile
router.put('/me', authenticate, async (req, res) => {
  try {
    const allowedUpdates = ['fullName', 'phone', 'email', 'address', 'delegation', 'emergencyContact', 'age', 'medicalInfo', 'isVolunteer'];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    if (updates.phone !== undefined) {
      const p = updates.phone.trim();
      updates.phone = p.startsWith('+') ? p : (p.length === 8 ? '+216' + p : p);
    }
    if (updates.emergencyContact !== undefined && updates.emergencyContact.phone !== undefined) {
      const ep = updates.emergencyContact.phone.trim();
      updates.emergencyContact.phone = ep.startsWith('+') ? ep : (ep.length === 8 ? '+216' + ep : ep);
    }
    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    }).select('-passwordHash');

    res.json({ success: true, user });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile' });
  }
});

// PUT /auth/users/:id - Update specific user's details (admin perspective)
router.put('/users/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const allowedUpdates = ['fullName', 'phone', 'email', 'address', 'delegation', 'bloodType', 'age', 'medicalInfo', 'emergencyContact', 'isVolunteer'];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    if (updates.phone !== undefined) {
      const p = updates.phone.trim();
      updates.phone = p.startsWith('+') ? p : (p.length === 8 ? '+216' + p : p);
    }
    if (updates.emergencyContact !== undefined && updates.emergencyContact.phone !== undefined) {
      const ep = updates.emergencyContact.phone.trim();
      updates.emergencyContact.phone = ep.startsWith('+') ? ep : (ep.length === 8 ? '+216' + ep : ep);
    }
    const user = await User.findByIdAndUpdate(req.params.id, updates, {
      new: true,
      runValidators: true,
    }).select('-passwordHash');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, user });
  } catch (error) {
    console.error('Update specific user error:', error);
    res.status(500).json({ success: false, message: 'Failed to update user' });
  }
});

// DELETE /auth/users/:id - Deactivate specific user (admin perspective)
router.delete('/users/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { isActive: false }, { new: true });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, message: 'User deactivated successfully' });
  } catch (error) {
    console.error('Deactivate specific user error:', error);
    res.status(500).json({ success: false, message: 'Failed to deactivate user' });
  }
});

module.exports = router;
