require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');

const authRoutes = require('./routes/auth');
const incidentRoutes = require('./routes/incidents');
const alertRoutes = require('./routes/alerts');
const notificationRoutes = require('./routes/notifications');
const liveRoutes = require('./routes/lives');
const safetyTipRoutes = require('./routes/safetyTips');
const User = require('./models/User');
const Live = require('./models/Live');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }
});

// Make io accessible globally via req.app.get('io')
app.set('io', io);

// Handle socket connections
io.on('connection', (socket) => {
  console.log('⚡ Client connected:', socket.id);

  socket.on('join_user', async (userId) => {
    if (userId) {
      const room = `user_${userId}`;
      socket.join(room);
      socket.userId = userId;
      console.log(`👤 Client ${socket.id} joined user room: ${room}`);
      try {
        const user = await User.findById(userId);
        if (user) {
          await User.findByIdAndUpdate(userId, { isOnline: true, lastActiveAt: new Date() });
          const volunteerRoom = user.isVolunteer ? 'volunteers' : 'non_volunteers';
          socket.join(volunteerRoom);
          console.log(`👤 Client ${socket.id} joined volunteer room: ${volunteerRoom}`);
        }
      } catch (err) {
        console.error('Socket join_user error:', err);
      }
    }
  });

  socket.on('join_governorate', (governorate) => {
    if (governorate) {
      const room = `governorate_${governorate.trim().toLowerCase()}`;
      socket.join(room);
      console.log(`📍 Client ${socket.id} joined governorate room: ${room}`);
    }
  });

  socket.on('update_location', async (data) => {
    if (data && data.userId) {
      try {
        const updateData = { isOnline: true, lastActiveAt: new Date() };
        if (data.latitude !== undefined && data.longitude !== undefined) {
          updateData.lastLatitude = data.latitude;
          updateData.lastLongitude = data.longitude;
        }
        await User.findByIdAndUpdate(data.userId, updateData);
      } catch (err) {
        console.error('Socket update_location error:', err);
      }
    }
  });

  socket.on('disconnect', async () => {
    console.log('⚡ Client disconnected:', socket.id);
    if (socket.userId) {
      try {
        await User.findByIdAndUpdate(socket.userId, { isOnline: false, lastActiveAt: new Date() });
        
        // Clean up active live session if they disconnected unexpectedly
        const activeLive = await Live.findOne({ user: socket.userId });
        if (activeLive) {
          await Live.deleteMany({ user: socket.userId });
          io.emit('live_stopped', { userId: socket.userId });
          const activeCount = await Live.countDocuments({ isActive: true });
          io.emit('live_count_update', { count: activeCount });
        }
      } catch (err) {
        console.error('Socket disconnect error:', err);
      }
    }
  });
});

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors({
  origin: '*', // In production: set specific origin
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Serve uploaded media files & Web Dashboard
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/dashboard', express.static(path.join(__dirname, '../dashboard_admin')));
app.use('/dashboard', express.static('C:/Users/AHMED/Desktop/web onpc'));
app.use('/web', express.static(path.join(__dirname, '../dashboard_admin')));
app.use('/web', express.static('C:/Users/AHMED/Desktop/web onpc'));

app.use('/api/auth', authRoutes);
app.use('/auth', authRoutes);
app.use('/api/incidents', incidentRoutes);
app.use('/incidents', incidentRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/alerts', alertRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/notifications', notificationRoutes);
app.use('/api/lives', liveRoutes);
app.use('/lives', liveRoutes);
app.use('/api/safety-tips', safetyTipRoutes);
app.use('/safety-tips', safetyTipRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Protection Civile Tunisie API',
    timestamp: new Date().toISOString(),
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  if (err.name === 'MulterError') {
    return res.status(400).json({ success: false, message: `File upload error: ${err.message}` });
  }
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    ...(process.env.NODE_ENV !== 'production' && { error: err.message }),
  });
});

// ─── Database & Server ────────────────────────────────────────────────────────
const SafetyTip = require('./models/SafetyTip');

async function seedSafetyTips() {
  try {
    const count = await SafetyTip.countDocuments();
    if (count === 0) {
      console.log('🌱 Seeding initial safety tips...');
      const initialTips = [
        {
          title: 'Incendie Domestique',
          category: 'Incendie',
          description: 'Que faire en cas de départ de feu à la maison.',
          iconName: 'local_fire_department',
          dos: [
            'Évacuez immédiatement les lieux en fermant la porte de la pièce en feu.',
            'Si de la fumée commence à envahir la pièce, baissez-vous près du sol où l\'air est plus sain.',
            'Appelez le 198 (Protection Civile) dès que vous êtes en sécurité.',
            'Touchez les portes avant de les ouvrir : si elles sont chaudes, ne les ouvrez pas.'
          ],
          donts: [
            'Ne prenez jamais l\'ascenseur, utilisez toujours les escaliers.',
            'Ne retournez jamais dans un bâtiment en feu pour récupérer des objets personnels.',
            'N\'ouvrez pas une porte chaude ou de laquelle s\'échappe de la fumée.',
            'Ne jetez pas d\'eau sur un feu d\'huile ou de graisse (cuisine).'
          ],
          titleAr: 'الحريق المنزلي',
          categoryAr: 'حرائق',
          descriptionAr: 'ماذا تفعل في حالة نشوب حريق في المنزل وكيفية حماية نفسك.',
          dosAr: [
            'غادر المكان فوراً مع إغلاق باب الغرفة المشتعلة لمنع انتشار النيران.',
            'إذا بدأ الدخان يملأ الغرفة، انخفض بالقرب من الأرض حيث يكون الهواء أنقى.',
            'اتصل بالرقم 198 (الحماية المدنية) بمجرد وصولك إلى مكان آمن.',
            'المس الأبواب قبل فتحها: إذا كانت ساخنة، فلا تفتحها أبداً.'
          ],
          dontsAr: [
            'لا تستخدم المصعد أبداً عند الإخلاء، استخدم السلالم دائماً.',
            'لا تعد أبداً إلى مبنى محترق لاستعادة أغراضك الشخصية.',
            'لا تفتح باباً ساخناً أو يتصاعد منه الدخان لتجنب هبوب النيران المفاجئ.',
            'لا تسكب الماء على حريق ناتج عن الزيوت أو الدهون (حرائق المطبخ).'
          ]
        },
        {
          title: 'Inondation',
          category: 'Inondation',
          description: 'Consignes de sécurité en cas de montée rapide des eaux ou de pluies diluviennes.',
          iconName: 'water_damage',
          dos: [
            'Réfugiez-vous en hauteur (à l\'étage ou sur le toit si nécessaire).',
            'Coupez le gaz et l\'électricité pour éviter les courts-circuits et les explosions.',
            'Suivez les consignes de sécurité diffusées à la radio ou par la Protection Civile.',
            'Préparez un kit d\'urgence (eau, nourriture, médicaments, lampe de poche).'
          ],
          donts: [
            'Ne descendez jamais dans les sous-sols ou les parkings souterrains.',
            'Ne traversez pas une route inondée à pied ou en voiture (30 cm d\'eau suffisent à emporter un véhicule).',
            'Ne touchez pas aux équipements électriques mouillés.',
            'Ne buvez pas l\'eau du robinet sans être sûr de sa potabilité.'
          ],
          titleAr: 'الفيضانات',
          categoryAr: 'فيضانات',
          descriptionAr: 'إرشادات السلامة في حالة الارتفاع السريع لمنسوب المياه أو الأمطار الغزيرة.',
          dosAr: [
            'الجأ إلى مكان مرتفع (الطابق العلوي أو السطح إذا لزم الأمر).',
            'اقطع الغاز والكهرباء لتجنب الماس الكهربائي وحوادث الصعق والانفجارات.',
            'اتبع تعليمات السلامة المذاعة عبر الراديو أو من قبل الحماية المدنية.',
            'جهّز حقيبة طوارئ تحتوي على ماء، طعام، أدوية، ومصباح يدوي.'
          ],
          dontsAr: [
            'لا تنزل أبداً إلى الطوابق السفلية أو مواقف السيارات تحت الأرض أثناء الفيضان.',
            'لا تعبر طريقاً مغموراً بالمياه مشياً أو بالسيارة (30 سم من الماء كافية لجرف سيارتك).',
            'لا تلمس الأجهزة أو التوصيلات الكهربائية المبللة أبداً.',
            'لا تشرب مياه الحنفية دون التأكد من تعقيمها وصلاحيتها للشرب.'
          ]
        },
        {
          title: 'Vague de Chaleur / Canicule',
          category: 'Météo',
          description: 'Comment se protéger et rester au frais pendant les fortes chaleurs d\'été.',
          iconName: 'thermostat',
          dos: [
            'Buvez de l\'eau régulièrement sans attendre d\'avoir soif (au moins 1,5L à 2L par jour).',
            'Mouillez votre corps et utilisez un ventilateur ou la climatisation.',
            'Fermez les volets et fenêtres pendant la journée, ouvrez-les la nuit.',
            'Portez des vêtements légers, amples et de couleur claire.'
          ],
          donts: [
            'Évitez de sortir aux heures les plus chaudes de la journée (11h - 16h).',
            'Ne faites pas d\'efforts physiques intenses (sport, travaux extérieurs).',
            'Ne buvez pas d\'alcool ou de boissons à forte teneur en caféine ou sucre.',
            'Ne laissez jamais personne (ni animal) seul dans une voiture garée.'
          ],
          titleAr: 'موجة الحر / الطقس الحار',
          categoryAr: 'طقس',
          descriptionAr: 'كيف تحمي نفسك وتبقي جسمك رطباً خلال درجات الحرارة المرتفعة في الصيف.',
          dosAr: [
            'اشرب الماء بانتظام دون انتظار الشعور بالعطش (على الأقل 1.5 إلى 2 لتر يومياً).',
            'بلل جسمك بالماء واستخدم المروحة أو مكيف الهواء لتبريد المكان.',
            'أغلق النوافذ والستائر خلال النهار وافتحها ليلاً لتهوية المنزل.',
            'ارتدِ ملابس خفيفة، فضفاضة، وفاتحة الألوان.'
          ],
          dontsAr: [
            'تجنب الخروج في الساعات الأكثر حرارة في اليوم (من 11 صباحاً حتى 4 مساءً).',
            'تجنب القيام بمجهود بدني شاق (مثل الرياضة أو العمل تحت أشعة الشمس).',
            'لا تشرب الكحول أو المشروبات الغنية بالكافيين أو السكريات لأنها تزيد الجفاف.',
            'لا تترك الأطفال أو الحيوانات الأليفة بمفردهم أبداً داخل سيارة متوقفة.'
          ]
        }
      ];
      await SafetyTip.insertMany(initialTips);
      console.log('🌱 Safety tips seeded successfully!');
    }
  } catch (err) {
    console.error('❌ Failed to seed safety tips:', err.message);
  }
}

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/protection_civile';

mongoose
  .connect(MONGO_URI)
  .then(async () => {
    console.log(`✅ MongoDB connected: ${MONGO_URI}`);
    await seedSafetyTips();
    server.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
      console.log(`📋 Health check: http://localhost:${PORT}/health`);
    });
  })
  .catch((err) => {
    console.error('❌ MongoDB connection failed:', err.message);
    process.exit(1);
  });

module.exports = app;
