const express = require('express');
const router = express.Router();
const Live = require('../models/Live');
const RecordedLive = require('../models/RecordedLive');
const { authenticate } = require('../middleware/auth');
const fs = require('fs');
const path = require('path');

const activeFrames = new Map(); // Store current JPEG frame buffer for each active stream

const TEST_VIDEOS = [
  '/uploads/live_1.mp4',
  '/uploads/live_2.mp4',
  '/uploads/live_3.mp4',
  '/uploads/live_4.mp4'
];

// POST /lives/start - Start a live stream (requires user auth)
router.post('/start', authenticate, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'Coordonnées requises.' });
    }

    // Delete any existing active streams for this citizen
    await Live.deleteMany({ user: req.user._id });

    // Generate unique stream recording directory
    const streamId = `stream_${Date.now()}_${req.user._id}`;
    const recordingsDir = path.join(__dirname, '../uploads/recordings', streamId);
    fs.mkdirSync(recordingsDir, { recursive: true });

    // Pick a random emergency loop video (fallback)
    const randomVideo = TEST_VIDEOS[Math.floor(Math.random() * TEST_VIDEOS.length)];

    const live = new Live({
      user: req.user._id,
      latitude,
      longitude,
      videoUrl: randomVideo,
      isActive: true,
      streamId,
      frameCount: 0
    });

    await live.save();
    await live.populate('user', 'fullName phone cin bloodType age medicalInfo governorate delegation');

    // Broadcast live_started and update count
    const io = req.app.get('io');
    if (io) {
      io.emit('live_started', live);
      const activeCount = await Live.countDocuments({ isActive: true });
      io.emit('live_count_update', { count: activeCount });
    }

    res.status(201).json({
      success: true,
      message: 'Direct démarré avec succès.',
      live
    });
  } catch (error) {
    console.error('Start live error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du démarrage du direct.' });
  }
});

// POST /lives/stop - Stop a live stream (requires user auth)
router.post('/stop', authenticate, async (req, res) => {
  try {
    const live = await Live.findOne({ user: req.user._id, isActive: true });
    if (live) {
      const duration = Math.round((Date.now() - live.createdAt.getTime()) / 1000);
      
      // Save recorded live stream information
      const recorded = new RecordedLive({
        user: live.user,
        latitude: live.latitude,
        longitude: live.longitude,
        streamId: live.streamId,
        frameCount: live.frameCount,
        duration: duration > 0 ? duration : 1
      });
      await recorded.save();
    }

    await Live.deleteMany({ user: req.user._id });
    activeFrames.delete(req.user._id.toString());

    // Broadcast live_stopped and update count
    const io = req.app.get('io');
    if (io) {
      io.emit('live_stopped', { userId: req.user._id });
      const activeCount = await Live.countDocuments({ isActive: true });
      io.emit('live_count_update', { count: activeCount });
    }

    res.json({ success: true, message: 'Direct arrêté avec succès.' });
  } catch (error) {
    console.error('Stop live error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'arrêt du direct.' });
  }
});

// GET /lives - List all active live streams (requires admin/user auth)
router.get('/', authenticate, async (req, res) => {
  try {
    const lives = await Live.find({ isActive: true })
      .populate('user', 'fullName phone cin bloodType age medicalInfo governorate delegation')
      .sort({ createdAt: -1 });
      
    res.json({ success: true, lives });
  } catch (error) {
    console.error('List lives error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du chargement des vidéos en direct.' });
  }
});

// GET /lives/recorded - List all recorded live streams
router.get('/recorded', authenticate, async (req, res) => {
  try {
    const recorded = await RecordedLive.find({})
      .populate('user', 'fullName phone cin bloodType age medicalInfo governorate delegation')
      .sort({ createdAt: -1 });
    res.json({ success: true, recorded });
  } catch (error) {
    console.error('List recorded lives error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du chargement des enregistrements.' });
  }
});

// DELETE /lives/recorded/:id - Delete a recorded live stream
router.delete('/recorded/:id', authenticate, async (req, res) => {
  try {
    const recorded = await RecordedLive.findById(req.params.id);
    if (!recorded) {
      return res.status(404).json({ success: false, message: 'Enregistrement non trouvé.' });
    }

    // Delete folder from disk
    const folderPath = path.join(__dirname, '../uploads/recordings', recorded.streamId);
    if (fs.existsSync(folderPath)) {
      fs.rmSync(folderPath, { recursive: true, force: true });
    }

    await recorded.deleteOne();
    res.json({ success: true, message: 'Enregistrement supprimé avec succès.' });
  } catch (error) {
    console.error('Delete recorded live error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression.' });
  }
});

// POST /lives/frame - Upload a single camera frame from the tablet
router.post('/frame', authenticate, express.raw({ type: 'image/jpeg', limit: '2mb' }), async (req, res) => {
  try {
    if (!req.body || req.body.length === 0) {
      return res.status(400).json({ success: false, message: 'Données d\'image requises.' });
    }
    activeFrames.set(req.user._id.toString(), req.body);

    // Save frame to disk
    const live = await Live.findOne({ user: req.user._id, isActive: true });
    if (live && live.streamId) {
      const framePath = path.join(__dirname, '../uploads/recordings', live.streamId, `${live.frameCount}.jpg`);
      fs.writeFileSync(framePath, req.body);
      live.frameCount += 1;
      await live.save();
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Upload frame error:', error);
    res.status(500).json({ success: false });
  }
});

// GET /lives/frame/:userId - Get the latest frame for a specific citizen
router.get('/frame/:userId', (req, res) => {
  const buffer = activeFrames.get(req.params.userId);
  if (!buffer) {
    return res.status(404).send('Aucun flux disponible.');
  }
  res.set('Content-Type', 'image/jpeg');
  res.send(buffer);
});

module.exports = router;
