require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Admin = require('./models/Admin');
const Alert = require('./models/Alert');
const Incident = require('./models/Incident');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/protection_civile';

// ─── Tunisian Governorates & Delegations Data ────────────────────────────────
const GOVERNORATES = {
  Tunis: ['Tunis', 'Le Bardo', 'La Goulette', 'La Marsa', 'Carthage', 'Sidi Bou Said', 'Hammam Lif', 'Ezzouhour'],
  Ariana: ['Ariana', 'La Soukra', 'Raoued', 'Kalaat el-Andalous', "Sidi Thabet", 'Ettadhamen', 'Mnihla'],
  'Ben Arous': ['Ben Arous', 'Hammam Lif', 'Bou Mhel el-Bassatine', 'Ezzahra', 'Mégrine', 'Rades', 'Fouchana', 'Mohamedia'],
  Manouba: ['Manouba', 'Den Den', 'Douar Hicher', 'Oued Ellil', 'Mornaguia', 'Borj El Amri', 'Jedaida', 'Tebourba'],
  Nabeul: ['Nabeul', 'Hammamet', 'Beni Khalled', 'Grombalia', 'Kelibia', 'Korba', 'Menzel Temime', 'Soliman'],
  Zaghouan: ['Zaghouan', 'Zriba', 'Bir Mcherga', 'El Fahs', 'Nadhour', 'Ssaouaf'],
  Bizerte: ['Bizerte', 'Menzel Bourguiba', 'Mateur', 'Sejnane', 'Joumine', 'Tinja', 'Ras Jebel', 'Ghezala'],
  Béja: ['Béja', 'Amdoun', 'Goubellat', 'Medjez el-Bab', 'Nefza', 'Teboursouk', 'Testour', 'Thibar'],
  Jendouba: ['Jendouba', 'Aïn Draham', 'Bou Salem', 'Fernana', 'Ghardimaou', 'Oued Melliz', 'Tabarka'],
  Siliana: ['Siliana', 'Bou Arada', 'Gaâfour', 'El Aroussa', 'Kesra', 'Makthar', 'Rouhia', 'Sidi Bou Rouis'],
  Sousse: ['Sousse', 'Akouda', 'Kalâa Kebira', 'Msaken', 'Sidi Bou Ali', 'Hammam Sousse', 'Enfidha', 'Hergla'],
  Monastir: ['Monastir', 'Jemmal', 'Ksar Hellal', 'Zeramdine', 'Beni Hassen', 'Bembla', 'Ouerdanine', 'Moknine'],
  Mahdia: ['Mahdia', 'Ksour Essef', 'El Jem', 'Chebba', 'Essouassi', 'Ouled Chamakh', 'Sidi Alouane'],
  Kairouan: ['Kairouan', 'Nasrallah', 'El Alaa', "Chebika", 'Haffouz', 'Menzel Mehiri', 'Oueslatia', 'Hajeb El Ayoun'],
  Sfax: ['Sfax', 'Kerkenah', 'El Ain', 'Bir Ali Ben Khélifa', 'Ghraiba', 'Jebeniana', 'Mahrès', 'Sakiet Eddaïer'],
  'Sidi Bouzid': ['Sidi Bouzid', 'Bir El Hafey', 'Cebbala Ouled Asker', 'Jilma', 'Meknassy', 'Menzel Bouzaiane', 'Mezzouna'],
  Kasserine: ['Kasserine', 'Sbeitla', 'Thala', 'Foussana', 'Haïdra', 'Jedeliane', 'Sbeïtla', 'Feriana'],
  Gafsa: ['Gafsa', 'Belkhir', 'El Guettar', 'Ksar', 'Mdhilla', 'Métlaoui', 'Redeyef', 'El Ksar'],
  Tozeur: ['Tozeur', 'Degache', 'Hazoua', 'Hezoua', 'Nefta', 'Tamerza'],
  Kebili: ['Kebili', 'Douz', 'Faouar', 'Souk Lahad', 'El Golaa'],
  Gabès: ['Gabès', 'El Hamma', 'Mareth', 'Matmata', 'Menzel El Habib', 'Nouvelle Matmata', 'Oudhref'],
  Médenine: ['Médenine', 'Ben Guerdane', 'Beni Khedache', 'Djerba', 'Zarzis', 'Sidi Makhlouf', 'Ajim'],
  Tataouine: ['Tataouine', 'Bir Lahmar', 'Dehiba', 'Ghomrassen', 'Remada', 'Smar'],
};

// ─── Sample Seed Data ─────────────────────────────────────────────────────────
const SAMPLE_ALERTS = [
  {
    title: 'ALERTE INONDATION - Grand Tunis',
    message: 'Des pluies torrentielles sont prévues pour les prochaines 24 heures dans la région du Grand Tunis. Évitez les sous-sols et les passages à niveau inondables. Gardez vos enfants à l\'abri.',
    governorate: 'Tunis',
    severity: 'high',
    category: 'flood',
    expiryDate: new Date(Date.now() + 48 * 60 * 60 * 1000), // 48 hours
  },
  {
    title: 'AVIS MÉTÉO - Vents Forts',
    message: 'Des vents forts de 60 à 80 km/h sont attendus sur les côtes de Bizerte. Les pêcheurs et les promeneurs sont priés de rester à distance des côtes.',
    governorate: 'Bizerte',
    severity: 'medium',
    category: 'weather',
    expiryDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
  },
  {
    title: 'RISQUE INCENDIE - Forêts Beja',
    message: 'Risque élevé d\'incendie de forêt dans la région de Béja en raison de la sécheresse prolongée. Évitez de faire des feux en plein air. Signalez tout début d\'incendie au 198.',
    governorate: 'Béja',
    severity: 'high',
    category: 'fire',
    expiryDate: new Date(Date.now() + 72 * 60 * 60 * 1000), // 72 hours
  },
  {
    title: 'ALERTE NATIONALE - Vague de Chaleur',
    message: 'Une vague de chaleur intense est attendue dans tout le pays avec des températures pouvant atteindre 46°C. Hydratez-vous régulièrement, évitez les sorties entre 12h et 16h, et prenez soin des personnes âgées et des enfants.',
    governorate: 'all',
    severity: 'critical',
    category: 'weather',
    expiryDate: new Date(Date.now() + 96 * 60 * 60 * 1000), // 96 hours
  },
  {
    title: 'ALERTE INONDATION - Zones Côtières Sfax',
    message: 'Les zones côtières de Sfax sont exposées à des risques d\'inondation suite aux pluies des derniers jours. Restez vigilants et évitez les oueds et les zones à risque.',
    governorate: 'Sfax',
    severity: 'medium',
    category: 'flood',
    expiryDate: new Date(Date.now() + 36 * 60 * 60 * 1000),
  },
  {
    title: 'TEMPÊTE DE SABLE - Région Sud',
    message: 'Une tempête de sable est prévue dans les gouvernorats du sud (Tozeur, Kebili, Tataouine). Fermez les fenêtres, évitez de conduire et protégez vos yeux et voies respiratoires.',
    governorate: 'Tozeur',
    severity: 'medium',
    category: 'weather',
    expiryDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
  },
];

// ─── Sample test users ─────────────────────────────────────────────────────────
const SAMPLE_USERS = [
  {
    fullName: 'Mohamed Ben Ali',
    cin: 'AA123456',
    phone: '+21699000001',
    email: 'test@example.com',
    passwordHash: 'password123', // Will be hashed by pre-save hook
    governorate: 'Tunis',
    delegation: 'Tunis',
    address: '12 Rue de la Liberté, Tunis',
    bloodType: 'O+',
    age: 34,
    medicalInfo: 'Asthmatique (utilise un inhalateur Ventoline)',
    emergencyContact: {
      name: 'Fatima Ben Ali',
      phone: '+21699000002',
    },
    consentGiven: true,
  },
  {
    fullName: 'Yassine Mansour',
    cin: 'AB123456',
    phone: '+21699000003',
    email: 'yassine@example.com',
    passwordHash: 'password123',
    governorate: 'Sousse',
    delegation: 'Sousse',
    address: 'Avenue 14 Janvier, Sousse',
    bloodType: 'A+',
    age: 28,
    medicalInfo: 'Allergie sévère à la pénicilline',
    emergencyContact: {
      name: 'Amel Mansour',
      phone: '+21699000004',
    },
    consentGiven: true,
  },
  {
    fullName: 'Fatma Trabelsi',
    cin: 'AC123456',
    phone: '+21699000005',
    email: 'fatma@example.com',
    passwordHash: 'password123',
    governorate: 'Ariana',
    delegation: 'La Soukra',
    address: 'Rue de la Mosquée, La Soukra',
    bloodType: 'B+',
    age: 45,
    medicalInfo: 'Diabétique de type 2 (prend de la metformine)',
    emergencyContact: {
      name: 'Rami Trabelsi',
      phone: '+21699000006',
    },
    consentGiven: true,
  },
  {
    fullName: 'Kamel Ben Salah',
    cin: 'AD123456',
    phone: '+21699000007',
    email: 'kamel@example.com',
    passwordHash: 'password123',
    governorate: 'Bizerte',
    delegation: 'Mateur',
    address: 'Avenue Habib Bourguiba, Mateur',
    bloodType: 'O-',
    age: 19,
    medicalInfo: 'Aucun antécédent médical connu',
    emergencyContact: {
      name: 'Salwa Ben Salah',
      phone: '+21699000008',
    },
    consentGiven: true,
  },
  {
    fullName: 'Mariem Gharbi',
    cin: 'AE123456',
    phone: '+21699000009',
    email: 'mariem@example.com',
    passwordHash: 'password123',
    governorate: 'Sfax',
    delegation: 'Sfax',
    address: 'Route de Teniour, Sfax',
    bloodType: 'AB+',
    age: 31,
    medicalInfo: 'Allergique aux arachides',
    emergencyContact: {
      name: 'Ali Gharbi',
      phone: '+21699000010',
    },
    consentGiven: true,
  },
  {
    fullName: 'Anis Bouazizi',
    cin: 'AF123456',
    phone: '+21699000011',
    email: 'anis@example.com',
    passwordHash: 'password123',
    governorate: 'Sidi Bouzid',
    delegation: 'Sidi Bouzid',
    address: 'Rue d\'Alger, Sidi Bouzid',
    bloodType: 'A-',
    age: 22,
    medicalInfo: 'Hypertension légère',
    emergencyContact: {
      name: 'Leila Bouazizi',
      phone: '+21699000012',
    },
    consentGiven: true,
  }
];

// ─── Main seed function ────────────────────────────────────────────────────────
async function seed() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected to MongoDB:', MONGO_URI);

    // Clear existing seed data
    await Alert.deleteMany({});
    await Incident.deleteMany({});
    await User.deleteMany({});
    await Admin.deleteMany({});
    console.log('🗑️  Cleared existing users, alerts, incidents, and admins');

    // Create Admin User
    const adminUser = new Admin({
      fullName: 'Ahmed Atallah',
      passwordHash: ' ahmed123456',
    });
    await adminUser.save();
    console.log('👑 Created Admin User: Ahmed Atallah');

    // Create sample alerts
    const alerts = await Alert.insertMany(SAMPLE_ALERTS);
    console.log(`✅ Created ${alerts.length} sample alerts`);

    // Create sample users
    let userId;
    for (let i = 0; i < SAMPLE_USERS.length; i++) {
      const uData = SAMPLE_USERS[i];
      const existingUser = await User.findOne({ cin: uData.cin });
      let currentUserId;
      if (!existingUser) {
        const user = new User(uData);
        await user.save();
        currentUserId = user._id;
        console.log(`✅ Created test user: ${uData.fullName} (CIN=${uData.cin})`);
      } else {
        currentUserId = existingUser._id;
        console.log(`ℹ️  Test user already exists: ${uData.fullName} (CIN=${uData.cin})`);
      }
      if (i === 0) {
        userId = currentUserId; // Set first user as the reporter for sample incidents
      }
    }

    // Create sample incidents
    const SAMPLE_INCIDENTS = [
      {
        type: 'fire',
        description: 'Incendie signalé dans un entrepôt à la Zone Industrielle de Charguia. Épaisses fumées noires visibles.',
        geolocation: {
          latitude: 36.8485,
          longitude: 10.2104,
          accuracy: 10,
          address: 'Zone Industrielle Charguia II, Tunis',
        },
        status: 'pending',
        reporter: userId,
        governorate: 'Tunis',
        createdAt: new Date(Date.now() - 1000 * 60 * 30), // 30 mins ago
      },
      {
        type: 'accident',
        description: 'Accident de la route impliquant deux voitures sur la GP1 près de Hammam Lif. Circulation bloquée.',
        geolocation: {
          latitude: 36.7291,
          longitude: 10.3418,
          accuracy: 15,
          address: 'GP1, Hammam Lif, Ben Arous',
        },
        status: 'dispatched',
        assignedUnit: 'Brigade Ben Arous - Ambulance 4',
        reporter: userId,
        governorate: 'Ben Arous',
        createdAt: new Date(Date.now() - 1000 * 60 * 120), // 2 hours ago
      },
      {
        type: 'flood',
        description: 'Inondation d\'une rue résidentielle à la Soukra suite aux fortes pluies. Niveau d\'eau atteignant les portes des maisons.',
        geolocation: {
          latitude: 36.8778,
          longitude: 10.2525,
          accuracy: 5,
          address: 'Avenue Hédi Nouira, La Soukra, Ariana',
        },
        status: 'pending',
        reporter: userId,
        governorate: 'Ariana',
        createdAt: new Date(Date.now() - 1000 * 60 * 15), // 15 mins ago
      },
      {
        type: 'rescue',
        description: 'Un randonneur blessé à la cheville sur le sentier de randonnée à Zaghouan. Incapable de redescendre.',
        geolocation: {
          latitude: 36.3989,
          longitude: 10.1433,
          accuracy: 25,
          address: 'Jebel Zaghouan, Zaghouan',
        },
        status: 'resolved',
        assignedUnit: 'Unité Secours Montagne Zaghouan',
        reporter: userId,
        governorate: 'Zaghouan',
        createdAt: new Date(Date.now() - 1000 * 60 * 300), // 5 hours ago
        resolvedAt: new Date(Date.now() - 1000 * 60 * 60), // resolved 1 hour ago
      },
      {
        type: 'other',
        description: 'Chute d\'un grand arbre bloquant la route principale près de l\'avenue Habib Bourguiba, Tunis.',
        geolocation: {
          latitude: 36.8002,
          longitude: 10.1864,
          accuracy: 8,
          address: 'Avenue Habib Bourguiba, Tunis',
        },
        status: 'closed',
        assignedUnit: 'Brigade Logistique Tunis',
        reporter: userId,
        governorate: 'Tunis',
        createdAt: new Date(Date.now() - 1000 * 60 * 600), // 10 hours ago
      }
    ];

    const seededIncidents = await Incident.insertMany(SAMPLE_INCIDENTS);
    console.log(`✅ Created ${seededIncidents.length} sample incidents`);


    // Log governorates summary
    console.log(`\n📍 Available governorates (${Object.keys(GOVERNORATES).length}):`);
    for (const [gov, delegations] of Object.entries(GOVERNORATES)) {
      console.log(`   - ${gov}: ${delegations.length} delegations`);
    }

    console.log('\n🌱 Seed completed successfully!');
    console.log('\n📋 Test credentials:');
    console.log(`   CIN/Email: ${SAMPLE_USERS[0].cin} or ${SAMPLE_USERS[0].email}`);
    console.log(`   Password:  password123`);
    console.log('\n📡 API Endpoints:');
    console.log('   POST /auth/register');
    console.log('   POST /auth/login');
    console.log('   GET  /alerts');
    console.log('   GET  /alerts/zone/:governorate');
    console.log('   POST /incidents (auth required)');
    console.log('   GET  /incidents  (auth required)');

  } catch (error) {
    console.error('❌ Seed failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 MongoDB disconnected');
  }
}

// Export governorates for use in other parts of the app
module.exports = { GOVERNORATES };

seed();
