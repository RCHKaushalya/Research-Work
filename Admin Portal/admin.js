// Workforce Platform Admin Portal JS (Supabase-backed)
const supabaseUrl = 'https://pkzdexdkgjjejctsgnbz.supabase.co';
const supabaseKey = 'sb_publishable_m6X8NGNqr0JFKSH5VcV1rw_rtiCKaXt';
const supabaseClient = supabase.createClient(supabaseUrl, supabaseKey);

const appConfig = window.APP_CONFIG || {};
const smsGatewayUrl = appConfig.SMS_GATEWAY_URL || 'https://app.sms-gateway.app/services/send.php';
const smsGatewayKey = appConfig.SMS_GATEWAY_API_KEY || '';
const smsGatewayDevices = appConfig.SMS_GATEWAY_DEVICES || '10959|1';
const locationData = window.LOCATION_DATA || { districts: [], dsAreas: {} };

const districtEnglishNames = {
    colombo: '01',
    gampaha: '02',
    kalutara: '03',
    kandy: '04',
    matale: '05',
    'nuwara eliya': '06',
    galle: '07',
    matara: '08',
    hambantota: '09',
    jaffna: '10',
    kilinochchi: '11',
    mannar: '12',
    vavuniya: '13',
    mullaitivu: '14',
    batticaloa: '15',
    ampara: '16',
    trincomalee: '17',
    kurunegala: '18',
    puttalam: '19',
    anuradhapura: '20',
    polonnaruwa: '21',
    badulla: '22',
    monaragala: '23',
    ratnapura: '24',
    kegalle: '25'
};

const state = {
    users: [],
    jobs: [],
    applications: [],
    sms: [],
    volunteers: [],
    pendingUsers: [],
    pendingJobs: []
};

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

const userModal = document.getElementById('user-modal');
const jobModal = document.getElementById('job-modal');
const volunteerModal = document.getElementById('volunteer-modal');
const approvalModal = document.getElementById('approval-modal');
const userForm = document.getElementById('user-form');
const jobForm = document.getElementById('job-form');
const volunteerForm = document.getElementById('volunteer-form');
const approvalForm = document.getElementById('approval-form');

let refreshInterval = null;
let editingUserId = null;
let editingJobId = null;
let editingVolunteerId = null;
let approvalContext = null;

setupLocationSelects('u-district', 'u-ds');
setupLocationSelects('j-district', 'j-area');
populateDistrictSelect(document.getElementById('v-district'), '');

// Initialization
if (localStorage.getItem('admin_authenticated') === 'true') {
    setTimeout(showDashboard, 100);
} else {
    loginContainer.classList.remove('hidden');
    dashboardContainer.classList.add('hidden');
}

loginBtn.addEventListener('click', () => {
    const pin = pinInput.value.trim();

    if (pin === '9421') {
        localStorage.setItem('admin_authenticated', 'true');
        showDashboard();
        errorMsg.textContent = '';
    } else {
        errorMsg.textContent = 'Invalid Admin PIN';
    }
});

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
    } catch (e) {
        alert('Error connecting to SMS Gateway');
    }
});

broadcastBtn.addEventListener('click', async () => {
    const message = broadcastMsgInput.value.trim();
    if (!message) return;
    if (!confirm('Send this message to ALL users?')) return;

    try {
        const requests = state.users
            .filter((user) => user.phone)
            .map((user) => sendSmsViaGateway(user.phone, message));

        const results = await Promise.all(requests);
        const sentCount = results.filter((result) => result.success).length;
        alert('Broadcast sent to ' + sentCount + ' of ' + requests.length + ' users!');
        broadcastMsgInput.value = '';
        loadAllData();
    } catch {
        alert('Failed to send broadcast');
    }
});

userForm.addEventListener('submit', saveUser);
jobForm.addEventListener('submit', saveJob);
volunteerForm.addEventListener('submit', saveVolunteer);
approvalForm.addEventListener('submit', submitApprovalForm);

document.querySelectorAll('.tab-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach((b) => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach((c) => c.classList.remove('active'));

        btn.classList.add('active');
        const tab = document.getElementById(btn.dataset.tab);
        if (tab) tab.classList.add('active');
    });
});

function showDashboard() {
    loginContainer.classList.add('hidden');
    dashboardContainer.classList.remove('hidden');

    loadAllData();
    if (refreshInterval) clearInterval(refreshInterval);
    refreshInterval = setInterval(loadAllData, 10000);
}

async function loadAllData() {
    state.users = await selectTable('users', { orderBy: 'created_at' });
    state.jobs = await selectTable('jobs', { orderBy: 'created_at' });
    state.applications = await selectTable('applications', { orderBy: 'applied_at' });
    state.sms = await selectTable('sms_messages', { orderBy: 'created_at' });
    state.volunteers = await selectTable('volunteers', { orderBy: 'volunteer_id', ascending: true });
    state.pendingUsers = await selectTable('pending_user_registrations', {
        eq: ['status', 'pending'],
        orderBy: 'created_at'
    });
    state.pendingJobs = await selectTable('pending_job_posts', {
        eq: ['status', 'pending'],
        orderBy: 'created_at'
    });

    updateStats();
    renderUsers(state.users);
    renderJobs(state.jobs);
    renderApplications(state.applications);
    renderFinancials(paymentsFromJobs(state.jobs));
    renderSMS(state.sms);
    renderVolunteers(state.volunteers);
    renderPendingUsers(state.pendingUsers);
    renderPendingJobs(state.pendingJobs);
}

async function selectTable(table, options = {}) {
    let query = supabaseClient.from(table).select(options.select || '*');

    if (options.eq) {
        query = query.eq(options.eq[0], options.eq[1]);
    }

    if (options.orderBy) {
        query = query.order(options.orderBy, { ascending: options.ascending ?? false });
    }

    const { data, error } = await query;
    if (error) {
        console.warn(`Unable to load ${table}:`, error.message);
        return [];
    }

    return data || [];
}

function updateStats() {
    const totalRevenue = paymentsFromJobs(state.jobs)
        .reduce((total, payment) => total + Number(payment.amount || 0), 0);
    const pendingCount = state.pendingUsers.length + state.pendingJobs.length;

    document.getElementById('stat-users').textContent = state.users.length;
    document.getElementById('stat-jobs').textContent = state.jobs.length;
    document.getElementById('stat-apps').textContent = state.applications.length;
    document.getElementById('stat-sms').textContent = state.sms.length;
    document.getElementById('stat-volunteers').textContent = state.volunteers.length;
    document.getElementById('stat-pending').textContent = pendingCount;
    document.getElementById('stat-revenue').textContent = 'Rs. ' + totalRevenue.toLocaleString();
    document.getElementById('total-revenue-badge').textContent = 'Total: Rs. ' + totalRevenue.toLocaleString();
    document.getElementById('pending-users-badge').textContent = state.pendingUsers.length + ' pending';
    document.getElementById('pending-jobs-badge').textContent = state.pendingJobs.length + ' pending';
}

function paymentsFromJobs(jobs) {
    const payments = [];

    jobs.forEach((job) => {
        if (Array.isArray(job.payments)) {
            job.payments.forEach((payment) => payments.push({ ...payment, job_id: job.id }));
        }
    });

    return payments;
}

function renderUsers(users) {
    const body = document.getElementById('users-table-body');
    body.innerHTML = users.map((user) => `
        <tr>
            <td>
                <div class="user-cell">
                    <img src="${avatarUrl(user)}" class="profile-thumb" alt="Avatar">
                    <div>
                        <strong>${escapeHtml(user.first_name || '')} ${escapeHtml(user.last_name || '')}</strong><br>
                        <small style="color:var(--text-light)">${escapeHtml(user.nic)}</small>
                    </div>
                </div>
            </td>
            <td>${escapeHtml(user.phone || '')}</td>
            <td>${escapeHtml(readableDistrict(user.district) || '—')}<br><small>${escapeHtml(readableDsArea(user.ds_area, user.district) || '—')}</small></td>
            <td>
                <strong>${Number(user.rating || 0).toFixed(1)}</strong><br>
                <small style="color:var(--text-light)">${user.abandoned_jobs_count || 0} abandoned</small>
            </td>
            <td>
                <div class="header-btns">
                    <button class="btn-sm outline" onclick="openUserModal('${escapeAttr(user.nic)}')">Edit</button>
                    <button class="btn-sm ${user.verified ? 'success' : 'outline'}" onclick="toggleVerifyUser('${escapeAttr(user.nic)}', ${Boolean(user.verified)})">
                        ${user.verified ? 'Verified' : 'Verify'}
                    </button>
                </div>
            </td>
            <td>
                <span class="badge incoming" title="Completed">${user.completed_jobs_count || 0}</span>
                <span class="badge abandoned" title="Abandoned">${user.abandoned_jobs_count || 0}</span>
                <span class="badge outgoing" title="Posted">${user.posted_jobs_count || 0}</span>
            </td>
            <td>
                <button class="btn-sm ${Number(user.is_blocked || 0) ? 'success' : 'danger'}" onclick="toggleBlockUser('${escapeAttr(user.nic)}', ${Number(user.is_blocked || 0)})">
                    ${Number(user.is_blocked || 0) ? 'Unblock' : 'Block'}
                </button>
            </td>
        </tr>
    `).join('');
}

function renderJobs(jobs) {
    const body = document.getElementById('jobs-table-body');
    body.innerHTML = jobs.map((job) => `
        <tr>
            <td><strong>${escapeHtml(job.title || 'Untitled')}</strong></td>
            <td>${escapeHtml(job.employer_nic || '')}</td>
            <td>${escapeHtml(readableLocation(job.location) || job.location || '')}</td>
            <td><span class="badge ${escapeAttr(job.status || 'open')}">${escapeHtml(job.status || 'open')}</span></td>
            <td>${(job.applied_worker_ids || []).length} apps</td>
            <td>${job.created_at ? new Date(job.created_at).toLocaleDateString() : ''}</td>
            <td>
                <div class="header-btns">
                    <button class="btn-sm outline" onclick="openJobModal('${escapeAttr(job.id)}')">Edit</button>
                    <button class="btn-sm danger" onclick="deleteJob('${escapeAttr(job.id)}')">Delete</button>
                </div>
            </td>
        </tr>
    `).join('');
}

function renderVolunteers(volunteers) {
    const body = document.getElementById('volunteers-table-body');
    body.innerHTML = volunteers.map((volunteer) => `
        <tr>
            <td><strong>${escapeHtml(volunteer.full_name || '')}</strong></td>
            <td>${escapeHtml(volunteer.volunteer_id || '')}</td>
            <td>${escapeHtml(readableDistrict(volunteer.district) || volunteer.district || 'All areas')}</td>
            <td>${escapeHtml(volunteer.language || 'si')}</td>
            <td><span class="badge ${volunteer.active ? 'available' : 'cancelled'}">${volunteer.active ? 'Active' : 'Inactive'}</span></td>
            <td>
                <div class="header-btns">
                    <button class="btn-sm outline" onclick="openVolunteerModal('${escapeAttr(volunteer.volunteer_id)}')">Edit</button>
                    <button class="btn-sm ${volunteer.active ? 'danger' : 'success'}" onclick="toggleVolunteer('${escapeAttr(volunteer.volunteer_id)}', ${Boolean(volunteer.active)})">
                        ${volunteer.active ? 'Disable' : 'Enable'}
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
}

function renderPendingUsers(users) {
    const body = document.getElementById('pending-users-table-body');
    body.innerHTML = users.length ? users.map((user) => `
        <tr>
            <td><strong>${escapeHtml(`${user.first_name || ''} ${user.last_name || ''}`.trim() || 'Unnamed')}</strong></td>
            <td>${escapeHtml(user.phone || '')}</td>
            <td>${escapeHtml(readableDistrict(user.district) || user.district || 'Needs key')}<br><small>${escapeHtml(readableDsArea(user.ds_area, user.district) || user.ds_area || 'Needs key')}</small></td>
            <td>${escapeHtml(user.language || 'si')}</td>
            <td>
                <div class="header-btns">
                    <button class="btn-sm success" onclick="openPendingUserApproval('${escapeAttr(user.id)}')">Approve Form</button>
                    <button class="btn-sm danger" onclick="rejectPending('pending_user_registrations', '${escapeAttr(user.id)}')">Reject</button>
                </div>
            </td>
        </tr>
    `).join('') : `<tr><td colspan="5">No pending user registrations.</td></tr>`;
}

function renderPendingJobs(jobs) {
    const body = document.getElementById('pending-jobs-table-body');
    body.innerHTML = jobs.length ? jobs.map((job) => `
        <tr>
            <td><strong>${escapeHtml(job.job_title || job.title || 'Untitled')}</strong></td>
            <td>${escapeHtml(job.employer_nic || job.employer_phone || '')}</td>
            <td>${escapeHtml(readableDistrict(job.district) || job.district || 'Needs key')}<br><small>${escapeHtml(readableDsArea(job.ds_area, job.district) || job.ds_area || 'Needs key')}</small></td>
            <td>${escapeHtml(job.category || '')}</td>
            <td>
                <div class="header-btns">
                    <button class="btn-sm success" onclick="openPendingJobApproval('${escapeAttr(job.id)}')">Approve Form</button>
                    <button class="btn-sm danger" onclick="rejectPending('pending_job_posts', '${escapeAttr(job.id)}')">Reject</button>
                </div>
            </td>
        </tr>
    `).join('') : `<tr><td colspan="5">No pending job posts.</td></tr>`;
}

function renderApplications(apps) {
    const body = document.getElementById('apps-table-body');
    body.innerHTML = apps.map((app) => `
        <tr>
            <td>#${escapeHtml(String(app.id || '').substring(0, 8))}...</td>
            <td><strong>Job ID: ${escapeHtml(app.job_id)}</strong></td>
            <td>${escapeHtml(app.worker_nic)}</td>
            <td>${app.applied_at ? new Date(app.applied_at).toLocaleString() : ''}</td>
        </tr>
    `).join('');
}

function renderFinancials(payments) {
    payments.sort((a, b) => new Date(b.date || 0) - new Date(a.date || 0));

    const body = document.getElementById('financial-table-body');
    body.innerHTML = payments.map((payment) => `
        <tr>
            <td><small>${escapeHtml(payment.job_id)}</small></td>
            <td><strong>${escapeHtml(payment.workerId || payment.worker_id || '')}</strong></td>
            <td class="success">Rs. ${Number(payment.amount || 0).toLocaleString()}</td>
            <td>${escapeHtml(payment.note || '—')}</td>
            <td>${payment.date ? new Date(payment.date).toLocaleString() : '—'}</td>
        </tr>
    `).join('');
}

function renderSMS(messages) {
    const body = document.getElementById('sms-table-body');
    body.innerHTML = messages.map((msg) => `
        <tr>
            <td>#${escapeHtml(String(msg.id || '').substring(0, 8))}...</td>
            <td>${escapeHtml(msg.phone_number)}</td>
            <td>${escapeHtml(msg.message)}</td>
            <td><span class="badge ${escapeAttr(msg.direction)}">${escapeHtml(msg.direction)}</span></td>
            <td><span class="badge ${escapeAttr(msg.status)}">${escapeHtml(msg.status)}</span></td>
            <td>${msg.created_at ? new Date(msg.created_at).toLocaleString() : ''}</td>
        </tr>
    `).join('');
}

async function toggleVerifyUser(nic, currentState) {
    try {
        const { error } = await supabaseClient
            .from('users')
            .update({ verified: !currentState })
            .eq('nic', nic);
        if (error) throw error;
        loadAllData();
    } catch (e) {
        alert('Failed to update verification status: ' + e.message);
    }
}

async function toggleBlockUser(nic, currentState) {
    if (!confirm('Change this user status?')) return;
    try {
        const { error } = await supabaseClient
            .from('users')
            .update({ is_blocked: currentState ? 0 : 1 })
            .eq('nic', nic);
        if (error) throw error;
        loadAllData();
    } catch (e) {
        alert('Failed to update user status: ' + e.message);
    }
}

async function toggleVolunteer(volunteerId, currentState) {
    try {
        const { error } = await supabaseClient
            .from('volunteers')
            .update({ active: !currentState })
            .eq('volunteer_id', volunteerId);
        if (error) throw error;
        loadAllData();
    } catch (e) {
        alert('Failed to update volunteer: ' + e.message);
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
        alert('Failed to delete job: ' + e.message);
    }
}

async function openUserModal(nic = null) {
    closeModals();
    editingUserId = nic;
    document.getElementById('user-modal-title').textContent = nic ? 'Edit User' : 'Add New User';
    document.getElementById('u-nic').disabled = Boolean(nic);
    setupLocationSelects('u-district', 'u-ds');

    if (nic) {
        const user = await getSingle('users', 'nic', nic);
        if (!user) {
            alert('User not found.');
            return;
        }

        document.getElementById('u-nic').value = nic;
        document.getElementById('u-first').value = user.first_name || '';
        document.getElementById('u-last').value = user.last_name || '';
        document.getElementById('u-phone').value = user.phone || '';
        document.getElementById('u-language').value = user.language || 'si';
        document.getElementById('u-pin').value = user.password_hash || '';
        setupLocationSelects('u-district', 'u-ds', user.district, user.ds_area);
    }

    userModal.classList.remove('hidden');
}

async function saveUser(event) {
    event.preventDefault();
    const nic = value('u-nic').toUpperCase();
    const userData = {
        first_name: value('u-first'),
        last_name: value('u-last'),
        phone: normalizePhone(value('u-phone')),
        district: value('u-district'),
        ds_area: value('u-ds'),
        language: value('u-language') || 'si'
    };

    if (value('u-pin')) {
        userData.password_hash = value('u-pin');
    }

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
                    nic,
                    completed_jobs_count: 0,
                    applied_jobs_count: 0,
                    abandoned_jobs_count: 0,
                    posted_jobs_count: 0,
                    rating: 0,
                    verified: false,
                    is_blocked: 0,
                    availability_status: 'available',
                    job_category_ids: [],
                    skill_ids: []
                });
            if (error) throw error;
        }
        closeModals();
        loadAllData();
    } catch (e) {
        alert('Error saving user: ' + e.message);
    }
}

async function openJobModal(jobId = null) {
    closeModals();
    editingJobId = jobId;
    document.getElementById('job-modal-title').textContent = jobId ? 'Edit Job' : 'Add New Job';
    setupLocationSelects('j-district', 'j-area');

    if (jobId) {
        const job = await getSingle('jobs', 'id', jobId);
        if (!job) {
            alert('Job not found.');
            return;
        }

        document.getElementById('j-title').value = job.title || '';
        document.getElementById('j-desc').value = job.description || '';
        document.getElementById('j-employer').value = job.employer_nic || '';
        document.getElementById('j-status').value = job.status || 'open';
        setupLocationSelects('j-district', 'j-area', districtForDs(job.location) || job.location, job.location);
    }

    jobModal.classList.remove('hidden');
}

async function saveJob(event) {
    event.preventDefault();
    const jobData = {
        title: value('j-title'),
        description: value('j-desc'),
        employer_nic: value('j-employer').toUpperCase(),
        location: value('j-area') || value('j-district'),
        status: value('j-status') || 'open'
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
        alert('Error saving job: ' + e.message);
    }
}

async function openVolunteerModal(volunteerId = null) {
    closeModals();
    editingVolunteerId = volunteerId;
    document.getElementById('volunteer-modal-title').textContent = volunteerId ? 'Edit Volunteer' : 'Add New Volunteer';
    document.getElementById('v-id').disabled = Boolean(volunteerId);
    populateDistrictSelect(document.getElementById('v-district'), '');

    if (volunteerId) {
        const volunteer = await getSingle('volunteers', 'volunteer_id', volunteerId);
        if (!volunteer) {
            alert('Volunteer not found.');
            return;
        }

        document.getElementById('v-id').value = volunteer.volunteer_id || '';
        document.getElementById('v-name').value = volunteer.full_name || '';
        document.getElementById('v-password').value = volunteer.password || '';
        document.getElementById('v-language').value = volunteer.language || 'si';
        document.getElementById('v-active').value = String(Boolean(volunteer.active));
        populateDistrictSelect(document.getElementById('v-district'), coerceDistrictKey(volunteer.district));
    }

    volunteerModal.classList.remove('hidden');
}

async function saveVolunteer(event) {
    event.preventDefault();
    const volunteerData = {
        volunteer_id: value('v-id'),
        full_name: value('v-name'),
        password: value('v-password'),
        district: value('v-district'),
        language: value('v-language') || 'si',
        active: value('v-active') === 'true'
    };

    try {
        if (editingVolunteerId) {
            const { error } = await supabaseClient
                .from('volunteers')
                .update(volunteerData)
                .eq('volunteer_id', editingVolunteerId);
            if (error) throw error;
        } else {
            const { error } = await supabaseClient
                .from('volunteers')
                .insert(volunteerData);
            if (error) throw error;
        }
        closeModals();
        loadAllData();
    } catch (e) {
        alert('Error saving volunteer: ' + e.message);
    }
}

async function openPendingUserApproval(id) {
    const pending = state.pendingUsers.find((user) => String(user.id) === String(id)) ||
        await getSingle('pending_user_registrations', 'id', id);
    if (!pending) {
        alert('Pending user not found.');
        return;
    }

    closeModals();
    approvalContext = { type: 'user', id };
    document.getElementById('approval-modal-title').textContent = 'Approve User Registration';
    document.getElementById('approval-modal-summary').textContent = 'Correct the district and DS keys before approving this user.';
    document.getElementById('approval-fields').innerHTML = `
        ${field('a-nic', 'NIC (unique user key)', pending.nic || pending.user_nic || '', true)}
        ${field('a-pin', 'SMS PIN / password', pending.pin || '', true)}
        ${field('a-phone', 'Phone', normalizePhone(pending.phone), true)}
        ${field('a-first', 'First name', pending.first_name || '', true)}
        ${field('a-last', 'Last name', pending.last_name || '', true)}
        ${selectField('a-language', 'Language', [['si', 'Sinhala'], ['ta', 'Tamil'], ['en', 'English']], pending.language || 'si')}
        ${selectShell('a-district', 'District key', 'Original: ' + (pending.district || 'empty'))}
        ${selectShell('a-ds', 'DS area key', 'Original: ' + (pending.ds_area || 'empty'))}
        ${field('a-categories', 'Job category keys', arrayToCsv(pending.job_category_ids || pending.categories || ''), false)}
        ${field('a-skills', 'Skill keys', arrayToCsv(pending.skill_ids || pending.skills || ''), false)}
    `;
    setupLocationSelects('a-district', 'a-ds', pending.district, pending.ds_area);
    approvalModal.classList.remove('hidden');
}

async function openPendingJobApproval(id) {
    const pending = state.pendingJobs.find((job) => String(job.id) === String(id)) ||
        await getSingle('pending_job_posts', 'id', id);
    if (!pending) {
        alert('Pending job not found.');
        return;
    }

    closeModals();
    approvalContext = { type: 'job', id };
    document.getElementById('approval-modal-title').textContent = 'Approve Job Post';
    document.getElementById('approval-modal-summary').textContent = 'Confirm employer NIC and choose the final location keys.';
    document.getElementById('approval-fields').innerHTML = `
        ${field('a-employer-nic', 'Employer NIC', pending.employer_nic || '', false)}
        ${field('a-employer-phone', 'Employer phone', normalizePhone(pending.employer_phone), false)}
        ${field('a-title', 'Job title', pending.job_title || pending.title || '', true)}
        ${textareaField('a-description', 'Description', pending.job_description || pending.description || '')}
        ${selectShell('a-district', 'District key', 'Original: ' + (pending.district || 'empty'))}
        ${selectShell('a-ds', 'DS area key', 'Original: ' + (pending.ds_area || 'empty'))}
        ${field('a-category', 'Category', pending.category || '', false)}
        ${field('a-skills', 'Required skill keys', arrayToCsv(pending.required_skills || ''), false)}
        ${field('a-payment', 'Payment note', pending.payment || '', false)}
    `;
    setupLocationSelects('a-district', 'a-ds', pending.district, pending.ds_area);
    approvalModal.classList.remove('hidden');
}

async function submitApprovalForm(event) {
    event.preventDefault();
    if (!approvalContext) return;

    try {
        if (approvalContext.type === 'user') {
            await approvePendingUser();
        } else {
            await approvePendingJob();
        }
        closeModals();
        loadAllData();
    } catch (e) {
        alert('Approval failed: ' + e.message);
    }
}

async function approvePendingUser() {
    const nic = value('a-nic').toUpperCase();
    const district = value('a-district');
    const dsArea = value('a-ds');

    if (!nic || !district || !dsArea) {
        throw new Error('NIC, district key, and DS area key are required.');
    }

    const user = {
        nic,
        password_hash: value('a-pin'),
        phone: normalizePhone(value('a-phone')),
        first_name: value('a-first'),
        last_name: value('a-last'),
        district,
        ds_area: dsArea,
        language: value('a-language') || 'si',
        verified: true,
        availability_status: 'available',
        job_category_ids: csvToArray(value('a-categories')),
        skill_ids: csvToArray(value('a-skills'))
    };

    const { error } = await supabaseClient
        .from('users')
        .upsert(user, { onConflict: 'nic' });
    if (error) throw error;

    await updatePending('pending_user_registrations', approvalContext.id, 'approved');
    alert('User approved with location keys.');
}

async function approvePendingJob() {
    let employerNic = value('a-employer-nic').toUpperCase();
    const employerPhone = value('a-employer-phone');
    const district = value('a-district');
    const dsArea = value('a-ds');

    if (!employerNic && employerPhone) {
        const employer = await findUserByPhoneOrNic(employerPhone);
        employerNic = employer ? employer.nic : '';
    }

    if (!employerNic || !district || !dsArea) {
        throw new Error('Employer NIC, district key, and DS area key are required.');
    }

    const payment = value('a-payment');
    const description = [value('a-description'), payment ? `Payment: ${payment}` : '']
        .filter(Boolean)
        .join('\n\n');

    const { error } = await supabaseClient
        .from('jobs')
        .insert({
            title: value('a-title'),
            description,
            employer_nic: employerNic,
            category: value('a-category'),
            location: dsArea || district,
            status: 'open',
            required_skills: csvToArray(value('a-skills')),
            applied_worker_ids: [],
            accepted_worker_ids: [],
            payments: []
        });
    if (error) throw error;

    await incrementUserCounter(employerNic, 'posted_jobs_count');
    await updatePending('pending_job_posts', approvalContext.id, 'approved');
    alert('Job approved with location keys.');
}

async function rejectPending(table, id) {
    if (!confirm('Reject this request?')) return;
    await updatePending(table, id, 'rejected');
    loadAllData();
}

async function updatePending(table, id, status) {
    const { error } = await supabaseClient
        .from(table)
        .update({ status })
        .eq('id', id);
    if (error) throw error;
}

function closeModals() {
    [userModal, jobModal, volunteerModal, approvalModal].forEach((modal) => {
        if (modal) modal.classList.add('hidden');
    });

    [userForm, jobForm, volunteerForm, approvalForm].forEach((form) => {
        if (form) form.reset();
    });

    editingUserId = null;
    editingJobId = null;
    editingVolunteerId = null;
    approvalContext = null;
    document.getElementById('approval-fields').innerHTML = '';
    document.getElementById('u-nic').disabled = false;
    document.getElementById('v-id').disabled = false;
    setupLocationSelects('u-district', 'u-ds');
    setupLocationSelects('j-district', 'j-area');
    populateDistrictSelect(document.getElementById('v-district'), '');
}

async function getSingle(table, column, valueToMatch) {
    const { data, error } = await supabaseClient
        .from(table)
        .select('*')
        .eq(column, valueToMatch)
        .limit(1);
    if (error) throw error;
    return data && data.length ? data[0] : null;
}

async function findUserByPhoneOrNic(input) {
    const raw = String(input || '').trim();
    if (!raw) return null;

    const byNic = await getSingle('users', 'nic', raw.toUpperCase());
    if (byNic) return byNic;

    return getSingle('users', 'phone', normalizePhone(raw));
}

async function incrementUserCounter(nic, key) {
    const user = await getSingle('users', 'nic', nic.toUpperCase());
    if (!user) return;

    const { error } = await supabaseClient
        .from('users')
        .update({ [key]: Number(user[key] || 0) + 1 })
        .eq('nic', nic.toUpperCase());
    if (error) throw error;
}

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

function setupLocationSelects(districtId, dsAreaId, districtValue = '', dsAreaValue = '') {
    const districtSelect = document.getElementById(districtId);
    const dsAreaSelect = document.getElementById(dsAreaId);
    if (!districtSelect || !dsAreaSelect) return;

    const districtKey = coerceDistrictKey(districtValue);
    const dsAreaKey = coerceDsKey(dsAreaValue, districtKey);
    const finalDistrictKey = districtKey || districtForDs(dsAreaKey);

    populateDistrictSelect(districtSelect, finalDistrictKey);
    populateDsAreaSelect(dsAreaSelect, finalDistrictKey, dsAreaKey);

    if (!districtSelect.dataset.locationBound) {
        districtSelect.addEventListener('change', () => {
            populateDsAreaSelect(dsAreaSelect, districtSelect.value, '');
        });
        districtSelect.dataset.locationBound = 'true';
    }
}

function populateDistrictSelect(select, selectedValue) {
    if (!select) return;
    select.innerHTML = `<option value="">Select district key</option>` +
        locationData.districts
            .map((district) => option(district.id, locationOptionLabel(district), district.id === selectedValue))
            .join('');
}

function populateDsAreaSelect(select, districtId, selectedValue) {
    if (!select) return;
    const areas = districtId ? locationData.dsAreas[districtId] || [] : [];
    select.innerHTML = `<option value="">Select DS area key</option>` +
        areas
            .map((area) => option(area.id, locationOptionLabel(area), area.id === selectedValue))
            .join('');
}

function option(valueToUse, label, selected) {
    return `<option value="${escapeAttr(valueToUse)}"${selected ? ' selected' : ''}>${escapeHtml(label)}</option>`;
}

function coerceDistrictKey(valueToCheck) {
    const raw = String(valueToCheck || '').trim();
    if (!raw) return '';

    const direct = locationData.districts.find((district) =>
        [district.id, district.si, district.ta].includes(raw)
    );
    if (direct) return direct.id;

    return districtEnglishNames[normalizeText(raw)] || '';
}

function coerceDsKey(valueToCheck, districtKey = '') {
    const raw = String(valueToCheck || '').trim();
    if (!raw) return '';

    const districtsToSearch = districtKey ? [districtKey] : Object.keys(locationData.dsAreas);

    for (const key of districtsToSearch) {
        const match = (locationData.dsAreas[key] || []).find((area) =>
            [area.id, area.si, area.ta].includes(raw)
        );
        if (match) return match.id;
    }

    return '';
}

function districtForDs(dsAreaKey) {
    if (!dsAreaKey) return '';

    return Object.keys(locationData.dsAreas).find((districtId) =>
        (locationData.dsAreas[districtId] || []).some((area) => area.id === dsAreaKey)
    ) || '';
}

function readableDistrict(valueToCheck) {
    const key = coerceDistrictKey(valueToCheck);
    return districtLabel(key) || valueToCheck || '';
}

function readableDsArea(valueToCheck, districtValue) {
    const districtKey = coerceDistrictKey(districtValue);
    const key = coerceDsKey(valueToCheck, districtKey);
    return dsAreaLabel(key, districtKey) || valueToCheck || '';
}

function readableLocation(locationKey) {
    return dsAreaLabel(locationKey) || districtLabel(coerceDistrictKey(locationKey)) || '';
}

function districtLabel(districtKey) {
    const district = locationData.districts.find((item) => item.id === districtKey);
    return district ? locationOptionLabel(district) : '';
}

function dsAreaLabel(dsAreaKey, districtKey = '') {
    const key = districtKey || districtForDs(dsAreaKey);
    const area = (locationData.dsAreas[key] || []).find((item) => item.id === dsAreaKey);
    return area ? locationOptionLabel(area) : '';
}

function locationOptionLabel(item) {
    return `${item.id} - ${item.si} / ${item.ta}`;
}

function normalizeText(valueToCheck) {
    return String(valueToCheck || '').trim().toLowerCase().replace(/\s+/g, ' ');
}

function field(id, label, fieldValue, required) {
    return `
        <div class="form-group">
            <label for="${id}">${escapeHtml(label)}</label>
            <input id="${id}" value="${escapeAttr(fieldValue)}"${required ? ' required' : ''}>
        </div>
    `;
}

function textareaField(id, label, fieldValue) {
    return `
        <div class="form-group full">
            <label for="${id}">${escapeHtml(label)}</label>
            <textarea id="${id}" rows="3" required>${escapeHtml(fieldValue)}</textarea>
        </div>
    `;
}

function selectField(id, label, options, selectedValue) {
    return `
        <div class="form-group">
            <label for="${id}">${escapeHtml(label)}</label>
            <select id="${id}">
                ${options.map(([fieldValue, fieldLabel]) => option(fieldValue, fieldLabel, fieldValue === selectedValue)).join('')}
            </select>
        </div>
    `;
}

function selectShell(id, label, note) {
    return `
        <div class="form-group">
            <label for="${id}">${escapeHtml(label)}</label>
            <select id="${id}" required></select>
            <span class="field-note">${escapeHtml(note)}</span>
        </div>
    `;
}

function value(id) {
    const element = document.getElementById(id);
    return element ? element.value.trim() : '';
}

function csvToArray(valueToCheck) {
    return String(valueToCheck || '')
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
}

function arrayToCsv(valueToCheck) {
    return Array.isArray(valueToCheck) ? valueToCheck.join(', ') : String(valueToCheck || '');
}

function avatarUrl(user) {
    if (user.profile_photo_url) return user.profile_photo_url;
    const name = `${user.first_name || ''}+${user.last_name || ''}`;
    return 'https://ui-avatars.com/api/?name=' + encodeURIComponent(name);
}

function escapeHtml(valueToCheck) {
    return String(valueToCheck || '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function escapeAttr(valueToCheck) {
    return escapeHtml(valueToCheck);
}
