const express = require('express');
const router = express.Router();
const SafetyTip = require('../models/SafetyTip');

// GET: Fetch all safety tips
router.get('/', async (req, res) => {
  try {
    const tips = await SafetyTip.find({}).sort({ createdAt: -1 });
    res.json({ success: true, count: tips.length, data: tips });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error fetching safety tips', error: err.message });
  }
});

// POST: Create a new safety tip
router.post('/', async (req, res) => {
  try {
    const {
      title, category, description, dos, donts, iconName,
      titleAr, categoryAr, descriptionAr, dosAr, dontsAr
    } = req.body;

    if (!title || !category || !description || !iconName || !titleAr || !categoryAr || !descriptionAr) {
      return res.status(400).json({ success: false, message: 'Required fields are missing' });
    }

    const newTip = new SafetyTip({
      title, category, description, dos: dos || [], donts: donts || [], iconName,
      titleAr, categoryAr, descriptionAr, dosAr: dosAr || [], dontsAr: dontsAr || []
    });

    await newTip.save();
    
    // Broadcast via socket.io if needed (optional)
    const io = req.app.get('io');
    if (io) {
      io.emit('safety_tips_updated');
    }

    res.status(201).json({ success: true, data: newTip });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error creating safety tip', error: err.message });
  }
});

// PUT: Update an existing safety tip
router.put('/:id', async (req, res) => {
  try {
    const {
      title, category, description, dos, donts, iconName,
      titleAr, categoryAr, descriptionAr, dosAr, dontsAr
    } = req.body;

    const tip = await SafetyTip.findById(req.params.id);
    if (!tip) {
      return res.status(404).json({ success: false, message: 'Safety tip not found' });
    }

    tip.title = title || tip.title;
    tip.category = category || tip.category;
    tip.description = description || tip.description;
    tip.dos = dos !== undefined ? dos : tip.dos;
    tip.donts = donts !== undefined ? donts : tip.donts;
    tip.iconName = iconName || tip.iconName;

    tip.titleAr = titleAr || tip.titleAr;
    tip.categoryAr = categoryAr || tip.categoryAr;
    tip.descriptionAr = descriptionAr || tip.descriptionAr;
    tip.dosAr = dosAr !== undefined ? dosAr : tip.dosAr;
    tip.dontsAr = dontsAr !== undefined ? dontsAr : tip.dontsAr;

    await tip.save();

    const io = req.app.get('io');
    if (io) {
      io.emit('safety_tips_updated');
    }

    res.json({ success: true, data: tip });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error updating safety tip', error: err.message });
  }
});

// DELETE: Delete a safety tip
router.delete('/:id', async (req, res) => {
  try {
    const tip = await SafetyTip.findById(req.params.id);
    if (!tip) {
      return res.status(404).json({ success: false, message: 'Safety tip not found' });
    }

    await tip.deleteOne();

    const io = req.app.get('io');
    if (io) {
      io.emit('safety_tips_updated');
    }

    res.json({ success: true, message: 'Safety tip deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server Error deleting safety tip', error: err.message });
  }
});

module.exports = router;
