const API_BASE_URL = 'http://localhost:3000';

// Tunisian Governorates matching backend
const GOVERNORATES = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte', 'Béja',
    'Jendouba', 'Siliana', 'Sousse', 'Monastir', 'Mahdia', 'Kairouan', 'Sfax', 'Sidi Bouzid',
    'Kasserine', 'Gafsa', 'Tozeur', 'Kebili', 'Gabès', 'Médenine', 'Tataouine'
];

// App State
const state = {
    token: localStorage.getItem('adminToken') || null,
    user: null,
    incidents: [],
    alerts: [],
    users: [],
    notifications: [],
    lives: [],
    activeTab: 'overview',
    charts: {},
    refreshInterval: null,
    statusInterval: null
};

// --- DOM ELEMENTS ---
const authOverlay = document.getElementById('auth-overlay');
const loginForm = document.getElementById('login-form');
const loginIdentifier = document.getElementById('login-identifier');
const loginPassword = document.getElementById('login-password');
const loginError = document.getElementById('login-error');
const loginSubmitBtn = document.getElementById('login-submit-btn');

const adminName = document.getElementById('admin-name');
const adminAvatar = document.getElementById('admin-avatar');
const logoutBtn = document.getElementById('logout-btn');

const serverStatusDot = document.getElementById('server-status-dot');
const serverStatusText = document.getElementById('server-status-text');
const viewTitle = document.getElementById('view-title');

const sidebarItems = document.querySelectorAll('.sidebar-item');
const viewContents = document.querySelectorAll('.view-content');

// Filter Elements
const filterGovernorate = document.getElementById('filter-governorate');
const filterStatus = document.getElementById('filter-status');
const incidentsTableBody = document.getElementById('incidents-table-body');
const usersTableBody = document.getElementById('users-table-body');

// Alert Form Elements
const broadcastForm = document.getElementById('broadcast-alert-form');
const alertGovernorate = document.getElementById('alert-governorate');
const alertExpiry = document.getElementById('alert-expiry');
const alertsFeedContainer = document.getElementById('alerts-feed-container');

// Modal Elements
const unitModal = document.getElementById('unit-modal');
const modalIncidentId = document.getElementById('modal-incident-id');
const modalAssignedUnit = document.getElementById('modal-assigned-unit');
const modalUnitSubmitBtn = document.getElementById('modal-unit-submit-btn');

const mediaModal = document.getElementById('media-modal');
const mediaModalContainer = document.getElementById('media-modal-container');

// Admin Notification Form Elements
const adminNotificationForm = document.getElementById('admin-notification-form');
const notifTitle = document.getElementById('notif-title');
const notifBody = document.getElementById('notif-body');
const notifTargetType = document.getElementById('notif-target-type');
const notifGovernorateGroup = document.getElementById('notif-governorate-group');
const notifGovernorate = document.getElementById('notif-governorate');
const notifPhoneGroup = document.getElementById('notif-phone-group');
const notifPhone = document.getElementById('notif-phone');
const notificationsHistoryContainer = document.getElementById('notifications-history-container');

// --- INITIALIZE APPLICATION ---
window.addEventListener('DOMContentLoaded', () => {
    // Load Saved Theme
    const savedTheme = localStorage.getItem('theme');
    const themeToggle = document.getElementById('theme-toggle-checkbox');
    if (savedTheme === 'light') {
        document.body.classList.add('light-theme');
        if (themeToggle) themeToggle.checked = true;
    } else {
        document.body.classList.remove('light-theme');
        if (themeToggle) themeToggle.checked = false;
    }

    populateDropdowns();
    setupEventListeners();
    setDefaultExpiryDate();
    
    if (state.token) {
        verifyTokenAndStart();
    } else {
        showLoginOverlay();
    }
    
    // Periodically monitor API status (even if not logged in)
    checkServerStatus();
    state.statusInterval = setInterval(checkServerStatus, 5000);
});

// Populate target zones and filters
function populateDropdowns() {
    // Incident view filters
    GOVERNORATES.sort().forEach(gov => {
        const opt1 = document.createElement('option');
        opt1.value = gov;
        opt1.textContent = gov;
        filterGovernorate.appendChild(opt1);
        
        const opt2 = document.createElement('option');
        opt2.value = gov;
        opt2.textContent = gov;
        alertGovernorate.appendChild(opt2);
        
        const opt3 = document.createElement('option');
        opt3.value = gov;
        opt3.textContent = gov;
        notifGovernorate.appendChild(opt3);
    });
}

function setDefaultExpiryDate() {
    // Default expiry: tomorrow at current time
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    // Format to YYYY-MM-DDThh:mm
    const year = tomorrow.getFullYear();
    const month = String(tomorrow.getMonth() + 1).padStart(2, '0');
    const day = String(tomorrow.getDate()).padStart(2, '0');
    const hours = String(tomorrow.getHours()).padStart(2, '0');
    const minutes = String(tomorrow.getMinutes()).padStart(2, '0');
    
    alertExpiry.value = `${year}-${month}-${day}T${hours}:${minutes}`;
}

// Setup Event Listeners
function setupEventListeners() {
    // Auth Form
    loginForm.addEventListener('submit', handleLoginSubmit);
    logoutBtn.addEventListener('click', handleLogout);
    
    // Sidebar Tabs navigation
    sidebarItems.forEach(item => {
        item.addEventListener('click', () => {
            const targetTab = item.getAttribute('data-tab');
            switchTab(targetTab);
        });
    });
    
    // Filter controls
    filterGovernorate.addEventListener('change', populateIncidentsTable);
    filterStatus.addEventListener('change', populateIncidentsTable);
    
    // Alert creation Form
    broadcastForm.addEventListener('submit', handleAlertBroadcast);
    
    // Modal Unit submission
    modalUnitSubmitBtn.addEventListener('click', handleUnitAssignment);
    
    // Citizen management modal listeners
    document.getElementById('modal-citizen-edit-btn').addEventListener('click', () => toggleCitizenEditMode(true));
    document.getElementById('modal-citizen-cancel-btn').addEventListener('click', () => toggleCitizenEditMode(false));
    document.getElementById('modal-citizen-save-btn').addEventListener('click', saveCitizenChanges);
    document.getElementById('modal-citizen-delete-btn').addEventListener('click', deleteCitizenAccount);
    
    // Admin Notification targeting change
    if (notifTargetType) {
        notifTargetType.addEventListener('change', () => {
            const type = notifTargetType.value;
            if (type === 'region') {
                notifGovernorateGroup.style.display = 'block';
                notifPhoneGroup.style.display = 'none';
            } else if (type === 'user') {
                notifGovernorateGroup.style.display = 'none';
                notifPhoneGroup.style.display = 'block';
            } else {
                notifGovernorateGroup.style.display = 'none';
                notifPhoneGroup.style.display = 'none';
            }
        });
    }
    
    // Admin Notification form submission
    if (adminNotificationForm) {
        adminNotificationForm.addEventListener('submit', handleNotificationSubmit);
    }
    
    // Theme toggle change listener
    const themeToggle = document.getElementById('theme-toggle-checkbox');
    if (themeToggle) {
        themeToggle.addEventListener('change', () => {
            if (themeToggle.checked) {
                document.body.classList.add('light-theme');
                localStorage.setItem('theme', 'light');
            } else {
                document.body.classList.remove('light-theme');
                localStorage.setItem('theme', 'dark');
            }
        });
    }

    // Notification management modal listeners
    document.getElementById('modal-notif-edit-btn').addEventListener('click', () => toggleNotificationEditMode(true));
    document.getElementById('modal-notif-cancel-btn').addEventListener('click', () => toggleNotificationEditMode(false));
    document.getElementById('modal-notif-save-btn').addEventListener('click', saveNotificationChanges);
    document.getElementById('modal-notif-delete-btn').addEventListener('click', deleteNotification);

    // User search filter
    const userSearchInput = document.getElementById('user-search-input');
    if (userSearchInput) {
        userSearchInput.addEventListener('input', populateUsersTable);
    }

    // Refresh live frame images at 3Hz / 300ms (simulate video stream)
    setInterval(() => {
        const imgs = document.querySelectorAll('[id^="live-frame-"]');
        imgs.forEach(img => {
            const userId = img.id.replace('live-frame-', '');
            img.src = `${API_BASE_URL}/lives/frame/${userId}?t=${Date.now()}`;
        });
    }, 300);
}

// Show/Hide Login
function showLoginOverlay() {
    authOverlay.classList.remove('hidden');
}

function hideLoginOverlay() {
    authOverlay.classList.add('hidden');
}

// Tab Switching
function switchTab(tabId) {
    state.activeTab = tabId;
    
    // Update Sidebar highlight
    sidebarItems.forEach(item => {
        if (item.getAttribute('data-tab') === tabId) {
            item.classList.add('active');
            item.classList.remove('flashing-red');
        } else {
            item.classList.remove('active');
        }
    });
    
    // Show correct View panel
    viewContents.forEach(view => {
        if (view.id === `${tabId}-view`) {
            view.classList.add('active');
        } else {
            view.classList.remove('active');
        }
    });
    
    // Update Header title
    const titles = {
        overview: 'Tableau de bord',
        map: 'Carte en Direct',
        incidents: 'Gestion des Incidents',
        alerts: 'Alerte et Radiodiffusion',
        users: 'Citoyens Enregistrés',
        notifications: 'Notifications Admin',
        lives: 'Vidéos en Direct',
        'safety-tips': 'Modifier Conseils'
    };
    viewTitle.textContent = titles[tabId];
    
    // Perform load tasks
    if (tabId === 'overview') {
        renderCharts();
    } else if (tabId === 'map') {
        initializeOrUpdateMap();
    } else if (tabId === 'incidents') {
        populateIncidentsTable();
    } else if (tabId === 'alerts') {
        populateAlertsFeed();
    } else if (tabId === 'users') {
        populateUsersTable();
    } else if (tabId === 'notifications') {
        loadNotificationsHistory();
    } else if (tabId === 'lives') {
        populateLivesGrid();
    } else if (tabId === 'safety-tips') {
        populateSafetyTipsTable();
    }
}

// Check Server Status
async function checkServerStatus() {
    try {
        const response = await fetch(`${API_BASE_URL}/health`);
        if (response.ok) {
            serverStatusDot.className = 'status-dot online';
            serverStatusText.textContent = 'En ligne';
        } else {
            throw new Error('API server unhealthy');
        }
    } catch (e) {
        serverStatusDot.className = 'status-dot offline';
        serverStatusText.textContent = 'Hors ligne';
    }
}

// --- API CLIENT WRAPPERS ---
async function fetchWithAuth(url, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers
    };
    
    if (state.token) {
        headers['Authorization'] = `Bearer ${state.token}`;
    }
    
    const response = await fetch(url, { ...options, headers });
    
    if (response.status === 401) {
        // Token expired or invalid -> log out
        handleLogout();
        throw new Error('Non autorisé. Veuillez vous reconnecter.');
    }
    
    return response.json();
}

// --- AUTHENTICATION FLOWS ---
async function handleLoginSubmit(e) {
    e.preventDefault();
    loginError.style.display = 'none';
    loginSubmitBtn.disabled = true;
    
    const identifier = loginIdentifier.value.trim();
    const password = loginPassword.value;
    
    try {
        const res = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identifier, password })
        });
        
        const data = await res.json();
        
        if (res.ok && data.success) {
            if (data.user.role !== 'admin') {
                throw new Error('Accès interdit. Cet espace est réservé aux administrateurs.');
            }
            
            state.token = data.token;
            state.user = data.user;
            localStorage.setItem('adminToken', data.token);
            
            // Set User Badge
            adminName.textContent = data.user.fullName;
            adminAvatar.textContent = data.user.fullName.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
            
            hideLoginOverlay();
            startPolling();
            switchTab('overview');
        } else {
            throw new Error(data.message || 'Login failed');
        }
    } catch (err) {
        console.error(err);
        loginError.style.display = 'block';
        loginError.textContent = err.message || 'Impossible de se connecter au serveur.';
    } finally {
        loginSubmitBtn.disabled = false;
    }
}

async function verifyTokenAndStart() {
    try {
        const data = await fetchWithAuth(`${API_BASE_URL}/auth/me`);
        if (data.success) {
            if (data.user.role !== 'admin') {
                throw new Error('Accès non autorisé');
            }
            state.user = data.user;
            adminName.textContent = data.user.fullName;
            adminAvatar.textContent = data.user.fullName.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
            hideLoginOverlay();
            initializeSocket(); // Setup real-time socket connections
            startPolling();
            switchTab('overview');
        } else {
            throw new Error('Token verification failed');
        }
    } catch (e) {
        console.error(e);
        handleLogout();
    }
}

function handleLogout() {
    state.token = null;
    state.user = null;
    localStorage.removeItem('adminToken');
    
    if (socket) {
        socket.disconnect();
        socket = null;
    }
    
    // Stop intervals
    if (state.refreshInterval) {
        clearInterval(state.refreshInterval);
        state.refreshInterval = null;
    }
    
    // Destroy charts
    Object.keys(state.charts).forEach(cId => {
        if (state.charts[cId]) {
            state.charts[cId].destroy();
        }
    });
    state.charts = {};
    
    loginIdentifier.value = '';
    loginPassword.value = '';
    showLoginOverlay();
}

// --- DATA POLLING ---
function startPolling() {
    // Refresh stats every 10 seconds
    refreshAllData();
    state.refreshInterval = setInterval(refreshAllData, 10000);
}

async function refreshAllData() {
    if (!state.token) return;
    
    try {
        // Fetch incidents
        const incRes = await fetchWithAuth(`${API_BASE_URL}/incidents?limit=100`);
        if (incRes.success) {
            state.incidents = incRes.incidents;
        }
        
        // Fetch alerts
        const alertRes = await fetchWithAuth(`${API_BASE_URL}/alerts`);
        if (alertRes.success) {
            state.alerts = alertRes.alerts;
        }
        
        // Fetch users
        const usersRes = await fetchWithAuth(`${API_BASE_URL}/auth/users`);
        if (usersRes.success) {
            state.users = usersRes.users;
        }

        // Fetch active lives
        const livesRes = await fetchWithAuth(`${API_BASE_URL}/lives`);
        if (livesRes.success) {
            state.lives = livesRes.lives;
            updateLiveBadge(state.lives.length);
        }
        
        // Update metric cards
        updateMetricCards();
        
        // Refresh active views
        if (state.activeTab === 'overview') {
            renderCharts();
        } else if (state.activeTab === 'incidents') {
            populateIncidentsTable();
        } else if (state.activeTab === 'alerts') {
            populateAlertsFeed();
        } else if (state.activeTab === 'users') {
            populateUsersTable();
        } else if (state.activeTab === 'notifications') {
            loadNotificationsHistory();
        } else if (state.activeTab === 'lives') {
            populateLivesGrid();
        }
    } catch (err) {
        console.error('Error refreshing data:', err);
    }
}

function updateMetricCards() {
    document.getElementById('metric-total-incidents').textContent = state.incidents.length;
    
    const pending = state.incidents.filter(i => i.status === 'pending').length;
    document.getElementById('metric-pending-incidents').textContent = pending;
    
    const resolved = state.incidents.filter(i => i.status === 'resolved' || i.status === 'closed').length;
    document.getElementById('metric-resolved-incidents').textContent = resolved;
    
    document.getElementById('metric-active-alerts').textContent = state.alerts.length;
}

// --- VIEW 1: OVERVIEW & CHARTS ---
function renderCharts() {
    if (state.incidents.length === 0) return;
    
    // Aggregate incident type counts
    const typeCounts = { fire: 0, accident: 0, flood: 0, collapse: 0, rescue: 0, other: 0 };
    state.incidents.forEach(inc => {
        if (typeCounts[inc.type] !== undefined) {
            typeCounts[inc.type]++;
        } else {
            typeCounts.other++;
        }
    });
    
    // Aggregate status counts
    const statusCounts = { pending: 0, dispatched: 0, resolved: 0, closed: 0 };
    state.incidents.forEach(inc => {
        if (statusCounts[inc.status] !== undefined) {
            statusCounts[inc.status]++;
        }
    });
    
    // 1. Render/Update Type Chart
    const typeCtx = document.getElementById('typeChart').getContext('2d');
    if (state.charts.typeChart) {
        state.charts.typeChart.data.datasets[0].data = Object.values(typeCounts);
        state.charts.typeChart.update();
    } else {
        state.charts.typeChart = new Chart(typeCtx, {
            type: 'bar',
            data: {
                labels: ['Incendie', 'Accident', 'Inondation', 'Effondrement', 'Secours', 'Autre'],
                datasets: [{
                    label: 'Nombre de cas',
                    data: Object.values(typeCounts),
                    backgroundColor: [
                        'rgba(231, 29, 54, 0.75)', // fire (accent)
                        'rgba(245, 158, 11, 0.75)', // accident (orange)
                        'rgba(59, 130, 246, 0.75)', // flood (blue)
                        'rgba(139, 92, 246, 0.75)', // collapse (purple)
                        'rgba(16, 185, 129, 0.75)', // rescue (green)
                        'rgba(107, 114, 128, 0.75)'  // other (grey)
                    ],
                    borderColor: [
                        '#e71d36', '#f59e0b', '#3b82f6', '#8b5cf6', '#10b981', '#6b7280'
                    ],
                    borderWidth: 1.5,
                    borderRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: { color: '#9ca3af', stepSize: 1 },
                        grid: { color: 'rgba(255, 255, 255, 0.05)' }
                    },
                    x: {
                        ticks: { color: '#9ca3af' },
                        grid: { display: false }
                    }
                }
            }
        });
    }
    
    // 2. Render/Update Status Chart
    const statusCtx = document.getElementById('statusChart').getContext('2d');
    if (state.charts.statusChart) {
        state.charts.statusChart.data.datasets[0].data = Object.values(statusCounts);
        state.charts.statusChart.update();
    } else {
        state.charts.statusChart = new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: ['En attente', 'Équipe envoyée', 'Résolu', 'Clôturé'],
                datasets: [{
                    data: Object.values(statusCounts),
                    backgroundColor: [
                        'rgba(245, 158, 11, 0.8)', // pending
                        'rgba(59, 130, 246, 0.8)',  // dispatched
                        'rgba(16, 185, 129, 0.8)',  // resolved
                        'rgba(107, 114, 128, 0.8)'  // closed
                    ],
                    borderColor: 'rgba(23, 31, 56, 0.85)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: { color: '#f3f4f6', boxWidth: 12, padding: 15 }
                    }
                },
                cutout: '65%'
            }
        });
    }
}

// --- VIEW 2: INCIDENTS CONTROLLER ---
function translateType(type) {
    const map = {
        fire: { fr: 'Incendie', icon: 'fa-fire', color: '#e71d36' },
        accident: { fr: 'Accident', icon: 'fa-car-burst', color: '#f59e0b' },
        flood: { fr: 'Inondation', icon: 'fa-house-flood-water', color: '#3b82f6' },
        collapse: { fr: 'Effondrement', icon: 'fa-building-crack', color: '#8b5cf6' },
        rescue: { fr: 'Secours', icon: 'fa-kit-medical', color: '#10b981' },
        other: { fr: 'Autre', icon: 'fa-circle-question', color: '#6b7280' }
    };
    return map[type] || { fr: type, icon: 'fa-circle-question', color: '#6b7280' };
}

function translateStatus(status) {
    const map = {
        pending: { fr: 'En attente', class: 'pending' },
        dispatched: { fr: 'Équipe envoyée', class: 'dispatched' },
        resolved: { fr: 'Résolu', class: 'resolved' },
        closed: { fr: 'Clôturé', class: 'closed' }
    };
    return map[status] || { fr: status, class: 'closed' };
}

function maskCin(cin) {
    if (!cin) return '';
    const str = cin.toString().trim();
    if (str.length <= 3) return str;
    return '*'.repeat(str.length - 3) + str.slice(-3);
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function populateIncidentsTable() {
    const govVal = filterGovernorate.value;
    const statusVal = filterStatus.value;
    
    // Filter local data
    const filtered = state.incidents.filter(inc => {
        const matchGov = !govVal || inc.governorate === govVal;
        const matchStatus = !statusVal || inc.status === statusVal;
        return matchGov && matchStatus;
    });
    
    incidentsTableBody.innerHTML = '';
    
    if (filtered.length === 0) {
        incidentsTableBody.innerHTML = `
            <tr>
                <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 30px 0;">
                    Aucun incident ne correspond aux critères de filtrage.
                </td>
            </tr>
        `;
        return;
    }
    
    filtered.forEach(inc => {
        const typeInfo = translateType(inc.type);
        const statusInfo = translateStatus(inc.status);
        let reporterHtml = '';
        if (inc.reporter) {
            const rep = inc.reporter;
            const ageText = rep.age ? `${rep.age} ans` : 'Âge inconnu';
            const bloodColor = rep.bloodType && rep.bloodType.includes('-') ? '#f59e0b' : '#ef4444';
            const bloodBadge = rep.bloodType ? `<span style="background: rgba(239, 68, 68, 0.08); color: ${bloodColor}; padding: 2px 6px; border-radius: 4px; font-weight: 700; font-size: 10px; border: 1px solid rgba(239,68,68,0.15);">${rep.bloodType}</span>` : '';
            
            let medWarningHtml = '';
            if (rep.medicalInfo && rep.medicalInfo.trim() !== '' && rep.medicalInfo.toLowerCase() !== 'aucun' && rep.medicalInfo.toLowerCase() !== 'aucune') {
                medWarningHtml = `
                    <div style="font-size: 11px; color: #f87171; font-weight: 700; margin-top: 4px; max-width: 180px; text-overflow: ellipsis; overflow: hidden; white-space: nowrap;" title="${rep.medicalInfo}">
                        <i class="fa-solid fa-circle-exclamation"></i> ${rep.medicalInfo}
                    </div>
                `;
            }
            
            reporterHtml = `
                <div style="font-weight: 700;">${rep.fullName}</div>
                <div style="font-size: 11px; color: var(--text-muted); display: flex; align-items: center; gap: 6px; margin-top: 2px;">
                    <span>${ageText}</span>
                    <span>•</span>
                    ${bloodBadge}
                </div>
                <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">
                    <i class="fa-solid fa-phone" style="font-size: 9px; margin-right: 4px;"></i> ${rep.phone}
                </div>
                ${medWarningHtml}
            `;
        } else {
            reporterHtml = `<span style="color: var(--text-muted);">Anonyme</span>`;
        }
        
        // Location mapping
        const lat = inc.geolocation.latitude;
        const lng = inc.geolocation.longitude;
        const address = inc.geolocation.address || 'Aucune adresse renseignée';
        const mapUrl = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
        
        // Description and voice note details
        let detailsHtml = '';
        if (inc.description && inc.description.trim() !== '') {
            detailsHtml += `<div style="font-size: 13px; font-weight: 500; margin-bottom: 6px; line-height: 1.4; color: var(--text-main); max-width: 250px; word-break: break-all;">${inc.description}</div>`;
        }
        if (inc.voiceUrl) {
            const absoluteVoiceUrl = `${API_BASE_URL}${inc.voiceUrl}`;
            detailsHtml += `
                <div style="margin-top: 4px; display: flex; align-items: center; gap: 8px;">
                    <audio src="${absoluteVoiceUrl}" controls style="max-width: 200px; height: 32px; outline: none; border-radius: 8px;"></audio>
                </div>
            `;
        }
        if (detailsHtml === '') {
            detailsHtml = `<span style="color: var(--text-muted); font-size: 12px; font-style: italic;">Aucun détail</span>`;
        }

        // Media preview
        let mediaHtml = '<span style="color: var(--text-muted);">Aucun</span>';
        if (inc.mediaUrl) {
            const absoluteMediaUrl = `${API_BASE_URL}${inc.mediaUrl}`;
            if (inc.mediaType === 'video') {
                mediaHtml = `
                    <div class="media-preview-container">
                        <div class="media-video-icon" onclick="openMediaViewer('${absoluteMediaUrl}', 'video')">
                            <i class="fa-solid fa-play"></i>
                        </div>
                    </div>
                `;
            } else {
                mediaHtml = `
                    <div class="media-preview-container">
                        <img src="${absoluteMediaUrl}" class="media-thumbnail" onclick="openMediaViewer('${absoluteMediaUrl}', 'image')" alt="Aperçu">
                    </div>
                `;
            }
        }
        
        const statusSelectHtml = `
            <select class="status-select badge ${statusInfo.class}" 
                onchange="changeIncidentStatus('${inc._id}', this.value, '${inc.status}', this)" 
                style="border: none; border-radius: 12px; padding: 4px 10px; font-weight: 700; font-size: 11px; cursor: pointer; outline: none; font-family: inherit; text-transform: uppercase;">
                <option value="pending" ${inc.status === 'pending' ? 'selected' : ''}>En attente</option>
                <option value="dispatched" ${inc.status === 'dispatched' ? 'selected' : ''}>Équipe envoyée</option>
                <option value="resolved" ${inc.status === 'resolved' ? 'selected' : ''}>Résolu</option>
                <option value="closed" ${inc.status === 'closed' ? 'selected' : ''}>Clôturé</option>
            </select>
        `;

        const tr = document.createElement('tr');
        tr.classList.add('clickable-row');
        tr.innerHTML = `
            <td><strong>${formatDate(inc.createdAt)}</strong></td>
            <td>
                <span class="badge" style="background: rgba(255,255,255,0.05); color: ${typeInfo.color}; padding: 6px 12px; border-radius: 8px;">
                    <i class="fa-solid ${typeInfo.icon}" style="margin-right: 6px;"></i> ${typeInfo.fr}
                </span>
            </td>
            <td>${reporterHtml}</td>
            <td>
                <div style="max-width: 200px; font-size: 13px; text-overflow: ellipsis; overflow: hidden; white-space: nowrap;">${address}</div>
                <div>
                    <a href="${mapUrl}" target="_blank" class="map-link">
                        <i class="fa-solid fa-map-location-dot"></i> Maps (${lat.toFixed(4)}, ${lng.toFixed(4)})
                    </a>
                </div>
            </td>
            <td>${detailsHtml}</td>
            <td>${mediaHtml}</td>
            <td>${statusSelectHtml}</td>
        `;

        tr.onclick = (e) => {
            const skipTags = ['SELECT', 'OPTION', 'A', 'I', 'AUDIO', 'IMG'];
            if (skipTags.includes(e.target.tagName) || e.target.closest('.media-preview-container') || e.target.closest('.status-select')) {
                return;
            }
            showIncidentDetails(inc._id);
        };
        
        incidentsTableBody.appendChild(tr);
    });

}

// Modal control utilities
function openModal(id) {
    document.getElementById(id).classList.add('show');
}

function closeModal(id) {
    document.getElementById(id).classList.remove('show');
}

// Assign Unit modal trigger
function openUnitModal(id) {
    modalIncidentId.value = id;
    modalAssignedUnit.value = '';
    openModal('unit-modal');
    modalAssignedUnit.focus();
}

async function handleUnitAssignment() {
    const id = modalIncidentId.value;
    const unitName = modalAssignedUnit.value.trim();
    
    if (!unitName) {
        alert("Le nom de l'équipe de secours est obligatoire.");
        return;
    }
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/incidents/${id}`, {
            method: 'PATCH',
            body: JSON.stringify({
                status: 'dispatched',
                assignedUnit: unitName
            })
        });
        
        if (res.success) {
            closeModal('unit-modal');
            refreshAllData();
        } else {
            throw new Error(res.message || 'Failed to assign unit');
        }
    } catch (e) {
        console.error(e);
        alert(`Erreur d'assignation: ${e.message}`);
    }
}

// Update incident status directly
async function changeIncidentStatus(id, newStatus, originalStatus = null, selectElement = null) {
    const confirmMsg = newStatus === 'closed' 
        ? "Êtes-vous sûr de vouloir clôturer définitivement cet incident ?" 
        : `Voulez-vous changer le statut à : ${translateStatus(newStatus).fr} ?`;
        
    if (!confirm(confirmMsg)) {
        if (selectElement && originalStatus) {
            selectElement.value = originalStatus;
        }
        return;
    }
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/incidents/${id}`, {
            method: 'PATCH',
            body: JSON.stringify({ status: newStatus })
        });
        
        if (res.success) {
            refreshAllData();
        } else {
            throw new Error(res.message || 'Failed to update status');
        }
    } catch (e) {
        console.error(e);
        if (selectElement && originalStatus) {
            selectElement.value = originalStatus;
        }
        alert(`Erreur de statut: ${e.message}`);
    }
}

// Media Lightbox modal
function openMediaViewer(url, type) {
    mediaModalContainer.innerHTML = '';
    
    if (type === 'video') {
        const video = document.createElement('video');
        video.src = url;
        video.controls = true;
        video.autoplay = true;
        video.className = 'media-viewer-content';
        mediaModalContainer.appendChild(video);
    } else {
        const img = document.createElement('img');
        img.src = url;
        img.className = 'media-viewer-content';
        mediaModalContainer.appendChild(img);
    }
    
    openModal('media-modal');
}

// --- VIEW 3: ALERTS CONTROLLER ---
function translateSeverity(severity) {
    const map = {
        low: { fr: 'Faible', class: 'low' },
        medium: { fr: 'Moyenne', class: 'medium' },
        high: { fr: 'Élevée', class: 'high' },
        critical: { fr: 'Critique / Vitale', class: 'critical' }
    };
    return map[severity] || { fr: severity, class: 'low' };
}

function translateCategory(category) {
    const map = {
        weather: 'Météo',
        fire: 'Incendie',
        flood: 'Inondation',
        accident: 'Accident',
        health: 'Santé publique',
        security: 'Sécurité',
        general: 'Général'
    };
    return map[category] || category;
}

function populateAlertsFeed() {
    alertsFeedContainer.innerHTML = '';
    
    if (state.alerts.length === 0) {
        alertsFeedContainer.innerHTML = `
            <div style="text-align: center; color: var(--text-muted); padding: 40px 0;">
                Aucune alerte active diffusée actuellement.
            </div>
        `;
        return;
    }
    
    state.alerts.forEach(alert => {
        const sevInfo = translateSeverity(alert.severity);
        const cardStyle = alert.severity === 'critical' ? 'border: 1px dashed #ef4444; background: rgba(239,68,68,0.03);' : '';
        const zoneText = alert.governorate === 'all' ? 'Toute la Tunisie' : `Gouv. : ${alert.governorate}`;
        
        const card = document.createElement('div');
        card.className = 'metric-card';
        card.style = `gap: 16px; padding: 20px; align-items: flex-start; display: flex; flex-direction: column; width: 100%; min-height: auto; flex-shrink: 0; ${cardStyle}`;
        
        card.innerHTML = `
            <div style="display: flex; align-items: center; justify-content: space-between; width: 100%; border-bottom: 1px solid rgba(255,255,255,0.05); padding-bottom: 10px;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span class="badge ${sevInfo.class}">${sevInfo.fr}</span>
                    <span style="font-size: 11px; font-weight: 700; background: rgba(255,255,255,0.05); padding: 4px 8px; border-radius: 6px; color: var(--text-muted);">
                        ${translateCategory(alert.category)}
                    </span>
                </div>
                <span style="font-size: 11px; font-weight: 800; color: #60a5fa;"><i class="fa-solid fa-location-dot"></i> ${zoneText}</span>
            </div>
            
            <div style="width: 100%;">
                <h4 style="font-size: 15px; font-weight: 800; margin-bottom: 6px; color: white;">${alert.title}</h4>
                <p style="font-size: 13px; color: var(--text-muted); line-height: 1.5; font-weight: 400; word-break: break-word;">${alert.message}</p>
            </div>
            
            <div style="display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 600; color: var(--text-muted); margin-top: 4px;">
                <i class="fa-solid fa-clock"></i> Expire le : ${formatDate(alert.expiryDate)}
            </div>
        `;
        
        alertsFeedContainer.appendChild(card);
    });
}

// Broadcast Alert Form submit
async function handleAlertBroadcast(e) {
    e.preventDefault();
    
    const submitBtn = document.getElementById('btn-broadcast-submit');
    submitBtn.disabled = true;
    
    const title = document.getElementById('alert-title').value.trim();
    const message = document.getElementById('alert-message').value.trim();
    const severity = document.getElementById('alert-severity').value;
    const category = document.getElementById('alert-category').value;
    const governorate = document.getElementById('alert-governorate').value;
    const expiryDate = document.getElementById('alert-expiry').value;
    
    if (!title || !message || !expiryDate) {
        alert('Veuillez remplir tous les champs requis.');
        submitBtn.disabled = false;
        return;
    }
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/alerts`, {
            method: 'POST',
            body: JSON.stringify({
                title,
                message,
                severity,
                category,
                governorate,
                expiryDate: new Date(expiryDate).toISOString()
            })
        });
        
        if (res.success) {
            // Reset form
            document.getElementById('alert-title').value = '';
            document.getElementById('alert-message').value = '';
            document.getElementById('alert-severity').value = 'high';
            document.getElementById('alert-category').value = 'weather';
            document.getElementById('alert-governorate').value = 'all';
            setDefaultExpiryDate();
            
            // Refresh
            refreshAllData();
            alert('Alerte d\'urgence diffusée avec succès!');
        } else {
            throw new Error(res.message || 'Failed to broadcast alert');
        }
    } catch (err) {
        console.error(err);
        alert(`Erreur de diffusion: ${err.message}`);
    } finally {
        submitBtn.disabled = false;
    }
}

// --- VIEW 4: USERS CONTROLLER ---
function populateUsersTable() {
    usersTableBody.innerHTML = '';
    
    const searchInput = document.getElementById('user-search-input');
    const query = searchInput ? searchInput.value.trim().toLowerCase() : '';
    
    const filteredUsers = state.users.filter(user => {
        if (!query) return true;
        const nameMatch = user.fullName && user.fullName.toLowerCase().includes(query);
        const phoneMatch = user.phone && user.phone.toLowerCase().includes(query);
        const cinMatch = user.cin && user.cin.toLowerCase().includes(query);
        return nameMatch || phoneMatch || cinMatch;
    });
    
    if (filteredUsers.length === 0) {
        usersTableBody.innerHTML = `
            <tr>
                <td colspan="10" style="text-align: center; color: var(--text-muted); padding: 30px 0;">
                    ${query ? 'Aucun citoyen ne correspond à votre recherche.' : 'Aucun citoyen enregistré dans la base de données.'}
                </td>
            </tr>
        `;
        return;
    }
    
    filteredUsers.forEach(user => {
        const emergencyName = user.emergencyContact ? user.emergencyContact.name : 'N/A';
        const emergencyPhone = user.emergencyContact ? user.emergencyContact.phone : 'N/A';
        
        // Dynamic blood badge style
        let bloodColor = '#6b7280';
        if (user.bloodType.includes('+')) {
            bloodColor = '#ef4444';
        } else if (user.bloodType.includes('-')) {
            bloodColor = '#f59e0b';
        }
        const bloodBadge = `
            <span class="badge" style="background: rgba(239, 68, 68, 0.08); color: ${bloodColor}; border: 1px solid rgba(239, 68, 68, 0.15); padding: 4px 8px; border-radius: 6px;">
                <i class="fa-solid fa-droplet"></i> ${user.bloodType}
            </span>
        `;
        
        const medInfoText = user.medicalInfo && user.medicalInfo.trim() !== '' ? user.medicalInfo.trim() : 'Aucune';
        const medBadge = user.medicalInfo && user.medicalInfo.trim() !== '' && user.medicalInfo.toLowerCase() !== 'aucun' && user.medicalInfo.toLowerCase() !== 'aucune'
            ? `<span style="color: #f87171; font-weight: 600; font-size: 13px;"><i class="fa-solid fa-triangle-exclamation" style="margin-right: 4px;"></i> ${medInfoText}</span>`
            : `<span style="color: var(--text-muted); font-size: 13px;">Aucune</span>`;

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${user.fullName}</strong></td>
            <td>
                <span class="badge" style="background: var(--input-bg); color: var(--text-main); border: 1px solid var(--card-border); padding: 4px 8px;">
                    ${maskCin(user.cin)}
                </span>
            </td>
            <td><strong>${user.age || 'N/A'}</strong> ans</td>
            <td>${user.phone}</td>
            <td>
                <div>${user.governorate}</div>
                <div style="font-size: 11px; color: var(--text-muted);">${user.delegation}</div>
            </td>
            <td>${bloodBadge}</td>
            <td>${medBadge}</td>
            <td>
                <div style="font-weight: 600;">${emergencyName}</div>
                <div style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone" style="font-size: 9px; margin-right: 4px;"></i> ${emergencyPhone}</div>
            </td>
            <td>
                ${user.isVolunteer
                    ? '<span class="badge" style="background: rgba(34, 197, 94, 0.08); color: #22c55e; border: 1px solid rgba(34, 197, 94, 0.15); padding: 4px 8px; border-radius: 6px; font-weight: 600;">Oui</span>'
                    : '<span class="badge" style="background: rgba(107, 114, 128, 0.08); color: #6b7280; border: 1px solid rgba(107, 114, 128, 0.15); padding: 4px 8px; border-radius: 6px;">Non</span>'
                }
            </td>
            <td>
                <button class="btn-action" onclick="openCitizenModal('${user._id}')" style="padding: 6px 12px; background: rgba(59, 130, 246, 0.08); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.15); border-radius: 8px;">
                    <i class="fa-solid fa-user-gear"></i> Gérer
                </button>
            </td>
        `;
        
        usersTableBody.appendChild(tr);
    });
}

// --- CITIZEN MANAGEMENT MODAL ---
let selectedCitizen = null;

function openCitizenModal(userId) {
    const user = state.users.find(u => u._id === userId);
    if (!user) return;
    
    selectedCitizen = user;
    
    // Set fields in View Mode
    document.getElementById('modal-citizen-id').value = user._id;
    document.getElementById('view-citizen-name').textContent = user.fullName;
    document.getElementById('view-citizen-cin').textContent = maskCin(user.cin);
    document.getElementById('view-citizen-age').textContent = `${user.age || 'N/A'} ans`;
    document.getElementById('view-citizen-phone').textContent = user.phone;
    document.getElementById('view-citizen-email').innerHTML = user.email ? user.email : '<span style="color: var(--text-muted);">Non spécifié</span>';
    document.getElementById('view-citizen-region').textContent = `${user.governorate} / ${user.delegation}`;
    document.getElementById('view-citizen-blood').textContent = user.bloodType;
    document.getElementById('view-citizen-medical').innerHTML = user.medicalInfo && user.medicalInfo.trim() !== ''
        ? `<span style="color: #f87171; font-weight: 600;"><i class="fa-solid fa-triangle-exclamation"></i> ${user.medicalInfo}</span>`
        : '<span style="color: var(--text-muted);">Aucune</span>';
    
    const emergencyName = user.emergencyContact ? user.emergencyContact.name : 'N/A';
    const emergencyPhone = user.emergencyContact ? user.emergencyContact.phone : 'N/A';
    document.getElementById('view-citizen-emergency').textContent = `${emergencyName} (${emergencyPhone})`;
    
    // Set volunteer view field
    const volunteerSpan = document.getElementById('view-citizen-volunteer');
    if (volunteerSpan) {
        volunteerSpan.innerHTML = user.isVolunteer 
            ? '<span style="color: #22c55e; font-weight: 700;"><i class="fa-solid fa-circle-check"></i> Oui (متطوع)</span>' 
            : '<span style="color: var(--text-muted); font-weight: 700;"><i class="fa-solid fa-circle-xmark"></i> Non (غير متطوع)</span>';
    }
    
    document.getElementById('view-citizen-date').textContent = formatDate(user.createdAt);

    // Set fields in Edit Mode Form
    document.getElementById('edit-citizen-name').value = user.fullName;
    document.getElementById('edit-citizen-age').value = user.age || '';
    document.getElementById('edit-citizen-blood').value = user.bloodType;
    document.getElementById('edit-citizen-phone').value = user.phone;
    document.getElementById('edit-citizen-email').value = user.email || '';
    document.getElementById('edit-citizen-address').value = user.address || '';
    document.getElementById('edit-citizen-medical').value = user.medicalInfo || '';
    document.getElementById('edit-citizen-emergency-name').value = user.emergencyContact ? user.emergencyContact.name : '';
    document.getElementById('edit-citizen-emergency-phone').value = user.emergencyContact ? user.emergencyContact.phone : '';
    
    // Set volunteer edit field
    const volunteerCheckbox = document.getElementById('edit-citizen-volunteer');
    if (volunteerCheckbox) {
        volunteerCheckbox.checked = user.isVolunteer === true;
    }

    // Reset View
    toggleCitizenEditMode(false);
    
    // Open Modal
    openModal('citizen-modal');
}

function closeCitizenModal() {
    closeModal('citizen-modal');
    selectedCitizen = null;
}

function toggleCitizenEditMode(isEditing) {
    const viewMode = document.getElementById('citizen-view-mode');
    const editMode = document.getElementById('citizen-edit-mode');
    
    const closeBtn = document.getElementById('modal-citizen-close-btn');
    const editBtn = document.getElementById('modal-citizen-edit-btn');
    const cancelBtn = document.getElementById('modal-citizen-cancel-btn');
    const saveBtn = document.getElementById('modal-citizen-save-btn');
    
    if (isEditing) {
        viewMode.style.display = 'none';
        editMode.style.display = 'block';
        
        closeBtn.style.display = 'none';
        editBtn.style.display = 'none';
        
        cancelBtn.style.display = 'inline-block';
        saveBtn.style.display = 'inline-block';
    } else {
        viewMode.style.display = 'block';
        editMode.style.display = 'none';
        
        closeBtn.style.display = 'inline-block';
        editBtn.style.display = 'inline-block';
        
        cancelBtn.style.display = 'none';
        saveBtn.style.display = 'none';
    }
}

async function saveCitizenChanges() {
    if (!selectedCitizen) return;
    
    const userId = selectedCitizen._id;
    
    const fullName = document.getElementById('edit-citizen-name').value.trim();
    const age = parseInt(document.getElementById('edit-citizen-age').value.trim());
    const bloodType = document.getElementById('edit-citizen-blood').value;
    const phone = document.getElementById('edit-citizen-phone').value.trim();
    const email = document.getElementById('edit-citizen-email').value.trim();
    const address = document.getElementById('edit-citizen-address').value.trim();
    const medicalInfo = document.getElementById('edit-citizen-medical').value.trim();
    const emergencyName = document.getElementById('edit-citizen-emergency-name').value.trim();
    const emergencyPhone = document.getElementById('edit-citizen-emergency-phone').value.trim();
    
    // Read volunteer check status
    const volunteerCheckbox = document.getElementById('edit-citizen-volunteer');
    const isVolunteer = volunteerCheckbox ? volunteerCheckbox.checked : false;
    
    if (!fullName || isNaN(age) || !phone || !emergencyName || !emergencyPhone) {
        alert('Veuillez remplir tous les champs obligatoires (Nom, Âge, Téléphone, Nom & Tél du contact d\'urgence).');
        return;
    }
    
    const payload = {
        fullName,
        age,
        bloodType,
        phone,
        email: email || undefined,
        address,
        medicalInfo,
        isVolunteer,
        emergencyContact: {
            name: emergencyName,
            phone: emergencyPhone
        }
    };
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/auth/users/${userId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        if (res.success) {
            // Update state
            const index = state.users.findIndex(u => u._id === userId);
            if (index !== -1) {
                state.users[index] = res.user;
            }
            
            // Refresh tables
            populateUsersTable();
            refreshAllData();
            
            closeCitizenModal();
            alert('Profil citoyen mis à jour avec succès !');
        } else {
            throw new Error(res.message || 'Failed to update citizen profile');
        }
    } catch (err) {
        console.error(err);
        alert(`Erreur de mise à jour: ${err.message}`);
    }
}

async function deleteCitizenAccount() {
    if (!selectedCitizen) return;
    
    const userId = selectedCitizen._id;
    const confirmDelete = confirm(`Êtes-vous sûr de vouloir désactiver le compte de ${selectedCitizen.fullName} ? Il ne figurera plus dans la liste des citoyens.`);
    if (!confirmDelete) return;
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/auth/users/${userId}`, {
            method: 'DELETE'
        });
        
        if (res.success) {
            // Remove from state list
            state.users = state.users.filter(u => u._id !== userId);
            
            // Refresh
            populateUsersTable();
            refreshAllData();
            
            closeCitizenModal();
            alert('Compte citoyen désactivé avec succès !');
        } else {
            throw new Error(res.message || 'Failed to deactivate citizen account');
        }
    } catch (err) {
        console.error(err);
        alert(`Erreur de désactivation: ${err.message}`);
    }
}

// --- VIEW 5: ADMIN NOTIFICATIONS CONTROLLER ---
async function handleNotificationSubmit(e) {
    e.preventDefault();
    const submitBtn = document.getElementById('notif-submit-btn');
    submitBtn.disabled = true;
    
    const title = notifTitle.value.trim();
    const body = notifBody.value.trim();
    const targetType = notifTargetType.value;
    const governorate = notifGovernorate.value;
    const userPhone = notifPhone.value.trim();
    
    if (targetType === 'user' && !userPhone) {
        alert('Veuillez renseigner le numéro de téléphone pour un ciblage individuel.');
        submitBtn.disabled = false;
        return;
    }
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/notifications`, {
            method: 'POST',
            body: JSON.stringify({
                title,
                body,
                targetType,
                governorate: targetType === 'region' ? governorate : undefined,
                userPhone: targetType === 'user' ? userPhone : undefined
            })
        });
        
        if (res.success) {
            // Reset form
            notifTitle.value = '';
            notifBody.value = '';
            notifPhone.value = '';
            notifTargetType.value = 'all';
            notifGovernorateGroup.style.display = 'none';
            notifPhoneGroup.style.display = 'none';
            
            // Refresh history
            loadNotificationsHistory();
            alert('Notification d\'administration envoyée avec succès !');
        } else {
            throw new Error(res.message || 'Failed to send notification');
        }
    } catch (err) {
        console.error(err);
        alert(`Erreur d'envoi: ${err.message}`);
    } finally {
        submitBtn.disabled = false;
    }
}

async function loadNotificationsHistory() {
    if (!notificationsHistoryContainer) return;
    
    notificationsHistoryContainer.innerHTML = `
        <div style="text-align: center; color: var(--text-muted); padding: 40px 0;">
            <i class="fa-solid fa-spinner fa-spin" style="margin-right: 8px;"></i> Chargement de l'historique...
        </div>
    `;
    
    try {
        const res = await fetchWithAuth(`${API_BASE_URL}/notifications/all`);
        if (!res.success) throw new Error(res.message || 'Failed to load notifications');
        
        notificationsHistoryContainer.innerHTML = '';
        
        if (res.notifications.length === 0) {
            notificationsHistoryContainer.innerHTML = `
                <div style="text-align: center; color: var(--text-muted); padding: 40px 0;">
                    Aucune notification n'a été envoyée pour le moment.
                </div>
            `;
            return;
        }
        
        // Save to state for easy modal search
        state.notifications = res.notifications;
        
        res.notifications.forEach(notif => {
            let targetLabel = '';
            let targetBadgeColor = '#3b82f6';
            if (notif.targetType === 'all') {
                targetLabel = 'Tous les citoyens';
                targetBadgeColor = '#10b981';
            } else if (notif.targetType === 'region') {
                targetLabel = `Région: ${notif.governorate}`;
                targetBadgeColor = '#f59e0b';
            } else if (notif.targetType === 'user') {
                targetLabel = `Tél: ${notif.userPhone}`;
                targetBadgeColor = '#8b5cf6';
            } else if (notif.targetType === 'volunteers') {
                targetLabel = 'Tous les bénévoles';
                targetBadgeColor = '#22c55e';
            } else if (notif.targetType === 'non_volunteers') {
                targetLabel = 'Tous les non bénévoles';
                targetBadgeColor = '#6b7280';
            }
            
            const card = document.createElement('div');
            card.className = 'alert-feed-card'; // Reuse alert card styling for nice visual integration
            card.style.borderLeft = `4px solid ${targetBadgeColor}`;
            card.style.marginBottom = '12px';
            card.style.cursor = 'pointer';
            card.addEventListener('click', () => openNotificationModal(notif._id));
            card.innerHTML = `
                <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                    <h4 style="margin: 0; color: white; font-size: 15px; font-weight: 700;">${notif.title}</h4>
                    <span class="badge" style="background: rgba(255,255,255,0.05); color: ${targetBadgeColor}; border: 1px solid ${targetBadgeColor}40; padding: 2px 8px; font-size: 11px;">
                        ${targetLabel}
                    </span>
                </div>
                <p style="margin: 0 0 10px 0; font-size: 13px; color: var(--text-muted); line-height: 1.5;">${notif.body}</p>
                <div style="font-size: 11px; color: var(--text-muted); text-align: right;">
                    <i class="fa-regular fa-clock" style="margin-right: 4px;"></i> ${formatDate(notif.createdAt)}
                </div>
            `;
            notificationsHistoryContainer.appendChild(card);
        });
    } catch (err) {
        console.error(err);
        notificationsHistoryContainer.innerHTML = `
            <div style="text-align: center; color: #ef4444; padding: 30px 0;">
                <i class="fa-solid fa-circle-xmark" style="margin-right: 8px;"></i> Erreur de chargement: ${err.message}
            </div>
        `;
    }
}

// --- NOTIFICATION MODAL ACTIONS ---
function openNotificationModal(notifId) {
    const notif = state.notifications.find(n => n._id === notifId);
    if (!notif) return;
    
    document.getElementById('modal-notif-id').value = notif._id;
    document.getElementById('view-notif-title').textContent = notif.title;
    document.getElementById('view-notif-body').textContent = notif.body;
    document.getElementById('view-notif-date').textContent = formatDate(notif.createdAt);
    
    let targetLabel = '';
    let targetColor = '#3b82f6';
    if (notif.targetType === 'all') {
        targetLabel = 'Tous les citoyens';
        targetColor = '#10b981';
    } else if (notif.targetType === 'region') {
        targetLabel = `Région: ${notif.governorate}`;
        targetColor = '#f59e0b';
    } else if (notif.targetType === 'user') {
        targetLabel = `Tél: ${notif.userPhone}`;
        targetColor = '#8b5cf6';
    } else if (notif.targetType === 'volunteers') {
        targetLabel = 'Tous les bénévoles';
        targetColor = '#22c55e';
    } else if (notif.targetType === 'non_volunteers') {
        targetLabel = 'Tous les non bénévoles';
        targetColor = '#6b7280';
    }
    
    const targetBadge = document.getElementById('view-notif-target');
    targetBadge.textContent = targetLabel;
    targetBadge.style.color = targetColor;
    targetBadge.style.border = `1px solid ${targetColor}40`;
    targetBadge.style.background = 'rgba(255,255,255,0.03)';
    
    // Set up edit inputs
    document.getElementById('edit-notif-title').value = notif.title;
    document.getElementById('edit-notif-body').value = notif.body;
    
    toggleNotificationEditMode(false);
    
    openModal('notification-modal');
}

function closeNotificationModal() {
    closeModal('notification-modal');
}

function toggleNotificationEditMode(isEditing) {
    const viewMode = document.getElementById('notif-view-mode');
    const editMode = document.getElementById('notif-edit-mode');
    
    const editBtn = document.getElementById('modal-notif-edit-btn');
    const closeBtn = document.getElementById('modal-notif-close-btn');
    const cancelBtn = document.getElementById('modal-notif-cancel-btn');
    const saveBtn = document.getElementById('modal-notif-save-btn');
    const deleteBtn = document.getElementById('modal-notif-delete-btn');
    
    if (isEditing) {
        viewMode.style.display = 'none';
        editMode.style.display = 'block';
        editBtn.style.display = 'none';
        closeBtn.style.display = 'none';
        cancelBtn.style.display = 'inline-block';
        saveBtn.style.display = 'inline-block';
        deleteBtn.style.display = 'none'; // hide delete when editing
    } else {
        viewMode.style.display = 'block';
        editMode.style.display = 'none';
        editBtn.style.display = 'inline-block';
        closeBtn.style.display = 'inline-block';
        cancelBtn.style.display = 'none';
        saveBtn.style.display = 'none';
        deleteBtn.style.display = 'inline-block';
    }
}

async function saveNotificationChanges() {
    const notifId = document.getElementById('modal-notif-id').value;
    const title = document.getElementById('edit-notif-title').value.trim();
    const body = document.getElementById('edit-notif-body').value.trim();
    
    if (!title || !body) {
        alert('Le titre et le message de la notification ne peuvent pas être vides.');
        return;
    }
    
    const saveBtn = document.getElementById('modal-notif-save-btn');
    saveBtn.disabled = true;
    saveBtn.textContent = 'Enregistrement...';
    
    try {
        const data = await fetchWithAuth(`${API_BASE_URL}/notifications/${notifId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title, body })
        });
        
        if (data.success) {
            closeNotificationModal();
            loadNotificationsHistory(); // reload feed
        } else {
            alert(data.message || 'Erreur lors de la mise à jour de la notification.');
        }
    } catch (e) {
        console.error(e);
        alert('Erreur serveur lors de la mise à jour.');
    } finally {
        saveBtn.disabled = false;
        saveBtn.textContent = 'Enregistrer';
    }
}

async function deleteNotification() {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette notification ?')) return;
    
    const notifId = document.getElementById('modal-notif-id').value;
    const deleteBtn = document.getElementById('modal-notif-delete-btn');
    deleteBtn.disabled = true;
    
    try {
        const data = await fetchWithAuth(`${API_BASE_URL}/notifications/${notifId}`, {
            method: 'DELETE'
        });
        
        if (data.success) {
            closeNotificationModal();
            loadNotificationsHistory(); // reload feed
        } else {
            alert(data.message || 'Erreur lors de la suppression.');
        }
    } catch (e) {
        console.error(e);
        alert('Erreur serveur lors de la suppression.');
    } finally {
        deleteBtn.disabled = false;
    }
}

// --- VIEW 6: LIVES CONTROLLER ---
const livesGridContainer = document.getElementById('lives-grid-container');

function populateLivesGrid() {
    if (!livesGridContainer) return;
    livesGridContainer.innerHTML = '';
    
    const activeLives = state.lives || [];
    
    // Load recorded lives history
    populateRecordedLivesTable();
    
    if (activeLives.length === 0) {
        livesGridContainer.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; color: var(--text-muted); padding: 60px 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 16px;">
                <div style="width: 70px; height: 70px; border-radius: 50%; background: rgba(255,255,255,0.03); display: flex; align-items: center; justify-content: center; color: var(--text-muted); border: 1px solid var(--card-border);">
                    <i class="fa-solid fa-video-slash" style="font-size: 28px;"></i>
                </div>
                <div>
                    <h4 style="margin: 0 0 6px 0; color: white;">Aucun flux vidéo actif</h4>
                    <p style="margin: 0; font-size: 13px; color: var(--text-muted);">En attente de transmissions en direct des citoyens sur l\'application mobile.</p>
                </div>
            </div>
        `;
        return;
    }
    
    activeLives.forEach(live => {
        const user = live.user || {};
        const fullName = user.fullName || 'Citoyen Inconnu';
        const phone = user.phone || 'N/A';
        const locationText = `${user.delegation || ''}, ${user.governorate || 'Localisation Inconnue'}`;
        const medicalWarning = user.medicalInfo && user.medicalInfo.trim() !== '' && user.medicalInfo.toLowerCase() !== 'aucun' && user.medicalInfo.toLowerCase() !== 'aucune'
            ? `<div style="font-size: 11px; color: #f87171; font-weight: 700; background: rgba(239, 68, 68, 0.08); padding: 4px 8px; border-radius: 6px; display: inline-flex; align-items: center; gap: 4px; border: 1px solid rgba(239, 68, 68, 0.15); margin-top: 6px;"><i class="fa-solid fa-circle-exclamation"></i> Allergie/Médicaments: ${user.medicalInfo}</div>`
            : '';
            
        const card = document.createElement('div');
        card.className = 'panel-card';
        card.style.padding = '0';
        card.style.overflow = 'hidden';
        card.style.display = 'flex';
        card.style.flexDirection = 'column';
        card.style.background = 'var(--modal-bg)';
        card.style.borderRadius = '20px';
        card.style.border = '1px solid var(--card-border)';
        
        card.innerHTML = `
            <div style="position: relative; width: 100%; height: 450px; background: #000; display: flex; align-items: center; justify-content: center;">
                <img id="live-frame-${live.user._id}" src="${API_BASE_URL}/lives/frame/${live.user._id}?t=${Date.now()}" style="width: 100%; height: 100%; object-fit: contain;" onerror="this.src='https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=400&q=80'" />
                
                <div style="position: absolute; top: 12px; left: 12px; display: flex; align-items: center; gap: 6px; background: rgba(0,0,0,0.6); padding: 4px 10px; border-radius: 20px; backdrop-filter: blur(4px); border: 1px solid rgba(255,255,255,0.1);">
                    <span style="width: 8px; height: 8px; background-color: #ef4444; border-radius: 50%; display: inline-block; animation: pulse 1s infinite;"></span>
                    <span style="color: #ef4444; font-size: 10px; font-weight: 800; letter-spacing: 0.5px;">DIRECT</span>
                </div>
                
                <div style="position: absolute; bottom: 12px; left: 12px; right: 12px; display: flex; justify-content: space-between; align-items: center; background: rgba(0,0,0,0.6); padding: 6px 12px; border-radius: 8px; backdrop-filter: blur(4px); border: 1px solid rgba(255,255,255,0.05);">
                    <span style="color: white; font-size: 11px; font-weight: 700; font-family: monospace;">CAM_${phone.substring(phone.length - 4)}</span>
                    <span style="color: #60a5fa; font-size: 11px; font-weight: 700;"><i class="fa-solid fa-location-dot"></i> ${locationText}</span>
                </div>
            </div>
            
            <div style="padding: 16px; display: flex; flex-direction: column; gap: 8px; flex-grow: 1;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <h4 style="margin: 0; color: white; font-size: 15px; font-weight: 800;">${fullName}</h4>
                    <span style="font-size: 11px; color: var(--text-muted); font-weight: 600;">${phone}</span>
                </div>
                
                ${medicalWarning}
                
                <div style="margin-top: auto; display: flex; gap: 10px; border-top: 1px solid var(--card-border); padding-top: 12px; justify-content: space-between; align-items: center;">
                    <a href="https://www.google.com/maps/search/?api=1&query=${live.latitude},${live.longitude}" target="_blank" class="map-link" style="font-size: 12px;">
                        <i class="fa-solid fa-map-location-dot"></i> Localiser GPS
                    </a>
                    <button class="btn-action success" onclick="openCitizenModalFromPhone('${phone}')" style="padding: 6px 12px; font-size: 11px; border-radius: 6px;">
                        <i class="fa-solid fa-id-card"></i> Fiche Citoyen
                    </button>
                </div>
            </div>
        `;
        livesGridContainer.appendChild(card);
    });
}

function openCitizenModalFromPhone(phone) {
    const user = state.users.find(u => u.phone === phone);
    if (user) {
        openCitizenModal(user._id);
    } else {
        alert('Impossible de trouver la fiche détaillée du citoyen.');
    }
}

// --- DYNAMIC SAFETY TIPS MANAGEMENT ---
let safetyTipsState = [];

async function populateSafetyTipsTable() {
    const tableBody = document.getElementById('safety-tips-table-body');
    if (!tableBody) return;

    tableBody.innerHTML = `
        <tr>
            <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 40px 0;">
                <i class="fa-solid fa-spinner fa-spin" style="font-size: 20px; margin-bottom: 8px;"></i>
                <div>Chargement des conseils de sécurité...</div>
            </td>
        </tr>
    `;

    try {
        const resData = await fetchWithAuth(`${API_BASE_URL}/safety-tips`);
        if (resData.success) {
            safetyTipsState = resData.data;
            renderSafetyTipsTable(safetyTipsState);
        } else {
            showTableError(tableBody, 'Erreur lors du chargement des conseils.');
        }
    } catch (err) {
        console.error('Error fetching safety tips:', err);
        showTableError(tableBody, 'Impossible de se connecter au serveur.');
    }
}

function showTableError(tableBody, msg) {
    tableBody.innerHTML = `
        <tr>
            <td colspan="5" style="text-align: center; color: #ef4444; padding: 30px 0; font-weight: 600;">
                <i class="fa-solid fa-triangle-exclamation" style="margin-bottom: 8px; font-size: 18px;"></i>
                <div>${msg}</div>
            </td>
        </tr>
    `;
}

function getIconEmoji(iconName) {
    const map = {
        local_fire_department: '🔥',
        water_damage: '🌊',
        thermostat: '🌡️',
        medical_services: '🏥',
        warning: '⚠️',
        help_outline: '❓'
    };
    return map[iconName] || '💡';
}

function renderSafetyTipsTable(tips) {
    const tableBody = document.getElementById('safety-tips-table-body');
    if (!tableBody) return;

    tableBody.innerHTML = '';

    if (tips.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 40px 0;">
                    Aucun conseil de sécurité trouvé.
                </td>
            </tr>
        `;
        return;
    }

    tips.forEach(tip => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td style="font-size: 20px; text-align: center;">${getIconEmoji(tip.iconName)}</td>
            <td><strong>${tip.title}</strong><div style="font-size: 11px; color: var(--text-muted);">${tip.description}</div></td>
            <td style="text-align: right; direction: rtl;"><strong>${tip.titleAr}</strong><div style="font-size: 11px; color: var(--text-muted);">${tip.descriptionAr}</div></td>
            <td>
                <span class="badge" style="background: var(--input-bg); color: var(--text-main); border: 1px solid var(--card-border); padding: 4px 8px;">
                    ${tip.category}
                </span>
            </td>
            <td>
                <div style="display: flex; gap: 8px;">
                    <button class="btn-action" onclick="openEditSafetyTipModal('${tip._id}')" style="padding: 6px 12px; background: rgba(59, 130, 246, 0.08); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.15); border-radius: 8px;">
                        <i class="fa-solid fa-edit"></i> Modifier
                    </button>
                    <button class="btn-action danger" onclick="deleteSafetyTip('${tip._id}')" style="padding: 6px 12px; border-radius: 8px;">
                        <i class="fa-solid fa-trash-can"></i> Supprimer
                    </button>
                </div>
            </td>
        `;
        tableBody.appendChild(tr);
    });
}

function openAddSafetyTipModal() {
    document.getElementById('safety-tip-modal-title').textContent = 'Ajouter un Conseil de Sécurité';
    document.getElementById('safety-tip-id').value = '';
    document.getElementById('safety-tip-form').reset();
    
    document.getElementById('safety-tip-dos-container').innerHTML = '';
    document.getElementById('safety-tip-donts-container').innerHTML = '';
    
    // Add one default empty field to start
    addDoField('', '');
    addDontField('', '');
    
    openModal('safety-tip-modal');
}

function openEditSafetyTipModal(id) {
    const tip = safetyTipsState.find(t => t._id === id);
    if (!tip) return;

    document.getElementById('safety-tip-modal-title').textContent = 'Modifier le Conseil de Sécurité';
    document.getElementById('safety-tip-id').value = tip._id;
    document.getElementById('safety-tip-icon').value = tip.iconName;
    document.getElementById('safety-tip-category-fr').value = tip.category;
    document.getElementById('safety-tip-category-ar').value = tip.categoryAr;
    document.getElementById('safety-tip-title-fr').value = tip.title;
    document.getElementById('safety-tip-title-ar').value = tip.titleAr;
    document.getElementById('safety-tip-desc-fr').value = tip.description;
    document.getElementById('safety-tip-desc-ar').value = tip.descriptionAr;

    const dosContainer = document.getElementById('safety-tip-dos-container');
    const dontsContainer = document.getElementById('safety-tip-donts-container');
    
    dosContainer.innerHTML = '';
    dontsContainer.innerHTML = '';

    const maxDos = Math.max(tip.dos.length, tip.dosAr.length);
    for (let i = 0; i < maxDos; i++) {
        addDoField(tip.dos[i] || '', tip.dosAr[i] || '');
    }

    const maxDonts = Math.max(tip.donts.length, tip.dontsAr.length);
    for (let i = 0; i < maxDonts; i++) {
        addDontField(tip.donts[i] || '', tip.dontsAr[i] || '');
    }

    if (maxDos === 0) addDoField('', '');
    if (maxDonts === 0) addDontField('', '');

    openModal('safety-tip-modal');
}

function addDoField(valFr = '', valAr = '') {
    const container = document.getElementById('safety-tip-dos-container');
    const div = document.createElement('div');
    div.className = 'do-input-row';
    div.style = 'display: grid; grid-template-columns: 1fr 1fr 40px; gap: 8px; align-items: center;';
    div.innerHTML = `
        <input type="text" class="form-control form-control-noicon do-fr" placeholder="Action à faire (FR)" value="${valFr.replace(/"/g, '&quot;')}" required>
        <input type="text" class="form-control form-control-noicon do-ar" placeholder="Action à faire (AR)" value="${valAr.replace(/"/g, '&quot;')}" required style="text-align: right; direction: rtl;">
        <button type="button" class="btn-action danger" onclick="this.parentElement.remove()" style="padding: 10px; border-radius: 8px; height: 38px; display: flex; align-items: center; justify-content: center; border: 0;">
            <i class="fa-solid fa-minus"></i>
        </button>
    `;
    container.appendChild(div);
}

function addDontField(valFr = '', valAr = '') {
    const container = document.getElementById('safety-tip-donts-container');
    const div = document.createElement('div');
    div.className = 'dont-input-row';
    div.style = 'display: grid; grid-template-columns: 1fr 1fr 40px; gap: 8px; align-items: center;';
    div.innerHTML = `
        <input type="text" class="form-control form-control-noicon dont-fr" placeholder="Action à éviter (FR)" value="${valFr.replace(/"/g, '&quot;')}" required>
        <input type="text" class="form-control form-control-noicon dont-ar" placeholder="Action à éviter (AR)" value="${valAr.replace(/"/g, '&quot;')}" required style="text-align: right; direction: rtl;">
        <button type="button" class="btn-action danger" onclick="this.parentElement.remove()" style="padding: 10px; border-radius: 8px; height: 38px; display: flex; align-items: center; justify-content: center; border: 0;">
            <i class="fa-solid fa-minus"></i>
        </button>
    `;
    container.appendChild(div);
}

async function saveSafetyTip() {
    const id = document.getElementById('safety-tip-id').value;
    const form = document.getElementById('safety-tip-form');
    if (!form.checkValidity()) {
        form.reportValidity();
        return;
    }

    const iconName = document.getElementById('safety-tip-icon').value;
    const category = document.getElementById('safety-tip-category-fr').value;
    const categoryAr = document.getElementById('safety-tip-category-ar').value;
    const title = document.getElementById('safety-tip-title-fr').value;
    const titleAr = document.getElementById('safety-tip-title-ar').value;
    const description = document.getElementById('safety-tip-desc-fr').value;
    const descriptionAr = document.getElementById('safety-tip-desc-ar').value;

    const dos = Array.from(document.querySelectorAll('.do-fr')).map(el => el.value.trim());
    const dosAr = Array.from(document.querySelectorAll('.do-ar')).map(el => el.value.trim());
    
    const donts = Array.from(document.querySelectorAll('.dont-fr')).map(el => el.value.trim());
    const dontsAr = Array.from(document.querySelectorAll('.dont-ar')).map(el => el.value.trim());

    const payload = {
        iconName, category, categoryAr, title, titleAr, description, descriptionAr,
        dos, dosAr, donts, dontsAr
    };

    const url = id ? `${API_BASE_URL}/safety-tips/${id}` : `${API_BASE_URL}/safety-tips`;
    const method = id ? 'PUT' : 'POST';

    const saveBtn = document.getElementById('safety-tip-save-btn');
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Enregistrement...';

    try {
        const resData = await fetchWithAuth(url, {
            method,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        if (resData.success) {
            closeModal('safety-tip-modal');
            populateSafetyTipsTable();
        } else {
            alert(`Erreur: ${resData.message}`);
        }
    } catch (err) {
        console.error('Error saving safety tip:', err);
        alert('Erreur réseau lors de la sauvegarde du conseil.');
    } finally {
        saveBtn.disabled = false;
        saveBtn.textContent = 'Enregistrer';
    }
}

async function deleteSafetyTip(id) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer définitivement ce conseil de sécurité ?')) {
        return;
    }

    try {
        const resData = await fetchWithAuth(`${API_BASE_URL}/safety-tips/${id}`, {
            method: 'DELETE'
        });
        if (resData.success) {
            populateSafetyTipsTable();
        } else {
            alert(`Erreur: ${resData.message}`);
        }
    } catch (err) {
        console.error('Error deleting safety tip:', err);
        alert('Erreur réseau lors de la suppression.');
    }
}

// --- DYNAMIC RECORDED LIVES MANAGEMENT & SEQUENTIAL PLAYER ---
let recordedLivesState = [];
let playerIntervalId = null;
let playerIsPlaying = false;
let playerCurrentIndex = 0;
let playerTotalFrames = 0;
let playerActiveStreamId = '';
let playerDurationSeconds = 0;

async function populateRecordedLivesTable() {
    const tableBody = document.getElementById('recorded-lives-table-body');
    if (!tableBody) return;

    try {
        const resData = await fetchWithAuth(`${API_BASE_URL}/lives/recorded`);
        if (resData.success) {
            recordedLivesState = resData.recorded;
            renderRecordedLivesTable(recordedLivesState);
        } else {
            tableBody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #ef4444; padding: 20px 0;">Erreur lors du chargement des enregistrements.</td></tr>`;
        }
    } catch (err) {
        console.error('Error fetching recorded lives:', err);
        tableBody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #ef4444; padding: 20px 0;">Impossible de se connecter au serveur.</td></tr>`;
    }
}

function renderRecordedLivesTable(recordedList) {
    const tableBody = document.getElementById('recorded-lives-table-body');
    if (!tableBody) return;

    tableBody.innerHTML = '';

    if (recordedList.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 40px 0;">
                    Aucun enregistrement vidéo disponible.
                </td>
            </tr>
        `;
        return;
    }

    recordedList.forEach(recorded => {
        const user = recorded.user || {};
        const fullName = user.fullName || 'Citoyen Inconnu';
        const phone = user.phone || 'N/A';
        const dateStr = new Date(recorded.createdAt).toLocaleString('fr-FR');
        const durationStr = `${recorded.duration}s`;

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>
                <strong>${fullName}</strong>
                <div style="font-size: 11px; color: var(--text-muted);">${phone}</div>
            </td>
            <td>${dateStr}</td>
            <td><span class="badge" style="background: rgba(59, 130, 246, 0.08); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.15); border-radius: 6px; padding: 4px 8px; font-weight: 700;">${durationStr}</span></td>
            <td>${recorded.frameCount} trames</td>
            <td>
                <a href="https://www.google.com/maps/search/?api=1&query=${recorded.latitude},${recorded.longitude}" target="_blank" class="map-link">
                    <i class="fa-solid fa-location-dot"></i> GPS
                </a>
            </td>
            <td>
                <div style="display: flex; gap: 8px;">
                    <button class="btn-action" onclick="openVideoPlayerModal('${recorded._id}')" style="padding: 6px 12px; background: rgba(16, 185, 129, 0.08); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.15); border-radius: 8px;">
                        <i class="fa-solid fa-play"></i> Lire
                    </button>
                    <button class="btn-action danger" onclick="deleteRecordedLive('${recorded._id}')" style="padding: 6px 12px; border-radius: 8px;">
                        <i class="fa-solid fa-trash-can"></i> Supprimer
                    </button>
                </div>
            </td>
        `;
        tableBody.appendChild(tr);
    });
}

function openVideoPlayerModal(recordedId) {
    const recorded = recordedLivesState.find(r => r._id === recordedId);
    if (!recorded) return;

    // Reset player state
    playerActiveStreamId = recorded.streamId;
    playerTotalFrames = recorded.frameCount;
    playerDurationSeconds = recorded.duration;
    playerCurrentIndex = 0;
    playerIsPlaying = false;
    
    if (playerIntervalId) {
        clearInterval(playerIntervalId);
        playerIntervalId = null;
    }

    const user = recorded.user || {};
    const title = document.getElementById('player-modal-title');
    if (title) {
        title.textContent = `Enregistrement : ${user.fullName || 'Citoyen'} - ${new Date(recorded.createdAt).toLocaleDateString('fr-FR')}`;
    }

    // Set slider range
    const slider = document.getElementById('player-progress');
    if (slider) {
        slider.max = playerTotalFrames > 0 ? playerTotalFrames - 1 : 0;
        slider.value = 0;
    }

    // Show placeholder and hide frame image
    const placeholder = document.getElementById('player-placeholder');
    const img = document.getElementById('player-frame');
    if (placeholder) placeholder.style.display = 'flex';
    if (img) img.style.display = 'none';

    // Set duration labels
    document.getElementById('player-current-time').textContent = '0s';
    document.getElementById('player-total-time').textContent = `${playerDurationSeconds}s`;

    // Reset Play Button Icon
    const playBtn = document.getElementById('player-play-btn');
    if (playBtn) {
        playBtn.innerHTML = '<i class="fa-solid fa-play" style="font-size: 16px;"></i>';
    }

    openModal('video-player-modal');
}

function closeVideoPlayerModal() {
    // Stop playback
    if (playerIntervalId) {
        clearInterval(playerIntervalId);
        playerIntervalId = null;
    }
    playerIsPlaying = false;
    
    // Clear image src to free memory
    const img = document.getElementById('player-frame');
    if (img) img.src = '';

    closeModal('video-player-modal');
}

function togglePlayerPlay() {
    const playBtn = document.getElementById('player-play-btn');
    if (!playBtn || playerTotalFrames === 0) return;

    if (playerIsPlaying) {
        // Pause
        if (playerIntervalId) {
            clearInterval(playerIntervalId);
            playerIntervalId = null;
        }
        playerIsPlaying = false;
        playBtn.innerHTML = '<i class="fa-solid fa-play" style="font-size: 16px;"></i>';
    } else {
        // Play
        playerIsPlaying = true;
        playBtn.innerHTML = '<i class="fa-solid fa-pause" style="font-size: 16px;"></i>';

        // Hide placeholder and show frame image
        const placeholder = document.getElementById('player-placeholder');
        const img = document.getElementById('player-frame');
        if (placeholder) placeholder.style.display = 'none';
        if (img) img.style.display = 'block';

        // Run frame sequence loop (using 300ms intervals which matches frame streaming preset)
        playerIntervalId = setInterval(() => {
            if (playerCurrentIndex >= playerTotalFrames - 1) {
                // End of video -> Pause
                togglePlayerPlay();
                return;
            }
            playerCurrentIndex++;
            updatePlayerUI();
        }, 300);
    }
}

function updatePlayerUI() {
    const img = document.getElementById('player-frame');
    const slider = document.getElementById('player-progress');
    const currentTimeText = document.getElementById('player-current-time');

    if (img) {
        img.src = `${API_BASE_URL}/uploads/recordings/${playerActiveStreamId}/${playerCurrentIndex}.jpg`;
    }

    if (slider) {
        slider.value = playerCurrentIndex;
    }

    if (currentTimeText && playerTotalFrames > 1) {
        const pct = playerCurrentIndex / (playerTotalFrames - 1);
        const curSeconds = Math.round(pct * playerDurationSeconds);
        currentTimeText.textContent = `${curSeconds}s`;
    }
}

function onPlayerProgressSeek(value) {
    playerCurrentIndex = parseInt(value, 10);
    
    // Hide placeholder and show frame image
    const placeholder = document.getElementById('player-placeholder');
    const img = document.getElementById('player-frame');
    if (placeholder) placeholder.style.display = 'none';
    if (img) img.style.display = 'block';

    updatePlayerUI();
}

function playerStepBack() {
    if (playerCurrentIndex > 0) {
        playerCurrentIndex--;
        updatePlayerUI();
    }
}

function playerStepForward() {
    if (playerCurrentIndex < playerTotalFrames - 1) {
        playerCurrentIndex++;
        updatePlayerUI();
    }
}

async function deleteRecordedLive(id) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer définitivement cet enregistrement vidéo et toutes ses trames ?')) {
        return;
    }

    try {
        const resData = await fetchWithAuth(`${API_BASE_URL}/lives/recorded/${id}`, {
            method: 'DELETE'
        });
        if (resData.success) {
            populateRecordedLivesTable();
        } else {
            alert(`Erreur: ${resData.message}`);
        }
    } catch (err) {
        console.error('Error deleting recorded live:', err);
        alert('Erreur réseau lors de la suppression.');
    }
}

// --- LIVE MAP SURVEILLANCE CONTROLLER ---
let mapInstance = null;
let mapMarkersGroup = null;

async function initializeOrUpdateMap() {
    const mapContainer = document.getElementById('surveillance-map');
    if (!mapContainer) return;

    if (!mapInstance) {
        // Initialize Leaflet map centered on Tunisia (center coordinates)
        mapInstance = L.map('surveillance-map').setView([35.5, 9.5], 7);

        // Add standard styled OpenStreetMap tile layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 18,
            attribution: '© OpenStreetMap contributors'
        }).addTo(mapInstance);

        mapMarkersGroup = L.layerGroup().addTo(mapInstance);
    }

    // Force size recalculation for leaflet div within tabs
    setTimeout(() => {
        if (mapInstance) {
            mapInstance.invalidateSize();
        }
    }, 150);

    // Draw markers immediately
    await drawMapMarkers();
}

const GOVERNORATE_COORDS = {
    tunis: [36.8065, 10.1815],
    nabeul: [36.4561, 10.7376],
    sousse: [35.8256, 10.6369],
    sfax: [34.7406, 10.7603],
    bizerte: [37.2744, 9.8739],
    kairouan: [35.6781, 10.0963],
    gabes: [33.8815, 10.0982],
    medenine: [33.3549, 10.4958],
    gafsa: [34.4250, 8.7842],
    monastir: [35.7833, 10.8333],
    ariana: [36.8625, 10.1956],
    'ben arous': [36.7531, 10.2228],
    manouba: [36.8078, 10.0864],
    'le kef': [36.1742, 8.7049],
    kef: [36.1742, 8.7049],
    beja: [36.7256, 9.1817],
    jendouba: [36.5011, 8.7802],
    siliana: [36.0848, 9.3708],
    zaghouan: [36.4029, 10.1429],
    kasserine: [35.1676, 8.8360],
    'sidi bouzid': [35.0382, 9.4849],
    mahdia: [35.5047, 11.0622],
    tozeur: [33.9198, 8.1335],
    kebili: [33.7044, 8.9690],
    tataouine: [32.9297, 10.4518]
};

async function drawMapMarkers() {
    if (!mapMarkersGroup) return;
    mapMarkersGroup.clearLayers();

    try {
        // Fetch incidents
        const incRes = await fetchWithAuth(`${API_BASE_URL}/incidents?limit=200`);
        const incidents = incRes.success ? incRes.incidents : [];

        // Fetch users
        const usersRes = await fetchWithAuth(`${API_BASE_URL}/auth/users`);
        const users = usersRes.success ? usersRes.users : [];

        // 1. Plot pending incidents (status: "pending") as RED circles
        incidents.forEach(inc => {
            let lat = inc.geolocation ? inc.geolocation.latitude : null;
            let lng = inc.geolocation ? inc.geolocation.longitude : null;

            // Fallback to governorate if coordinates are missing
            if ((!lat || !lng) && inc.governorate) {
                const govKey = inc.governorate.toLowerCase().trim();
                if (GOVERNORATE_COORDS[govKey]) {
                    lat = GOVERNORATE_COORDS[govKey][0] + (Math.random() - 0.5) * 0.04;
                    lng = GOVERNORATE_COORDS[govKey][1] + (Math.random() - 0.5) * 0.04;
                }
            }

            if (inc.status === 'pending' && lat && lng) {
                const type = inc.type || 'Incident';
                
                const circle = L.circle([lat, lng], {
                    color: '#ef4444',
                    fillColor: '#f87171',
                    fillOpacity: 0.5,
                    radius: 250 // 250m radius
                });

                // Tooltip showing name on hover
                circle.bindTooltip(`<strong>${type}</strong>`, { direction: 'top' });

                // Open same details modal when clicked
                circle.on('click', () => {
                    showIncidentDetails(inc._id);
                });

                mapMarkersGroup.addLayer(circle);
            }
        });

        // 2. Plot users based on active status
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

        users.forEach(user => {
            const isActiveRecently = user.lastActiveAt && new Date(user.lastActiveAt) > oneHourAgo;
            const isOnline = user.isOnline;

            let color = '';
            let statusLabel = '';

            if (isOnline) {
                if (user.isVolunteer) {
                    color = '#3b82f6'; // Blue for Online Volunteers
                } else {
                    color = '#10b981'; // Green for Online Citizens (non-volunteers)
                }
            } else if (isActiveRecently) {
                color = '#f59e0b'; // Orange for recently active
            } else {
                // Skip if inactive for more than 1 hour to avoid cluttering
                return;
            }

            let lat = user.lastLatitude;
            let lng = user.lastLongitude;

            // Fallback to governorate coordinates if missing
            if ((!lat || !lng) && user.governorate) {
                const govKey = user.governorate.toLowerCase().trim();
                if (GOVERNORATE_COORDS[govKey]) {
                    // Seed a random offset to prevent exact overlap
                    lat = GOVERNORATE_COORDS[govKey][0] + (Math.random() - 0.5) * 0.05;
                    lng = GOVERNORATE_COORDS[govKey][1] + (Math.random() - 0.5) * 0.05;
                }
            }

            if (lat && lng) {
                const circleMarker = L.circleMarker([lat, lng], {
                    color: color,
                    fillColor: color,
                    fillOpacity: 0.8,
                    radius: 8
                });

                // Tooltip showing user details on hover
                const roleSuffix = user.isVolunteer ? ' (Bénévole)' : ' (Citoyen)';
                circleMarker.bindTooltip(`<strong>${user.fullName}${roleSuffix}</strong>`, { direction: 'top' });

                // Open same details modal when clicked
                circleMarker.on('click', () => {
                    openCitizenModal(user._id);
                });

                mapMarkersGroup.addLayer(circleMarker);
            }
        });

    } catch (err) {
        console.error('Error drawing map markers:', err);
    }
}

// --- REAL-TIME SOCKET.IO CLIENT CONTROLLER ---
let socket = null;

function initializeSocket() {
    if (!state.token) return;
    if (socket) return;

    console.log('🔌 Connecting to Socket.io backend...');
    socket = io(API_BASE_URL);

    socket.on('connect', () => {
        console.log('⚡ Connected to Socket.io backend!');
    });

    // 1. Real-time Incident Signalement
    socket.on('new_incident', (incident) => {
        console.log('🚨 New incident received in real-time:', incident);
        
        // Add to state list (prepend at index 0)
        state.incidents.unshift(incident);

        // Play audio alert to grab attention
        playAlertSound();

        // Check if the current tab is 'incidents'
        if (state.activeTab === 'incidents') {
            populateIncidentsTable();
        } else {
            // Flashing red button in left sidebar
            const incidentsTabButton = document.querySelector('.sidebar-item[data-tab="incidents"]');
            if (incidentsTabButton) {
                incidentsTabButton.classList.add('flashing-red');
            }
        }

        // Also update charts if on overview
        if (state.activeTab === 'overview') {
            renderCharts();
        }

        // Also draw markers on the live map if the map view is open
        if (state.activeTab === 'map' && typeof drawMapMarkers === 'function') {
            drawMapMarkers();
        }
    });

    // 2. Real-time Live Stream Started
    socket.on('live_started', (live) => {
        console.log('📹 Live stream started in real-time:', live);
        
        // Add to state if not exists
        const exists = state.lives.some(l => l.user === live.user || l._id === live._id);
        if (!exists) {
            state.lives.unshift(live);
        }

        playAlertSound();

        // Check if current tab is 'lives'
        if (state.activeTab === 'lives') {
            populateLivesGrid();
        } else {
            // Flashing red button in left sidebar
            const livesTabButton = document.querySelector('.sidebar-item[data-tab="lives"]');
            if (livesTabButton) {
                livesTabButton.classList.add('flashing-red');
            }
        }
    });

    // 3. Real-time Live Stream Stopped
    socket.on('live_stopped', (data) => {
        console.log('📹 Live stream stopped in real-time:', data);
        
        // Remove from state
        state.lives = state.lives.filter(l => {
            const uid = l.user._id || l.user;
            return uid !== data.userId;
        });

        // Check if current tab is 'lives'
        if (state.activeTab === 'lives') {
            populateLivesGrid();
        }
    });

    // 4. Live counts update
    socket.on('live_count_update', (data) => {
        console.log('📹 Live count update:', data);
        updateLiveBadge(data.count);
    });
}

function updateLiveBadge(count) {
    const badge = document.getElementById('live-count-badge');
    if (!badge) return;
    badge.textContent = count;
    if (count > 0) {
        badge.style.display = 'inline-block';
    } else {
        badge.style.display = 'none';
    }
}

function playAlertSound() {
    try {
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        
        // First tone
        const osc1 = audioCtx.createOscillator();
        const gain1 = audioCtx.createGain();
        osc1.connect(gain1);
        gain1.connect(audioCtx.destination);
        osc1.type = 'sine';
        osc1.frequency.setValueAtTime(587.33, audioCtx.currentTime); // D5
        gain1.gain.setValueAtTime(0.08, audioCtx.currentTime);
        gain1.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
        osc1.start(audioCtx.currentTime);
        osc1.stop(audioCtx.currentTime + 0.15);
        
        // Second tone slightly offset
        setTimeout(() => {
            const osc2 = audioCtx.createOscillator();
            const gain2 = audioCtx.createGain();
            osc2.connect(gain2);
            gain2.connect(audioCtx.destination);
            osc2.type = 'sine';
            osc2.frequency.setValueAtTime(880.00, audioCtx.currentTime); // A5
            gain2.gain.setValueAtTime(0.08, audioCtx.currentTime);
            gain2.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.25);
            osc2.start(audioCtx.currentTime);
            osc2.stop(audioCtx.currentTime + 0.25);
        }, 100);
    } catch (e) {
        console.warn('AudioContext not allowed or not supported:', e);
    }
}

// Show Incident Details Modal (grouped views)
function showIncidentDetails(id) {
    const inc = state.incidents.find(i => i._id === id);
    if (!inc) return;

    const typeInfo = translateType(inc.type);
    const statusInfo = translateStatus(inc.status);
    
    // Fill general details
    document.getElementById('detail-inc-type').innerHTML = `
        <span class="badge" style="background: rgba(239, 68, 68, 0.08); color: ${typeInfo.color}; padding: 6px 12px; border-radius: 8px;">
            <i class="fa-solid ${typeInfo.icon}"></i> ${typeInfo.fr}
        </span>
    `;
    
    const lat = inc.geolocation.latitude;
    const lng = inc.geolocation.longitude;
    const address = inc.geolocation.address || 'Tunisie';
    const mapUrl = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
    document.getElementById('detail-inc-location').innerHTML = `
        <div>${address}</div>
        <div style="margin-top: 4px;">
            <a href="${mapUrl}" target="_blank" class="map-link" style="font-size: 12px;">
                <i class="fa-solid fa-map-location-dot"></i> Voir sur Google Maps (${lat.toFixed(5)}, ${lng.toFixed(5)})
            </a>
        </div>
    `;

    document.getElementById('detail-inc-date').textContent = formatDate(inc.createdAt);

    let statusText = `<span class="badge ${statusInfo.class}">${statusInfo.label}</span>`;
    if (inc.assignedUnit) {
        statusText += `<div style="font-size: 11px; margin-top: 6px; color: var(--text-muted);">🚒 Unité: <strong>${inc.assignedUnit}</strong></div>`;
    }
    document.getElementById('detail-inc-status').innerHTML = statusText;

    // 1. Gather all medias
    const galleryContainer = document.getElementById('detail-inc-gallery');
    const noGalleryText = document.getElementById('detail-inc-no-gallery');
    galleryContainer.innerHTML = '';
    
    const medias = [];
    if (inc.mediaUrl) {
        medias.push({ url: `${API_BASE_URL}${inc.mediaUrl}`, type: inc.mediaType || 'image', reporterName: inc.reporter ? inc.reporter.fullName : 'Initial' });
    }
    
    if (inc.duplicates && inc.duplicates.length > 0) {
        inc.duplicates.forEach(dup => {
            if (dup.mediaUrl) {
                medias.push({ url: `${API_BASE_URL}${dup.mediaUrl}`, type: dup.mediaType || 'image', reporterName: dup.reporter ? dup.reporter.fullName : 'Doublon' });
            }
        });
    }

    if (medias.length > 0) {
        noGalleryText.style.display = 'none';
        galleryContainer.style.display = 'grid';
        medias.forEach(media => {
            const wrapper = document.createElement('div');
            wrapper.style.position = 'relative';
            wrapper.style.borderRadius = '6px';
            wrapper.style.overflow = 'hidden';
            wrapper.style.border = '1px solid var(--card-border)';
            wrapper.style.aspectRatio = '1/1';
            
            if (media.type === 'video') {
                wrapper.innerHTML = `
                    <div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: #000; cursor: pointer;" onclick="openMediaViewer('${media.url}', 'video')">
                        <i class="fa-solid fa-play" style="font-size: 24px; color: #fff; opacity: 0.8;"></i>
                    </div>
                    <div style="position: absolute; bottom: 0; left: 0; right: 0; background: rgba(0,0,0,0.6); color: #fff; font-size: 9px; padding: 2px 4px; text-overflow: ellipsis; overflow: hidden; white-space: nowrap;">
                        ${media.reporterName} (Vidéo)
                    </div>
                `;
            } else {
                wrapper.innerHTML = `
                    <img src="${media.url}" style="width: 100%; height: 100%; object-fit: cover; cursor: pointer;" onclick="openMediaViewer('${media.url}', 'image')" />
                    <div style="position: absolute; bottom: 0; left: 0; right: 0; background: rgba(0,0,0,0.6); color: #fff; font-size: 9px; padding: 2px 4px; text-overflow: ellipsis; overflow: hidden; white-space: nowrap;">
                        ${media.reporterName}
                    </div>
                `;
            }
            galleryContainer.appendChild(wrapper);
        });
    } else {
        noGalleryText.style.display = 'block';
        galleryContainer.style.display = 'none';
    }

    // 2. Build list of citizens
    const declarantsList = document.getElementById('detail-inc-declarants-list');
    declarantsList.innerHTML = '';
    
    const reportersList = [inc];
    if (inc.duplicates && inc.duplicates.length > 0) {
        reportersList.push(...inc.duplicates);
    }
    
    document.getElementById('detail-inc-declarants-count').textContent = reportersList.length;
    
    if (reportersList.length > 1) {
        document.getElementById('detail-inc-group-info').innerHTML = `
            <i class="fa-solid fa-circle-info" style="color: #3b82f6; margin-right: 4px;"></i> 
            <strong>Dédoublonnage actif :</strong> ${reportersList.length} rapports regroupés dans une zone de 200m aujourd'hui.
        `;
    } else {
        document.getElementById('detail-inc-group-info').textContent = '';
    }

    reportersList.forEach((report, index) => {
        const rep = report.reporter;
        const card = document.createElement('div');
        card.style.background = 'var(--modal-bg)';
        card.style.border = '1px solid var(--card-border)';
        card.style.borderRadius = '8px';
        card.style.padding = '12px';
        
        let headerHtml = '';
        if (rep) {
            const ageText = rep.age ? `${rep.age} ans` : 'Âge inconnu';
            const bloodColor = rep.bloodType && rep.bloodType.includes('-') ? '#f59e0b' : '#ef4444';
            const bloodBadge = rep.bloodType ? `<span style="background: rgba(239, 68, 68, 0.08); color: ${bloodColor}; padding: 2px 6px; border-radius: 4px; font-weight: 700; font-size: 10px; border: 1px solid rgba(239,68,68,0.15);">${rep.bloodType}</span>` : '';
            
            headerHtml = `
                <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 8px;">
                    <div>
                        <strong style="color: var(--text-main); font-size: 14px;">
                            ${index === 0 ? '🟢 Déclarant Principal :' : `🟠 Déclarant Secondaire #${index} :`} ${rep.fullName}
                        </strong>
                        <div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">
                            CIN: <strong>${rep.cin || 'Non renseignée'}</strong> | Tél: <strong>${rep.phone}</strong> | ${ageText}
                        </div>
                    </div>
                    ${bloodBadge}
                </div>
            `;
            
            // Medical Warnings banner
            if (rep.medicalInfo && rep.medicalInfo.trim() !== '' && rep.medicalInfo.toLowerCase() !== 'aucun' && rep.medicalInfo.toLowerCase() !== 'aucune') {
                headerHtml += `
                    <div style="background: rgba(239, 68, 68, 0.05); border: 1px solid rgba(239, 68, 68, 0.15); color: #f87171; border-radius: 6px; padding: 6px 10px; font-size: 11px; margin-top: 8px; font-weight: 600; display: flex; align-items: center; gap: 6px;">
                        <i class="fa-solid fa-circle-exclamation"></i>
                        <span>Fiche Médicale: ${rep.medicalInfo}</span>
                    </div>
                `;
            }
        } else {
            headerHtml = `
                <div>
                    <strong style="color: var(--text-main); font-size: 14px;">
                        ${index === 0 ? '🟢 Déclarant Principal :' : `🟠 Déclarant Secondaire #${index} :`} Citoyen Anonyme
                    </strong>
                </div>
            `;
        }

        let descText = report.description && report.description.trim() !== '' ? report.description.trim() : 'Aucune description textuelle fournie.';
        let voiceHtml = '';
        if (report.voiceUrl) {
            const absoluteVoiceUrl = `${API_BASE_URL}${report.voiceUrl}`;
            voiceHtml = `
                <div style="margin-top: 10px; display: flex; align-items: center; gap: 8px; background: rgba(0,0,0,0.03); border-radius: 6px; padding: 6px 10px; border: 1px solid var(--card-border);">
                    <i class="fa-solid fa-microphone" style="color: #3b82f6;"></i>
                    <span style="font-size: 11px; color: var(--text-muted); font-weight: 500;">Note Vocale:</span>
                    <audio src="${absoluteVoiceUrl}" controls style="max-width: 200px; height: 28px; outline: none;"></audio>
                </div>
            `;
        }

        card.innerHTML = `
            ${headerHtml}
            <div style="font-size: 13px; color: var(--text-main); margin-top: 10px; line-height: 1.4; font-style: italic;">
                "${descText}"
            </div>
            ${voiceHtml}
        `;
        
        declarantsList.appendChild(card);
    });

    openModal('incident-details-modal');
}
