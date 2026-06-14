const backendUrl = 'http://localhost:8000';
const volunteerPin = '9421';

const loginView = document.getElementById('login-view');
const panelView = document.getElementById('panel-view');
const pinInput = document.getElementById('pin-input');
const loginBtn = document.getElementById('login-btn');
const logoutBtn = document.getElementById('logout-btn');
const refreshBtn = document.getElementById('refresh-btn');
const errorMsg = document.getElementById('error-msg');
const pendingList = document.getElementById('pending-list');
const supportList = document.getElementById('support-list');
const pendingCountPill = document.getElementById('pending-count-pill');
const statPending = document.getElementById('stat-pending');
const statVerified = document.getElementById('stat-verified');
const statSupport = document.getElementById('stat-support');
const supportReceiver = document.getElementById('support-receiver');
const supportMessage = document.getElementById('support-message');
const supportSendBtn = document.getElementById('support-send-btn');
let verifiedThisSession = 0;

const localAuth = localStorage.getItem('volunteer_authenticated') === 'true';
if (localAuth) {
    showPanel();
}

loginBtn.addEventListener('click', () => {
    const pin = pinInput.value.trim();
    if (pin !== volunteerPin) {
        errorMsg.textContent = 'Invalid volunteer PIN';
        return;
    }

    localStorage.setItem('volunteer_authenticated', 'true');
    errorMsg.textContent = '';
    verifiedThisSession = 0;
    showPanel();
});

logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('volunteer_authenticated');
    location.reload();
});

refreshBtn.addEventListener('click', loadData);
supportSendBtn.addEventListener('click', sendSupportResponse);

document.querySelectorAll('.tab-btn').forEach((button) => {
    button.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach((item) => item.classList.remove('active'));
        document.querySelectorAll('.tab-panel').forEach((item) => item.classList.remove('active'));
        button.classList.add('active');
        document.getElementById(button.dataset.tab).classList.add('active');
    });
});

function showPanel() {
    loginView.classList.add('hidden');
    panelView.classList.remove('hidden');
    loadData();
}

async function loadData() {
    await Promise.all([loadPendingUsers(), loadSupportQueries()]);
}

async function loadPendingUsers() {
    try {
        const response = await fetch(`${backendUrl}/volunteer/pending-users`);
        const users = await response.json();
        const safeUsers = Array.isArray(users) ? users : [];

        statPending.textContent = safeUsers.length;
        pendingCountPill.textContent = `${safeUsers.length} pending`;
        statVerified.textContent = String(verifiedThisSession);

        pendingList.innerHTML = safeUsers.length
            ? safeUsers.map(renderPendingUser).join('')
            : emptyState('No pending registrations right now.');

        document.querySelectorAll('.verify-btn').forEach((button) => {
            button.addEventListener('click', async () => {
                const nic = button.dataset.nic;
                await verifyUser(nic);
            });
        });
    } catch (error) {
        pendingList.innerHTML = emptyState('Unable to load pending registrations.');
    }
}

async function verifyUser(nic) {
    try {
        const response = await fetch(`${backendUrl}/volunteer/verify/${encodeURIComponent(nic)}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
        });

        if (!response.ok) {
            throw new Error(await response.text());
        }

        verifiedThisSession += 1;
        await loadPendingUsers();
        statVerified.textContent = String(verifiedThisSession);
        alert(`Verified ${nic}`);
    } catch (error) {
        alert('Failed to verify user');
    }
}

async function loadSupportQueries() {
    try {
        const response = await fetch(`${backendUrl}/volunteer/support-queries`);
        const queries = await response.json();
        const safeQueries = Array.isArray(queries) ? queries : [];

        statSupport.textContent = safeQueries.length;
        supportList.innerHTML = safeQueries.length
            ? safeQueries.map(renderSupportQuery).join('')
            : emptyState('No support queries yet.');
    } catch (error) {
        supportList.innerHTML = emptyState('Unable to load support queries.');
    }
}

async function sendSupportResponse() {
    const senderNic = 'VOLUNTEER';
    const receiverNic = supportReceiver.value.trim();
    const content = supportMessage.value.trim();

    if (!receiverNic || !content) {
        alert('Enter receiver NIC and message.');
        return;
    }

    try {
        const response = await fetch(`${backendUrl}/volunteer/support-respond`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sender_nic: senderNic, receiver_nic: receiverNic, content }),
        });

        if (!response.ok) {
            throw new Error(await response.text());
        }

        supportMessage.value = '';
        alert('Support response sent');
        await loadSupportQueries();
    } catch (error) {
        alert('Failed to send support response');
    }
}

function renderPendingUser(user) {
    const template = document.getElementById('pending-card-template');
    const card = template.content.cloneNode(true);
    const firstName = user.first_name || '';
    const lastName = user.last_name || '';

    card.querySelector('.worker-name').textContent = `${firstName} ${lastName}`.trim() || 'Unnamed worker';
    card.querySelector('.worker-nic').textContent = user.nic || 'Unknown NIC';
    card.querySelector('.worker-meta').innerHTML = `
        <div><strong>Phone:</strong> ${user.phone || '—'}</div>
        <div><strong>Area:</strong> ${(user.district || '—') + ' / ' + (user.ds_area || '—')}</div>
        <div><strong>Skills:</strong> ${(Array.isArray(user.skill_ids) && user.skill_ids.length) ? user.skill_ids.join(', ') : 'No skills listed'}</div>
    `;
    card.querySelector('.verify-btn').dataset.nic = user.nic;
    return card.firstElementChild.outerHTML;
}

function renderSupportQuery(query) {
    const template = document.getElementById('support-card-template');
    const card = template.content.cloneNode(true);
    const title = query.sender_nic ? `From ${query.sender_nic}` : 'Support query';
    const timestamp = query.created_at ? new Date(query.created_at).toLocaleString() : '';

    card.querySelector('.support-title').textContent = title;
    card.querySelector('.support-channel').textContent = query.receiver_nic ? `To ${query.receiver_nic}` : 'General support';
    card.querySelector('.support-time').textContent = timestamp;
    card.querySelector('.support-body').textContent = query.content || '';
    return card.firstElementChild.outerHTML;
}

function emptyState(message) {
    return `<div class="card worker-card"><p>${message}</p></div>`;
}
