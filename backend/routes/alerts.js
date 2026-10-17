const express = require('express');
const Alert = require('../models/Alert');
const { authenticate, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /alerts - Get all active alerts
router.get('/', async (req, res) => {
  try {
    const now = new Date();
    const alerts = await Alert.find({
      isActive: true,
      expiryDate: { $gt: now },
    })
      .sort({ severity: -1, createdAt: -1 })
      .limit(50);

    res.json({ success: true, alerts });
  } catch (error) {
    console.error('List alerts error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve alerts' });
  }
});

// GET /alerts/zone/:governorate - Get alerts for a specific governorate
router.get('/zone/:governorate', async (req, res) => {
  try {
    const { governorate } = req.params;
    const now = new Date();

    const alerts = await Alert.find({
      isActive: true,
      expiryDate: { $gt: now },
      $or: [
        { governorate: governorate },
        { governorate: 'all' }, // nationwide alerts
      ],
    })
      .sort({ severity: -1, createdAt: -1 })
      .limit(50);

    res.json({ success: true, governorate, alerts });
  } catch (error) {
    console.error('Zone alerts error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve alerts for this zone' });
  }
});

// GET /alerts/:id - Get single alert
router.get('/:id', async (req, res) => {
  try {
    const alert = await Alert.findById(req.params.id);
    if (!alert) {
      return res.status(404).json({ success: false, message: 'Alert not found' });
    }
    res.json({ success: true, alert });
  } catch (error) {
    console.error('Get alert error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve alert' });
  }
});

// POST /alerts - Create alert (admin only - simplified, no role system)
router.post('/', authenticate, requireAdmin, async (req, res) => {
  try {
    const { title, message, governorate, severity, category, expiryDate } = req.body;

    if (!title || !message || !governorate || !severity || !expiryDate) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const alert = new Alert({
      title,
      message,
      governorate,
      severity,
      category: category || 'general',
      expiryDate: new Date(expiryDate),
    });

    await alert.save();

    // Emit Socket.io real-time event
    const io = req.app.get('io');
    if (io) {
      const room = `governorate_${governorate.trim().toLowerCase()}`;
      io.to(room).emit('new_alert', alert);
      if (governorate.trim().toLowerCase() === 'all') {
        io.emit('new_alert', alert);
      }
    }

    res.status(201).json({ success: true, alert });
  } catch (error) {
    console.error('Create alert error:', error);
    res.status(500).json({ success: false, message: 'Failed to create alert' });
  }
});

module.exports = router;
