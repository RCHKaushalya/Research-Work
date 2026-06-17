// Workforce Platform Admin Portal JS (Supabase-backed)
let token = localStorage.getItem('admin_token');

const supabaseUrl = 'https://pkzdexdkgjjejctsgnbz.supabase.co';
const supabaseKey = 'sb_publishable_m6X8NGNqr0JFKSH5VcV1rw_rtiCKaXt';
const supabaseClient = supabase.createClient(supabaseUrl, supabaseKey);

const appConfig = window.APP_CONFIG || {};
const smsGatewayUrl = appConfig.SMS_GATEWAY_URL || 'https://app.sms-gateway.app/services/send.php';
const smsGatewayKey = appConfig.SMS_GATEWAY_API_KEY || '';
const smsGatewayDevices = appConfig.SMS_GATEWAY_DEVICES || '10959|1';

// DOM Elements
const loginContainer = document.getElementById('login-container');
const dashboardContainer = document.getElementById('dashboard-container');
const pinInput = document.getElementById('pin-input');
const loginBtn = document.getElementById('login-btn');
const errorMsg = document.getElementById('error-msg');
const logoutBtn = document.getElementById('logout-btn');
const queueSmsBtn = document.getElementById('queue-sms-btn');
const broadcastBtn = document.getElementById('broadcast-btn');
const broadcastMsgInput = document.getElementById('broadcast-msg');

// Initialization
const localAuth = localStorage.getItem('admin_authenticated');
if (localAuth === 'true') {
    setTimeout(showDashboard, 100);
} else {
    loginContainer.classList.remove('hidden');
    dashboardContainer.classList.add('hidden');
}

// Login logic
loginBtn.addEventListener('click', async () => {
    const pin = pinInput.value.trim();
    
    // Master PIN Bypass
    if (pin === '9421') {
        localStorage.setItem('admin_authenticated', 'true');
        showDashboard();
        errorMsg.textContent = '';
    } else {
        errorMsg.textContent = 'Invalid Admin PIN';
    }
});

// Logout logic
logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('admin_authenticated');
    location.reload();
});

queueSmsBtn.addEventListener('click', async () => {
    const phone = prompt('Enter phone number (e.g. 0771234567):');
    if (!phone) return;
    const message = prompt('Enter test message:');
    if (!message) return;

    try {
        const result = await sendSmsViaGateway(phone, message);

        if (result.success) {
            alert('SMS sent successfully via Gateway!');
            loadAllData();
        } else {
            alert('Failed to send SMS: ' + result.error);
        }
    } catch(e) {
        console.error(e);
        alert("Error connecting to SMS Gateway");
    }
});

broadcastBtn.addEventListener('click', async () => {
    const message = broadcastMsgInput.value.trim();
    if (!message) return;
    if (!confirm(`Send this message to ALL users?`)) return;

    try {
        const { data: users, error } = await supabaseClient.from('users').select('phone');
        if (error) throw error;
        
        const requests = [];
        users.forEach(user => {
            if (user.phone) {
                requests.push(sendSmsViaGateway(user.phone, message));
            }
        });

        const results = await Promise.all(requests);
        const sentCount = results.filter((result) => result.success).length;
        alert('Broadcast sent to ' + sentCount + ' of ' + requests.length + ' users!');
        broadcastMsgInput.value = '';
        loadAllData();
    } catch (e) {
        console.error(e);
        alert('Failed to send broadcast');
    }
});

function normalizePhone(phone) {
    phone = String(phone || '').trim().replace(/[\s().-]+/g, '');
    if (!phone) return phone;
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+94' + phone.substring(1);
    if (phone.startsWith('94')) return '+' + phone;
    return '+' + phone;
}

async function sendSmsViaGateway(phone, message) {
    if (!smsGatewayKey) {
        return { success: false, error: 'SMS_GATEWAY_API_KEY is missing in config.js.' };
    }

    const params = new URLSearchParams({
        key: smsGatewayKey,
        number: normalizePhone(phone),
        message,
        devices: smsGatewayDevices,
        type: 'sms',
        prioritize: '0'
    });
    const url = `${smsGatewayUrl}?${params.toString()}`;

    try {
        const response = await fetch(url);
        const payload = await response.json();
        return {
            success: response.ok && payload.success === true,
            error: payload.error || response.statusText || 'Gateway rejected the message'
        };
    } catch (error) {
        try {
            await fetch(url, { mode: 'no-cors' });
            return { success: true, opaque: true };
        } catch {
            return { success: false, error: error.message || 'Gateway request failed' };
        }
    }
}

let refreshInterval = null;

function showDashboard() {
    loginContainer.classList.add('hidden');
    dashboardContainer.classList.remove('hidden');
    
    loadAllData();
    if (refreshInterval) clearInterval(refreshInterval);
    refreshInterval = setInterval(loadAllData, 5000); // Poll every 5 seconds
}

async function loadAllData() {
    try {
        // Fetch Users
        const { data: users, error: usersErr } = await supabaseClient
            .from('users')
            .select('*')
            .order('created_at', { ascending: false });
        if (usersErr) throw usersErr;
        document.getElementById('stat-users').textContent = users.length;
        renderUsers(users);

        // Fetch Jobs
        const { data: jobs, error: jobsErr } = await supabaseClient
            .from('jobs')
            .select('*')
            .order('created_at', { ascending: false });
        if (jobsErr) throw jobsErr;
        document.getElementById('stat-jobs').textContent = jobs.length;

        const allPayments = [];
        let totalRevenue = 0;

        jobs.forEach(job => {
            if (job.payments && Array.isArray(job.payments)) {
                job.payments.forEach(p => {
                    allPayments.push({...p, job_id: job.id});
                    totalRevenue += (p.amount || 0);
                });
            }
        });

        document.getElementById('stat-revenue').textContent = 'Rs. ' + totalRevenue.toLocaleString();
        document.getElementById('total-revenue-badge').textContent = 'Total: Rs. ' + totalRevenue.toLocaleString();
        
        renderJobs(jobs);
        renderFinancials(allPayments);

        // Fetch Applications
        const { data: apps, error: appsErr } = await supabaseClient
            .from('applications')
            .select('*')
            .order('applied_at', { ascending: false });
        if (appsErr) throw appsErr;
        document.getElementById('stat-apps').textContent = apps.length;
        renderApplications(apps);

        // Fetch SMS
        const { data: sms, error: smsErr } = await supabaseClient
            .from('sms_messages')
            .select('*')
            .order('created_at', { ascending: false });
        if (smsErr) throw smsErr;
        document.getElementById('stat-sms').textContent = sms.length;
        renderSMS(sms);

    } catch (e) {
        console.error("Error loading dashboard data:", e);
    }
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
                <div class="header-btns">
                    <button class="btn-sm outline" onclick="openUserModal('${user.nic}')">Edit</button>
                    <button class="btn-sm ${user.verified ? 'success' : 'outline'}" onclick="toggleVerifyUser('${user.nic}', ${user.verified})">
                        ${user.verified ? '✅ Verified' : 'Verify'}
                    </button>
                </div>
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
            <td>${job.employer_nic || ''}</td>
            <td>${job.location || ''}</td>
            <td><span class="badge ${job.status || 'open'}">${job.status || 'open'}</span></td>
            <td>${(job.applied_worker_ids || []).length} apps</td>
            <td>${job.created_at ? new Date(job.created_at).toLocaleDateString() : ''}</td>
            <td>
                <div class="header-btns">
                    <button class="btn-sm outline" onclick="openJobModal('${job.id}')">Edit</button>
                    <button class="btn-sm danger" onclick="deleteJob('${job.id}')">Delete</button>
                </div>
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
            <td>${app.worker_nic}</td>
            <td>${app.applied_at ? new Date(app.applied_at).toLocaleString() : ''}</td>
        </tr>
    `).join('');
}

function renderFinancials(payments) {
    payments.sort((a, b) => new Date(b.date) - new Date(a.date));

    const body = document.getElementById('financial-table-body');
    body.innerHTML = payments.map(p => `
        <tr>
            <td><small>${p.job_id}</small></td>
            <td><strong>${p.workerId || p.worker_id || ''}</strong></td>
            <td class="success">Rs. ${(p.amount || 0).toLocaleString()}</td>
            <td>${p.note || '—'}</td>
            <td>${p.date ? new Date(p.date).toLocaleString() : '—'}</td>
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
async function toggleVerifyUser(nic, currentState) {
    try {
        const { error } = await supabaseClient
            .from('users')
            .update({ verified: !currentState })
            .eq('nic', nic);
        if (error) throw error;
        loadAllData();
    } catch (e) {
        alert("Failed to update verification status: " + e.message);
    }
}

async function toggleBlockUser(nic, currentState) {
    if (!confirm('Are you sure you want to change this user\'s status?')) return;
    try {
        const { error } = await supabaseClient
            .from('users')
            .update({ is_blocked: currentState ? 0 : 1 })
            .eq('nic', nic);
        if (error) throw error;
        loadAllData();
    } catch (e) {
        alert("Failed to update user status: " + e.message);
    }
}

async function deleteJob(jobId) {
    if (!confirm('Are you sure you want to delete this job?')) return;
    try {
        const { error } = await supabaseClient
            .from('jobs')
            .delete()
            .eq('id', jobId);
        if (error) throw error;
        loadAllData();
    } catch (e) {
        alert("Failed to delete job: " + e.message);
    }
}

// CRUD Modals
const userModal = document.getElementById('user-modal');
const jobModal = document.getElementById('job-modal');
const userForm = document.getElementById('user-form');
const jobForm = document.getElementById('job-form');

let editingUserId = null;
let editingJobId = null;

function closeModals() {
    userModal.classList.add('hidden');
    jobModal.classList.add('hidden');
    editingUserId = null;
    editingJobId = null;
    userForm.reset();
    jobForm.reset();
}

async function openUserModal(nic = null) {
    editingUserId = nic;
    document.getElementById('user-modal-title').textContent = nic ? 'Edit User' : 'Add New User';
    document.getElementById('u-nic').disabled = !!nic;

    if (nic) {
        const { data, error } = await supabaseClient
            .from('users')
            .select('*')
            .eq('nic', nic)
            .limit(1);
        if (error) {
            alert("Error loading user: " + error.message);
            return;
        }
        if (data && data.length > 0) {
            const u = data[0];
            document.getElementById('u-nic').value = nic;
            document.getElementById('u-first').value = u.first_name || '';
            document.getElementById('u-last').value = u.last_name || '';
            document.getElementById('u-phone').value = u.phone || '';
            document.getElementById('u-district').value = u.district || '';
            document.getElementById('u-ds').value = u.ds_area || '';
        }
    }
    userModal.classList.remove('hidden');
}

userForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const nic = document.getElementById('u-nic').value.trim();
    const userData = {
        first_name: document.getElementById('u-first').value.trim(),
        last_name: document.getElementById('u-last').value.trim(),
        phone: document.getElementById('u-phone').value.trim(),
        district: document.getElementById('u-district').value.trim(),
        ds_area: document.getElementById('u-ds').value.trim(),
    };

    try {
        if (editingUserId) {
            const { error } = await supabaseClient
                .from('users')
                .update(userData)
                .eq('nic', editingUserId);
            if (error) throw error;
        } else {
            const { error } = await supabaseClient
                .from('users')
                .insert({
                    ...userData,
                    nic: nic,
                    completed_jobs_count: 0,
                    applied_jobs_count: 0,
                    abandoned_jobs_count: 0,
                    posted_jobs_count: 0,
                    rating: 5.0,
                    verified: false,
                    is_blocked: 0,
                    language: 'en'
                });
            if (error) throw error;
        }
        closeModals();
        loadAllData();
    } catch (e) {
        alert("Error saving user: " + e.message);
    }
});

async function openJobModal(jobId = null) {
    editingJobId = jobId;
    document.getElementById('job-modal-title').textContent = jobId ? 'Edit Job' : 'Add New Job';

    if (jobId) {
        const { data, error } = await supabaseClient
            .from('jobs')
            .select('*')
            .eq('id', jobId)
            .limit(1);
        if (error) {
            alert("Error loading job: " + error.message);
            return;
        }
        if (data && data.length > 0) {
            const j = data[0];
            document.getElementById('j-title').value = j.title || '';
            document.getElementById('j-desc').value = j.description || '';
            document.getElementById('j-employer').value = j.employer_nic || '';
            document.getElementById('j-area').value = j.location || '';
            document.getElementById('j-status').value = j.status || 'open';
        }
    }
    jobModal.classList.remove('hidden');
}

jobForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const jobData = {
        title: document.getElementById('j-title').value.trim(),
        description: document.getElementById('j-desc').value.trim(),
        employer_nic: document.getElementById('j-employer').value.trim(),
        location: document.getElementById('j-area').value.trim(),
        status: document.getElementById('j-status').value,
    };

    try {
        if (editingJobId) {
            const { error } = await supabaseClient
                .from('jobs')
                .update(jobData)
                .eq('id', editingJobId);
            if (error) throw error;
        } else {
            const { error } = await supabaseClient
                .from('jobs')
                .insert({
                    ...jobData,
                    applied_worker_ids: [],
                    accepted_worker_ids: [],
                    required_skills: [],
                    payments: []
                });
            if (error) throw error;
        }
        closeModals();
        loadAllData();
    } catch (e) {
        alert("Error saving job: " + e.message);
    }
});

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
