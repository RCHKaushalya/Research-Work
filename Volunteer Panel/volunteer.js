const SUPABASE_URL = window.APP_CONFIG.SUPABASE_URL;
const SUPABASE_KEY = window.APP_CONFIG.SUPABASE_KEY;

const headers = {
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${SUPABASE_KEY}`,
  "Content-Type": "application/json"
};

const loginView = document.getElementById("login-view");
const panelView = document.getElementById("panel-view");

const volunteerIdInput = document.getElementById("volunteer-id-input");
const passwordInput = document.getElementById("password-input");
const loginBtn = document.getElementById("login-btn");
const logoutBtn = document.getElementById("logout-btn");
const refreshBtn = document.getElementById("refresh-btn");
const errorMsg = document.getElementById("error-msg");

const volunteerInfo = document.getElementById("volunteer-info");
const pendingUsersList = document.getElementById("pending-users-list");
const pendingJobsList = document.getElementById("pending-jobs-list");

const pendingCountPill = document.getElementById("pending-count-pill");
const statPendingUsers = document.getElementById("stat-pending-users");
const statPendingJobs = document.getElementById("stat-pending-jobs");
const statApproved = document.getElementById("stat-approved");

let approvedThisSession = 0;

if (localStorage.getItem("volunteer")) {
  showPanel();
}

loginBtn.addEventListener("click", login);
logoutBtn.addEventListener("click", logout);
refreshBtn.addEventListener("click", loadData);

document.getElementById("manual-register-btn").addEventListener("click", manualRegisterUser);
document.getElementById("manual-job-btn").addEventListener("click", manualPostJob);
document.getElementById("apply-job-btn").addEventListener("click", submitApplication);
document.getElementById("review-btn").addEventListener("click", submitReview);

document.querySelectorAll(".tab-btn").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".tab-btn").forEach((btn) => btn.classList.remove("active"));
    document.querySelectorAll(".tab-panel").forEach((panel) => panel.classList.remove("active"));

    button.classList.add("active");
    document.getElementById(button.dataset.tab).classList.add("active");
  });
});

async function login() {
  const volunteerId = volunteerIdInput.value.trim();
  const password = passwordInput.value.trim();

  if (!volunteerId || !password) {
    errorMsg.textContent = "Enter volunteer ID and password.";
    return;
  }

  const url =
    `${SUPABASE_URL}/rest/v1/volunteers` +
    `?volunteer_id=eq.${encodeURIComponent(volunteerId)}` +
    `&password=eq.${encodeURIComponent(password)}` +
    `&active=eq.true` +
    `&select=*`;

  console.log(volunteerId);
  console.log(password);
  console.log(url);

  try {
    const res = await fetch(url, { headers });
    const data = await res.json();

    if (!Array.isArray(data) || data.length === 0) {
      errorMsg.textContent = "Invalid volunteer ID or password.";
      return;
    }

    localStorage.setItem("volunteer", JSON.stringify(data[0]));
    errorMsg.textContent = "";
    showPanel();
  } catch {
    errorMsg.textContent = "Login failed.";
  }
}

function logout() {
  localStorage.removeItem("volunteer");
  location.reload();
}

function getVolunteer() {
  try {
    return JSON.parse(localStorage.getItem("volunteer"));
  } catch {
    return null;
  }
}

function showPanel() {
  loginView.classList.add("hidden");
  panelView.classList.remove("hidden");

  const volunteer = getVolunteer();

  volunteerInfo.textContent = volunteer
    ? `${volunteer.full_name} | ${volunteer.district} | ${volunteer.language}`
    : "";

  loadData();
}

async function loadData() {
  await Promise.all([
    loadPendingUsers(),
    loadPendingJobs()
  ]);
}

async function loadPendingUsers() {
  const url =
    `${SUPABASE_URL}/rest/v1/pending_user_registrations` +
    `?status=eq.pending&select=*&order=created_at.desc`;

  try {
    const res = await fetch(url, { headers });
    const users = await res.json();

    statPendingUsers.textContent = users.length;
    updatePendingPill();

    pendingUsersList.innerHTML = users.length
      ? users.map(renderPendingUser).join("")
      : emptyState("No pending user registrations.");

    document.querySelectorAll(".approve-user-btn").forEach((btn) => {
      btn.addEventListener("click", () => approveUser(btn.dataset.id));
    });

    document.querySelectorAll(".reject-user-btn").forEach((btn) => {
      btn.addEventListener("click", () => rejectPending("pending_user_registrations", btn.dataset.id));
    });
  } catch {
    pendingUsersList.innerHTML = emptyState("Unable to load users.");
  }
}

async function loadPendingJobs() {
  const url =
    `${SUPABASE_URL}/rest/v1/pending_job_posts` +
    `?status=eq.pending&select=*&order=created_at.desc`;

  try {
    const res = await fetch(url, { headers });
    const jobs = await res.json();

    statPendingJobs.textContent = jobs.length;
    updatePendingPill();

    pendingJobsList.innerHTML = jobs.length
      ? jobs.map(renderPendingJob).join("")
      : emptyState("No pending job posts.");

    document.querySelectorAll(".approve-job-btn").forEach((btn) => {
      btn.addEventListener("click", () => approveJob(btn.dataset.id));
    });

    document.querySelectorAll(".reject-job-btn").forEach((btn) => {
      btn.addEventListener("click", () => rejectPending("pending_job_posts", btn.dataset.id));
    });
  } catch {
    pendingJobsList.innerHTML = emptyState("Unable to load jobs.");
  }
}

function updatePendingPill() {
  const users = Number(statPendingUsers.textContent || 0);
  const jobs = Number(statPendingJobs.textContent || 0);

  pendingCountPill.textContent = `${users + jobs} pending`;
  statApproved.textContent = String(approvedThisSession);
}

function renderPendingUser(user) {
  return `
    <article class="item-card card">
      <h4>${escapeHtml(`${user.first_name || ""} ${user.last_name || ""}`.trim() || "Unnamed User")}</h4>
      <div class="meta">
        <div><strong>Phone:</strong> ${escapeHtml(user.phone)}</div>
        <div><strong>District:</strong> ${escapeHtml(user.district)}</div>
        <div><strong>DS Area:</strong> ${escapeHtml(user.ds_area)}</div>
        <div><strong>Language:</strong> ${escapeHtml(user.language)}</div>
      </div>
      <div class="actions">
        <button class="button success approve-user-btn" data-id="${user.id}">Approve</button>
        <button class="button danger reject-user-btn" data-id="${user.id}">Reject</button>
      </div>
    </article>
  `;
}

function renderPendingJob(job) {
  return `
    <article class="item-card card">
      <h4>${escapeHtml(job.job_title || "Untitled Job")}</h4>
      <div class="meta">
        <div><strong>Employer:</strong> ${escapeHtml(job.employer_name)}</div>
        <div><strong>Phone:</strong> ${escapeHtml(job.employer_phone)}</div>
        <div><strong>District:</strong> ${escapeHtml(job.district)}</div>
        <div><strong>DS Area:</strong> ${escapeHtml(job.ds_area)}</div>
        <div><strong>Category:</strong> ${escapeHtml(job.category)}</div>
        <div><strong>Skills:</strong> ${escapeHtml(job.required_skills)}</div>
        <div><strong>Payment:</strong> ${escapeHtml(job.payment)}</div>
        <div><strong>Description:</strong> ${escapeHtml(job.job_description)}</div>
      </div>
      <div class="actions">
        <button class="button success approve-job-btn" data-id="${job.id}">Approve</button>
        <button class="button danger reject-job-btn" data-id="${job.id}">Reject</button>
      </div>
    </article>
  `;
}

async function approveUser(id) {
  const pending = await getSingle("pending_user_registrations", id);

  if (!pending) {
    alert("Pending user not found.");
    return;
  }

  const user = {
    phone: pending.phone,
    first_name: pending.first_name,
    last_name: pending.last_name,
    district: pending.district,
    ds_area: pending.ds_area,
    language: pending.language,
    verified: true,
    availability_status: "available"
  };

  const inserted = await insertRow("users", user);

  if (!inserted) {
    alert("Failed to insert user.");
    return;
  }

  await updateRow("pending_user_registrations", id, { status: "approved" });

  approvedThisSession++;
  await loadData();
  alert("User approved.");
}

async function approveJob(id) {
  const pending = await getSingle("pending_job_posts", id);

  if (!pending) {
    alert("Pending job not found.");
    return;
  }

  const job = {
    employer_name: pending.employer_name,
    employer_phone: pending.employer_phone,
    job_title: pending.job_title,
    job_description: pending.job_description,
    district: pending.district,
    ds_area: pending.ds_area,
    category: pending.category,
    required_skills: pending.required_skills,
    payment: pending.payment,
    language: pending.language,
    status: "open"
  };

  const inserted = await insertRow("jobs", job);

  if (!inserted) {
    alert("Failed to insert job.");
    return;
  }

  await updateRow("pending_job_posts", id, { status: "approved" });

  approvedThisSession++;
  await loadData();
  alert("Job approved.");
}

async function rejectPending(table, id) {
  await updateRow(table, id, { status: "rejected" });
  await loadData();
  alert("Rejected.");
}

async function manualRegisterUser() {
  const user = {
    phone: normalizePhone(document.getElementById("reg-phone").value),
    first_name: document.getElementById("reg-first-name").value.trim(),
    last_name: document.getElementById("reg-last-name").value.trim(),
    district: document.getElementById("reg-district").value.trim(),
    ds_area: document.getElementById("reg-ds-area").value.trim(),
    language: document.getElementById("reg-language").value,
    verified: true,
    availability_status: "available"
  };

  const ok = await insertRow("users", user);
  alert(ok ? "User registered." : "Failed to register user.");
}

async function manualPostJob() {
  const job = {
    employer_name: document.getElementById("job-employer-name").value.trim(),
    employer_phone: normalizePhone(document.getElementById("job-employer-phone").value),
    job_title: document.getElementById("job-title").value.trim(),
    job_description: document.getElementById("job-description").value.trim(),
    district: document.getElementById("job-district").value.trim(),
    ds_area: document.getElementById("job-ds-area").value.trim(),
    category: document.getElementById("job-category").value.trim(),
    required_skills: document.getElementById("job-skills").value.trim(),
    payment: document.getElementById("job-payment").value.trim(),
    language: document.getElementById("job-language").value,
    status: "open"
  };

  const ok = await insertRow("jobs", job);
  alert(ok ? "Job posted." : "Failed to post job.");
}

async function submitApplication() {
  const application = {
    worker_phone: normalizePhone(document.getElementById("apply-worker-phone").value),
    job_id: document.getElementById("apply-job-id").value.trim(),
    note: document.getElementById("apply-note").value.trim(),
    status: "pending"
  };

  const ok = await insertRow("applications", application);
  alert(ok ? "Application submitted." : "Failed to submit application.");
}

async function submitReview() {
  const review = {
    worker_phone: normalizePhone(document.getElementById("review-worker-phone").value),
    employer_phone: normalizePhone(document.getElementById("review-employer-phone").value),
    rating: Number(document.getElementById("review-rating").value),
    comment: document.getElementById("review-comment").value.trim()
  };

  const ok = await insertRow("reviews", review);
  alert(ok ? "Review submitted." : "Failed to submit review.");
}

async function getSingle(table, id) {
  const url = `${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}&select=*`;

  const res = await fetch(url, { headers });
  const rows = await res.json();

  return rows[0] || null;
}

async function insertRow(table, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: "POST",
    headers: {
      ...headers,
      Prefer: "return=representation"
    },
    body: JSON.stringify(data)
  });

  console.log(await res.text());
  return res.status === 201;
}

async function updateRow(table, id, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}`, {
    method: "PATCH",
    headers,
    body: JSON.stringify(data)
  });

  return res.ok;
}

function normalizePhone(phone) {
  phone = String(phone || "").trim().replace(/\s+/g, "");

  if (phone.startsWith("0")) {
    return "+94" + phone.substring(1);
  }

  if (phone.startsWith("94")) {
    return "+" + phone;
  }

  if (phone.startsWith("+94")) {
    return phone;
  }

  return phone;
}

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function emptyState(message) {
  return `<div class="card item-card"><p>${message}</p></div>`;
}