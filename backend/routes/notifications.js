const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const User = require('../models/User');
const { authenticate, requireAdmin } = require('../middleware/auth');

// POST /notifications - Send notification (admin/authenticated dashboard operator)
router.post('/', authenticate, requireAdmin, async (req, res) => {
  try {
    const { title, body, targetType, governorate, userPhone } = req.body;

    if (!title || !body || !targetType) {
      return res.status(400).json({ success: false, message: 'Champs obligatoires manquants.' });
    }

    if (targetType === 'region' && !governorate) {
      return res.status(400).json({ success: false, message: 'Gouvernorat requis pour un envoi par région.' });
    }

    let targetUser = null;
    if (targetType === 'user') {
      if (!userPhone) {
        return res.status(400).json({ success: false, message: 'Numéro de téléphone requis pour un envoi ciblé.' });
      }
      
      // Verify user exists by phone (supporting with or without +216 prefix)
      const searchPhone = userPhone.trim();
      const phoneConditions = [{ phone: searchPhone }];
      if (/^\d{8}$/.test(searchPhone)) {
        phoneConditions.push({ phone: '+216' + searchPhone });
      }
      
      targetUser = await User.findOne({
        $or: phoneConditions,
        isActive: true
      });

      if (!targetUser) {
        return res.status(404).json({ 
          success: false, 
          message: 'Aucun citoyen actif trouvé avec ce numéro de téléphone.' 
        });
      }
      
      // Use the actual stored phone number
      var targetUserPhone = targetUser.phone;
    }

    const notification = new Notification({
      title: title.trim(),
      body: body.trim(),
      targetType,
      governorate: targetType === 'region' ? governorate.trim() : undefined,
      userPhone: targetType === 'user' ? targetUserPhone : undefined,
    });

    await notification.save();

    // Emit Socket.io real-time event
    const io = req.app.get('io');
    if (io) {
      if (targetType === 'all') {
        io.emit('new_notification', notification);
      } else if (targetType === 'region') {
        const room = `governorate_${governorate.trim().toLowerCase()}`;
        io.to(room).emit('new_notification', notification);
      } else if (targetType === 'user' && targetUser) {
        const room = `user_${targetUser._id.toString()}`;
        io.to(room).emit('new_notification', notification);
      } else if (targetType === 'volunteers' || targetType === 'non_volunteers') {
        io.to(targetType).emit('new_notification', notification);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Notification envoyée avec succès.',
      notification
    });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi de la notification.' });
  }
});

// GET /notifications - Get citizen targeted notifications
router.get('/', authenticate, async (req, res) => {
  try {
    const user = req.user;
    const targetConditions = [
      { targetType: 'all' },
      { targetType: 'region', governorate: user.governorate },
      { targetType: 'user', userPhone: user.phone },
      { targetType: user.isVolunteer ? 'volunteers' : 'non_volunteers' }
    ];
    const notifications = await Notification.find({
      $or: targetConditions
    }).sort({ createdAt: -1 }).limit(100);

    res.json({ success: true, notifications });
  } catch (error) {
    console.error('List notifications error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des notifications.' });
  }
});

// GET /notifications/all - Get all notifications (for admin review list)
router.get('/all', authenticate, requireAdmin, async (req, res) => {
  try {
    const notifications = await Notification.find({}).sort({ createdAt: -1 }).limit(100);
    res.json({ success: true, notifications });
  } catch (error) {
    console.error('List all notifications error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du chargement des notifications.' });
  }
});

// PUT /notifications/:id - Modify a notification (admin only)
router.put('/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const { title, body } = req.body;
    if (!title || !body) {
      return res.status(400).json({ success: false, message: 'Le titre et le contenu sont requis.' });
    }
    
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { title: title.trim(), body: body.trim() },
      { new: true }
    );
    
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification non trouvée.' });
    }
    
    res.json({ success: true, message: 'Notification modifiée avec succès.', notification });
  } catch (error) {
    console.error('Modify notification error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la modification de la notification.' });
  }
});

// DELETE /notifications/:id - Delete a notification (admin only)
router.delete('/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const notification = await Notification.findByIdAndDelete(req.params.id);
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification non trouvée.' });
    }
    res.json({ success: true, message: 'Notification supprimée avec succès.' });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression de la notification.' });
  }
});

module.exports = router;
