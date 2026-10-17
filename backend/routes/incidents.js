const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Incident = require('../models/Incident');
const Notification = require('../models/Notification');
const { authenticate, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Configure multer for media uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, `incident-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = /jpeg|jpg|png|gif|mp4|mov|avi|mkv|webm|mp3|wav|m4a|aac|3gp|ogg|caf/;
  const extname = allowed.test(path.extname(file.originalname).toLowerCase());
  const mimeSplit = file.mimetype ? file.mimetype.split('/') : [];
  const mimetype = mimeSplit.length > 1 ? allowed.test(mimeSplit[1]) : false;
  
  if (extname || mimetype || file.mimetype === 'application/octet-stream') {
    cb(null, true);
  } else {
    cb(new Error('Only image, video and audio files are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB limit
});

// POST /incidents - Report a new incident (requires auth)
router.post('/', authenticate, upload.fields([{ name: 'media', maxCount: 1 }, { name: 'voice', maxCount: 1 }]), async (req, res) => {
  try {
    const { type, description, latitude, longitude, accuracy, address } = req.body;

    if (!type) {
      return res.status(400).json({ success: false, message: 'Incident type is required' });
    }
    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, message: 'GPS location is required' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ success: false, message: 'Invalid GPS coordinates' });
    }

    // ─── GEOGRAPHIC DEDUPLICATION (200m Same Day, Same Type) ───
    let parentId = null;
    try {
      const now = new Date();
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
      const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

      // Find any potential parent incidents of the same type reported today
      const candidates = await Incident.find({
        type,
        createdAt: { $gte: startOfDay, $lte: endOfDay },
        parentIncident: null // Only group under parent/original reports
      });

      // Haversine formula helper
      function getDistance(lat1, lon1, lat2, lon2) {
        const R = 6371000; // Earth radius in meters
        const phi1 = lat1 * Math.PI / 180;
        const phi2 = lat2 * Math.PI / 180;
        const deltaPhi = (lat2 - lat1) * Math.PI / 180;
        const deltaLambda = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
                  Math.cos(phi1) * Math.cos(phi2) *
                  Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c; // distance in meters
      }

      for (const cand of candidates) {
        if (cand.geolocation && cand.geolocation.latitude && cand.geolocation.longitude) {
          const dist = getDistance(lat, lng, cand.geolocation.latitude, cand.geolocation.longitude);
          if (dist <= 200) {
            parentId = cand._id;
            break; // Join the first matching incident group
          }
        }
      }
    } catch (err) {
      console.error('Deduplication check error:', err);
    }

    let mediaUrl = null;
    let mediaType = null;
    if (req.files && req.files['media'] && req.files['media'][0]) {
      const mediaFile = req.files['media'][0];
      mediaUrl = `/uploads/${mediaFile.filename}`;
      mediaType = mediaFile.mimetype.startsWith('video') ? 'video' : 'image';
    }

    let voiceUrl = null;
    if (req.files && req.files['voice'] && req.files['voice'][0]) {
      const voiceFile = req.files['voice'][0];
      voiceUrl = `/uploads/${voiceFile.filename}`;
    }

    const incident = new Incident({
      type,
      description: description ? description.trim() : undefined,
      geolocation: {
        latitude: lat,
        longitude: lng,
        accuracy: accuracy ? parseFloat(accuracy) : undefined,
        address: address ? address.trim() : undefined,
      },
      mediaUrl,
      mediaType,
      voiceUrl,
      reporter: req.user._id,
      governorate: req.user.governorate,
      parentIncident: parentId,
    });

    await incident.save();
    await incident.populate('reporter', 'fullName phone cin bloodType age medicalInfo');

    // Broadcast new incident to all connected sockets
    const io = req.app.get('io');
    if (io) {
      io.emit('new_incident', incident);
    }

    // Automatically send a targeted thank-you notification to the citizen reporter
    try {
      const isSos = type === 'SOS';
      const notifTitle = isSos
        ? 'Alerte SOS reçue - Merci pour votre civisme ! 🛡️'
        : 'Signalement reçu - Merci pour votre civisme ! 🛡️';

      const notifBody = isSos
        ? "Merci d'être un bon citoyen ! Votre alerte SOS a bien été transmise à la Protection Civile. Nos équipes sont informées et traitent votre urgence en priorité. Merci pour votre soutien !"
        : `Merci d'être un bon citoyen ! Votre signalement d'incident (${type}) a bien été transmis à la Protection Civile. Nos équipes la traitent en priorité. Merci pour votre soutien !`;

      const userNotification = new Notification({
        title: notifTitle,
        body: notifBody,
        targetType: 'user',
        userPhone: req.user.phone,
      });

      await userNotification.save();

      // Emit real-time notification strictly to the reporter's user room
      if (io) {
        const userRoom = `user_${req.user._id.toString()}`;
        io.to(userRoom).emit('new_notification', userNotification);
      }
    } catch (notifErr) {
      console.error('Auto notification error:', notifErr);
    }

    res.status(201).json({
      success: true,
      message: 'Incident reported successfully',
      incident,
    });
  } catch (error) {
    console.error('Create incident error:', error);
    res.status(500).json({ success: false, message: 'Failed to report incident' });
  }
});

// GET /incidents - List incidents (requires admin auth, optionally filter by governorate)
router.get('/', authenticate, requireAdmin, async (req, res) => {
  try {
    const { governorate, status, page = 1, limit = 20 } = req.query;
    const filter = {};

    if (governorate) filter.governorate = governorate;
    if (status) filter.status = status;
    
    // Only fetch parent/original reports in the main list
    filter.parentIncident = null;

    const incidents = await Incident.find(filter)
      .populate('reporter', 'fullName phone cin bloodType age medicalInfo')
      .sort({ createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    // For each parent incident, query and attach child duplicate reports
    const groupedIncidents = await Promise.all(incidents.map(async (inc) => {
      const children = await Incident.find({ parentIncident: inc._id })
        .populate('reporter', 'fullName phone cin bloodType age medicalInfo')
        .sort({ createdAt: -1 });

      return {
        ...inc.toObject(),
        duplicates: children || []
      };
    }));

    const total = await Incident.countDocuments(filter);

    res.json({
      success: true,
      incidents: groupedIncidents,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('List incidents error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve incidents' });
  }
});

// GET /incidents/mine - Get current user's incidents
router.get('/mine', authenticate, async (req, res) => {
  try {
    const incidents = await Incident.find({ reporter: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({ success: true, incidents });
  } catch (error) {
    console.error('Get my incidents error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve your incidents' });
  }
});

// GET /incidents/:id - Get single incident
router.get('/:id', authenticate, async (req, res) => {
  try {
    const incident = await Incident.findById(req.params.id).populate(
      'reporter',
      'fullName phone cin bloodType age medicalInfo'
    );
    if (!incident) {
      return res.status(404).json({ success: false, message: 'Incident not found' });
    }
    res.json({ success: true, incident });
  } catch (error) {
    console.error('Get incident error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve incident' });
  }
});

// PATCH /incidents/:id - Update incident status or details (requires admin auth)
router.patch('/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const { status, assignedUnit } = req.body;
    const updates = {};
    if (status) updates.status = status;
    if (assignedUnit !== undefined) updates.assignedUnit = assignedUnit;
    if (status === 'resolved') updates.resolvedAt = new Date();

    const incident = await Incident.findByIdAndUpdate(req.params.id, updates, {
      new: true,
      runValidators: true,
    }).populate('reporter', 'fullName phone cin bloodType age medicalInfo');

    if (!incident) {
      return res.status(404).json({ success: false, message: 'Incident not found' });
    }

    res.json({ success: true, message: 'Incident updated successfully', incident });
  } catch (error) {
    console.error('Update incident error:', error);
    res.status(500).json({ success: false, message: 'Failed to update incident' });
  }
});

module.exports = router;
