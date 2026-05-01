const API_BASE = '/'; // Served from same origin
let token = localStorage.getItem('admin_token');

// DOM Elements
const loginContainer = document.getElementById('login-container');
const dashboardContainer = document.getElementById('dashboard-container');
const pinInput = document.getElementById('pin-input');
const loginBtn = document.getElementById('login-btn');
const errorMsg = document.getElementById('error-msg');
const logoutBtn = document.getElementById('logout-btn');

// Initialization
if (token) {
    showDashboard();
}

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
            localStorage.setItem('admin_token', token);
            showDashboard();
        } else {
            errorMsg.textContent = 'Invalid Admin PIN';
        }
    } catch (e) {
        errorMsg.textContent = 'Connection error';
    }
});

// Logout logic
logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('admin_token');
    location.reload();
});

function showDashboard() {
    loginContainer.classList.add('hidden');
    dashboardContainer.classList.remove('hidden');
    loadStats();
    loadUsers();
    loadJobs();
    loadApplications();
}

// Data Loading
async function loadStats() {
    const response = await fetchWithAuth(`${API_BASE}admin/stats`);
    if (response) {
        document.getElementById('stat-users').textContent = response.total_users;
        document.getElementById('stat-jobs').textContent = response.total_jobs;
        document.getElementById('stat-active').textContent = response.active_jobs;
        document.getElementById('stat-apps').textContent = response.total_applications;
    }
}

async function loadUsers() {
    const users = await fetchWithAuth(`${API_BASE}admin/users`);
    if (users) {
        const body = document.getElementById('users-table-body');
        body.innerHTML = users.map(user => `
            <tr>
                <td><strong>${user.nic}</strong> ${user.is_blocked ? '<span class="badge cancelled">Blocked</span>' : ''}</td>
                <td>${user.first_name} ${user.last_name}</td>
                <td>${user.phone}</td>
                <td>${user.district}, ${user.ds_area}</td>
                <td>⭐ ${user.rating}</td>
                <td>${user.completed_jobs_count} / ${user.abandoned_jobs_count} / ${user.posted_jobs_count}</td>
                <td>
                    <button class="btn-sm ${user.is_blocked ? 'success' : 'danger'}" onclick="toggleBlockUser('${user.nic}')">
                        ${user.is_blocked ? 'Unblock' : 'Block'}
                    </button>
                </td>
            </tr>
        `).join('');
    }
}

async function loadJobs() {
    const jobs = await fetchWithAuth(`${API_BASE}admin/jobs`);
    if (jobs) {
        const body = document.getElementById('jobs-table-body');
        body.innerHTML = jobs.map(job => `
            <tr>
                <td><strong>${job.title}</strong></td>
                <td>${job.employer_id}</td>
                <td>${job.area}</td>
                <td><span class="badge ${job.status}">${job.status}</span></td>
                <td>${job.applied_worker_ids.length}</td>
                <td>${new Date(job.created_at).toLocaleDateString()}</td>
                <td>
                    <button class="btn-sm danger" onclick="deleteJob('${job.id}')">Delete</button>
                </td>
            </tr>
        `).join('');
    }
}

async function loadApplications() {
    const apps = await fetchWithAuth(`${API_BASE}admin/applications`);
    if (apps) {
        const body = document.getElementById('apps-table-body');
        body.innerHTML = apps.map(app => `
            <tr>
                <td>${app.id}</td>
                <td><strong>${app.job_title}</strong></td>
                <td>${app.worker_id}</td>
                <td>${new Date(app.applied_at).toLocaleString()}</td>
            </tr>
        `).join('');
    }
}

// Admin Actions
async function toggleBlockUser(nic) {
    if (!confirm('Are you sure you want to change this user\'s status?')) return;
    const response = await fetchWithAuth(`${API_BASE}admin/users/${nic}/block`, 'POST');
    if (response) {
        loadUsers();
    }
}

async function deleteJob(jobId) {
    if (!confirm('Are you sure you want to delete this job?')) return;
    const response = await fetchWithAuth(`${API_BASE}admin/jobs/${jobId}`, 'DELETE');
    if (response) {
        loadStats();
        loadJobs();
    }
}

// Helpers
async function fetchWithAuth(url, method = 'GET') {
    try {
        const response = await fetch(url, {
            method: method,
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (response.status === 401) {
            localStorage.removeItem('admin_token');
            location.reload();
            return null;
        }
        return await response.json();
    } catch (e) {
        console.error('Fetch error:', e);
        return null;
    }
}

// Tab Logic
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
    });
});
