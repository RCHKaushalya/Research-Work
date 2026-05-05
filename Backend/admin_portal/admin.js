const API_BASE = '/'; // Still used for custom token login and SMS queue
let token = localStorage.getItem('admin_token');

// Firebase Configuration
const firebaseConfig = {
    apiKey: "AIzaSyCtZyjw23-drhI1w1pXgOJI_4gxzLGe7gA",
    authDomain: "informal-worker-platform.firebaseapp.com",
    projectId: "informal-worker-platform",
    storageBucket: "informal-worker-platform.firebasestorage.app"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();
const auth = firebase.auth();

// DOM Elements
const loginContainer = document.getElementById('login-container');
const dashboardContainer = document.getElementById('dashboard-container');
const pinInput = document.getElementById('pin-input');
const loginBtn = document.getElementById('login-btn');
const errorMsg = document.getElementById('error-msg');
const logoutBtn = document.getElementById('logout-btn');
const queueSmsBtn = document.getElementById('queue-sms-btn');

// Initialization
auth.onAuthStateChanged(user => {
    if (user) {
        showDashboard();
    } else {
        loginContainer.classList.remove('hidden');
        dashboardContainer.classList.add('hidden');
    }
});

// Login logic
loginBtn.addEventListener('click', async () => {
    const pin = pinInput.value;
    try {
        const response = await fetch(`${API_BASE}admin/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ pin })
        });

        if (response.ok) {
            const data = await response.json();
            token = data.access_token;
            // Sign in to Firebase with custom token
            await auth.signInWithCustomToken(token);
        } else {
            errorMsg.textContent = 'Invalid Admin PIN';
        }
    } catch (e) {
        errorMsg.textContent = 'Connection error';
    }
});

// Logout logic
logoutBtn.addEventListener('click', () => {
    auth.signOut().then(() => {
        location.reload();
    });
});

queueSmsBtn.addEventListener('click', async () => {
    const phone = prompt('Enter phone number (e.g. 0771234567):');
    if (!phone) return;
    const message = prompt('Enter test message:');
    if (!message) return;

    try {
        const response = await fetch(`${API_BASE}sms/queue`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone_number: phone, message: message })
        });

        if (response.ok) {
            alert('SMS queued successfully!');
            // Realtime listener will automatically update the table
        }
    } catch(e) {
        alert("Failed to queue SMS");
    }
});

function showDashboard() {
    loginContainer.classList.add('hidden');
    dashboardContainer.classList.remove('hidden');
    
    // Set up realtime listeners instead of static loads
    setupRealtimeListeners();
}

let unsubUsers, unsubJobs, unsubApps, unsubSMS;

function setupRealtimeListeners() {
    // Users
    unsubUsers = db.collection('users').onSnapshot(snapshot => {
        document.getElementById('stat-users').textContent = snapshot.size;
        const users = [];
        snapshot.forEach(doc => users.push({nic: doc.id, ...doc.data()}));
        renderUsers(users);
    });

    // Jobs
    unsubJobs = db.collection('jobs').onSnapshot(snapshot => {
        document.getElementById('stat-jobs').textContent = snapshot.size;
        const jobs = [];
        snapshot.forEach(doc => jobs.push({id: doc.id, ...doc.data()}));
        renderJobs(jobs);
    });

    // Applications
    unsubApps = db.collection('applications').onSnapshot(snapshot => {
        document.getElementById('stat-apps').textContent = snapshot.size;
        const apps = [];
        snapshot.forEach(doc => apps.push({id: doc.id, ...doc.data()}));
        renderApplications(apps);
    });

    // SMS
    unsubSMS = db.collection('sms_messages').orderBy('created_at', 'desc').onSnapshot(snapshot => {
        document.getElementById('stat-sms').textContent = snapshot.size;
        const messages = [];
        snapshot.forEach(doc => messages.push({id: doc.id, ...doc.data()}));
        renderSMS(messages);
    });
}

function renderUsers(users) {
    const body = document.getElementById('users-table-body');
    body.innerHTML = users.map(user => `
        <tr>
            <td>
                <div class="user-cell">
                    <img src="${user.profile_photo_url ? user.profile_photo_url : 'https://ui-avatars.com/api/?name=' + encodeURIComponent((user.first_name||'') + '+' + (user.last_name||''))}" class="profile-thumb" alt="Avatar">
                    <div>
                        <strong>${user.first_name || ''} ${user.last_name || ''}</strong><br>
                        <small style="color:var(--text-light)">${user.nic}</small>
                    </div>
                </div>
            </td>
            <td>${user.phone || ''}</td>
            <td>${user.district || '—'}, ${user.ds_area || '—'}</td>
            <td>
                <strong>⭐ ${user.rating || 0}</strong><br>
                <small style="color:var(--text-light)">${user.abandoned_jobs_count || 0} abandoned</small>
            </td>
            <td>
                <span class="badge ${user.availability_status || 'available'}">${user.availability_status || 'available'}</span>
                ${user.is_blocked ? '<span class="badge cancelled" style="margin-left:4px">Blocked</span>' : ''}
            </td>
            <td>
                <span class="badge incoming" title="Completed">${user.completed_jobs_count || 0} ✓</span>
                <span class="badge abandoned" title="Abandoned">${user.abandoned_jobs_count || 0} ✗</span>
                <span class="badge outgoing" title="Posted">${user.posted_jobs_count || 0} 📋</span>
            </td>
            <td>
                <button class="btn-sm ${user.is_blocked ? 'success' : 'danger'}" onclick="toggleBlockUser('${user.nic}', ${user.is_blocked})">
                    ${user.is_blocked ? 'Unblock' : 'Block'}
                </button>
            </td>
        </tr>
    `).join('');
}

function renderJobs(jobs) {
    const body = document.getElementById('jobs-table-body');
    body.innerHTML = jobs.map(job => `
        <tr>
            <td><strong>${job.title || 'Untitled'}</strong></td>
            <td>${job.employer_id || ''}</td>
            <td>${job.area || ''}</td>
            <td><span class="badge ${job.status || 'open'}">${job.status || 'open'}</span></td>
            <td>${(job.applied_worker_ids || []).length} apps</td>
            <td>${job.created_at ? new Date(job.created_at).toLocaleDateString() : ''}</td>
            <td>
                <button class="btn-sm danger" onclick="deleteJob('${job.id}')">Delete</button>
            </td>
        </tr>
    `).join('');
}

function renderApplications(apps) {
    const body = document.getElementById('apps-table-body');
    body.innerHTML = apps.map(app => `
        <tr>
            <td>#${app.id.substring(0,8)}...</td>
            <td><strong>Job ID: ${app.job_id}</strong></td>
            <td>${app.worker_id}</td>
            <td>${app.applied_at ? new Date(app.applied_at).toLocaleString() : ''}</td>
        </tr>
    `).join('');
}

function renderSMS(messages) {
    const body = document.getElementById('sms-table-body');
    body.innerHTML = messages.map(msg => `
        <tr>
            <td>#${(msg.id||'').substring(0,8)}...</td>
            <td>${msg.phone_number}</td>
            <td>${msg.message}</td>
            <td><span class="badge ${msg.direction}">${msg.direction}</span></td>
            <td><span class="badge ${msg.status}">${msg.status}</span></td>
            <td>${msg.created_at ? new Date(msg.created_at).toLocaleString() : ''}</td>
        </tr>
    `).join('');
}

// Admin Actions
async function toggleBlockUser(nic, currentState) {
    if (!confirm('Are you sure you want to change this user\'s status?')) return;
    try {
        await db.collection('users').doc(nic).update({
            is_blocked: currentState ? 0 : 1
        });
    } catch (e) {
        alert("Failed to update user status");
    }
}

async function deleteJob(jobId) {
    if (!confirm('Are you sure you want to delete this job?')) return;
    try {
        await db.collection('jobs').doc(jobId).delete();
    } catch (e) {
        alert("Failed to delete job");
    }
}

// Tab Logic
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        btn.classList.add('active');
        const tab = document.getElementById(btn.dataset.tab);
        if (tab) tab.classList.add('active');
    });
});
