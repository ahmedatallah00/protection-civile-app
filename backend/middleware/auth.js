const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Admin = require('../models/Admin');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Try finding in Admin collection first
    let user = await Admin.findById(decoded.userId).select('-passwordHash');
    
    // If not found in Admin, look in User (citizen) collection
    if (!user) {
      user = await User.findById(decoded.userId).select('-passwordHash');
      if (!user || !user.isActive) {
        return res.status(401).json({ success: false, message: 'User not found or deactivated' });
      }
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired' });
    }
    next(error);
  }
};

const requireAdmin = (req, res, next) => {
  if (req.user && (req.user.role === 'admin' || req.user.constructor.modelName === 'Admin')) {
    return next();
  }
  return res.status(403).json({ success: false, message: 'Accès interdit. Réservé aux administrateurs.' });
};

module.exports = { authenticate, requireAdmin };
