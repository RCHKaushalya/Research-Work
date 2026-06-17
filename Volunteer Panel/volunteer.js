const SUPABASE_URL = window.APP_CONFIG.SUPABASE_URL;
const SUPABASE_KEY = window.APP_CONFIG.SUPABASE_KEY;

const headers = {
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${SUPABASE_KEY}`,
  "Content-Type": "application/json"
};

const locationData = window.LOCATION_DATA || { districts: [], dsAreas: {} };
const districtEnglishNames = {
  colombo: "01",
  gampaha: "02",
  kalutara: "03",
  kandy: "04",
  matale: "05",
  "nuwara eliya": "06",
  galle: "07",
  matara: "08",
  hambantota: "09",
  jaffna: "10",
  kilinochchi: "11",
  mannar: "12",
  vavuniya: "13",
  mullaitivu: "14",
  batticaloa: "15",
  ampara: "16",
  trincomalee: "17",
  kurunegala: "18",
  puttalam: "19",
  anuradhapura: "20",
  polonnaruwa: "21",
  badulla: "22",
  monaragala: "23",
  ratnapura: "24",
  kegalle: "25"
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

const approvalModal = document.getElementById("approval-modal");
const approvalTitle = document.getElementById("approval-title");
const approvalSummary = document.getElementById("approval-summary");
const approvalForm = document.getElementById("approval-form");
const approvalFields = document.getElementById("approval-fields");
const approvalCancelBtn = document.getElementById("approval-cancel-btn");

let approvedThisSession = 0;
let approvalContext = null;

setupLocationSelects("reg-district", "reg-ds-area");
setupLocationSelects("job-district", "job-ds-area");

if (localStorage.getItem("volunteer")) {
  showPanel();
}

loginBtn.addEventListener("click", login);
logoutBtn.addEventListener("click", logout);
refreshBtn.addEventListener("click", loadData);
approvalCancelBtn.addEventListener("click", closeApprovalModal);
approvalForm.addEventListener("submit", submitApprovalForm);

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

  try {
    const rows = await fetchRows(url);

    if (!Array.isArray(rows) || rows.length === 0) {
      errorMsg.textContent = "Invalid volunteer ID or password.";
      return;
    }

    localStorage.setItem("volunteer", JSON.stringify(rows[0]));
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
  const district = volunteer ? districtLabel(coerceDistrictKey(volunteer.district)) || volunteer.district : "";

  volunteerInfo.textContent = volunteer
    ? `${volunteer.full_name} | ${district || "All areas"} | ${volunteer.language || "si"}`
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
    const users = await fetchRows(url);

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
    const jobs = await fetchRows(url);

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
  const district = readableDistrict(user.district);
  const dsArea = readableDsArea(user.ds_area, user.district);

  return `
    <article class="item-card card">
      <h4>${escapeHtml(`${user.first_name || ""} ${user.last_name || ""}`.trim() || "Unnamed User")}</h4>
      <div class="meta">
        <div><strong>Phone:</strong> ${escapeHtml(user.phone)}</div>
        <div><strong>District:</strong> ${escapeHtml(district || "Needs key")}</div>
        <div><strong>DS Area:</strong> ${escapeHtml(dsArea || "Needs key")}</div>
        <div><strong>Language:</strong> ${escapeHtml(user.language)}</div>
      </div>
      <div class="actions">
        <button class="button success approve-user-btn" data-id="${escapeAttr(user.id)}">Approve With Form</button>
        <button class="button danger reject-user-btn" data-id="${escapeAttr(user.id)}">Reject</button>
      </div>
    </article>
  `;
}

function renderPendingJob(job) {
  const district = readableDistrict(job.district);
  const dsArea = readableDsArea(job.ds_area, job.district);

  return `
    <article class="item-card card">
      <h4>${escapeHtml(job.job_title || job.title || "Untitled Job")}</h4>
      <div class="meta">
        <div><strong>Employer:</strong> ${escapeHtml(job.employer_name)}</div>
        <div><strong>Phone:</strong> ${escapeHtml(job.employer_phone)}</div>
        <div><strong>District:</strong> ${escapeHtml(district || "Needs key")}</div>
        <div><strong>DS Area:</strong> ${escapeHtml(dsArea || "Needs key")}</div>
        <div><strong>Category:</strong> ${escapeHtml(job.category)}</div>
        <div><strong>Skills:</strong> ${escapeHtml(job.required_skills)}</div>
        <div><strong>Payment:</strong> ${escapeHtml(job.payment)}</div>
        <div><strong>Description:</strong> ${escapeHtml(job.job_description || job.description)}</div>
      </div>
      <div class="actions">
        <button class="button success approve-job-btn" data-id="${escapeAttr(job.id)}">Approve With Form</button>
        <button class="button danger reject-job-btn" data-id="${escapeAttr(job.id)}">Reject</button>
      </div>
    </article>
  `;
}

async function approveUser(id) {
  try {
    const pending = await getSingle("pending_user_registrations", id);

    if (!pending) {
      alert("Pending user not found.");
      return;
    }

    openUserApproval(pending);
  } catch (error) {
    alert("Unable to open user request: " + error.message);
  }
}

async function approveJob(id) {
  try {
    const pending = await getSingle("pending_job_posts", id);

    if (!pending) {
      alert("Pending job not found.");
      return;
    }

    openJobApproval(pending);
  } catch (error) {
    alert("Unable to open job request: " + error.message);
  }
}

function openUserApproval(pending) {
  approvalContext = { type: "user", id: pending.id };
  approvalTitle.textContent = "Approve User Registration";
  approvalSummary.textContent = "Check the phone, NIC, district key, and DS key before approving.";
  approvalFields.innerHTML = `
    ${field("approval-nic", "NIC (unique user key)", pending.nic || pending.user_nic || "", "text", true)}
    ${field("approval-pin", "SMS PIN / password", pending.pin || "", "text", true)}
    ${field("approval-phone", "Phone", normalizePhone(pending.phone), "text", true)}
    ${field("approval-first-name", "First name", pending.first_name || "", "text", true)}
    ${field("approval-last-name", "Last name", pending.last_name || "", "text", true)}
    ${selectField("approval-language", "Language", [
      ["si", "Sinhala"],
      ["ta", "Tamil"],
      ["en", "English"]
    ], pending.language || "si")}
    ${selectShell("approval-district", "District key", "Original: " + (pending.district || "empty"))}
    ${selectShell("approval-ds-area", "DS area key", "Original: " + (pending.ds_area || "empty"))}
    ${field("approval-categories", "Job category keys", arrayToCsv(pending.job_category_ids || pending.categories || ""), "text", false)}
    ${field("approval-skills", "Skill keys", arrayToCsv(pending.skill_ids || pending.skills || ""), "text", false)}
  `;
  setupLocationSelects("approval-district", "approval-ds-area", pending.district, pending.ds_area);
  approvalModal.classList.remove("hidden");
}

function openJobApproval(pending) {
  approvalContext = { type: "job", id: pending.id };
  approvalTitle.textContent = "Approve Job Post";
  approvalSummary.textContent = "Confirm the employer NIC and choose the final location keys before posting.";
  approvalFields.innerHTML = `
    ${field("approval-employer-nic", "Employer NIC", pending.employer_nic || "", "text", false)}
    ${field("approval-employer-phone", "Employer phone", normalizePhone(pending.employer_phone), "text", false)}
    ${field("approval-title-input", "Job title", pending.job_title || pending.title || "", "text", true)}
    ${textAreaField("approval-description", "Description", pending.job_description || pending.description || "")}
    ${selectShell("approval-district", "District key", "Original: " + (pending.district || "empty"))}
    ${selectShell("approval-ds-area", "DS area key", "Original: " + (pending.ds_area || "empty"))}
    ${field("approval-category", "Category", pending.category || "", "text", false)}
    ${field("approval-skills", "Required skill keys", arrayToCsv(pending.required_skills || ""), "text", false)}
    ${field("approval-payment", "Payment note", pending.payment || "", "text", false)}
  `;
  setupLocationSelects("approval-district", "approval-ds-area", pending.district, pending.ds_area);
  approvalModal.classList.remove("hidden");
}

async function submitApprovalForm(event) {
  event.preventDefault();

  if (!approvalContext) {
    return;
  }

  try {
    if (approvalContext.type === "user") {
      await submitUserApproval();
    } else {
      await submitJobApproval();
    }

    closeApprovalModal();
    approvedThisSession++;
    await loadData();
  } catch (error) {
    alert("Approval failed: " + error.message);
  }
}

async function submitUserApproval() {
  const nic = value("approval-nic").toUpperCase();
  const district = value("approval-district");
  const dsArea = value("approval-ds-area");

  if (!nic || !district || !dsArea) {
    throw new Error("NIC, district key, and DS area key are required.");
  }

  const user = {
    nic,
    password_hash: value("approval-pin"),
    phone: normalizePhone(value("approval-phone")),
    first_name: value("approval-first-name"),
    last_name: value("approval-last-name"),
    district,
    ds_area: dsArea,
    language: value("approval-language") || "si",
    verified: true,
    availability_status: "available",
    job_category_ids: csvToArray(value("approval-categories")),
    skill_ids: csvToArray(value("approval-skills"))
  };

  await upsertRow("users", user, "nic");
  await updateRow("pending_user_registrations", approvalContext.id, { status: "approved" });
  alert("User approved with location keys.");
}

async function submitJobApproval() {
  let employerNic = value("approval-employer-nic").toUpperCase();
  const employerPhone = value("approval-employer-phone");
  const district = value("approval-district");
  const dsArea = value("approval-ds-area");

  if (!employerNic && employerPhone) {
    const employer = await findUserByPhoneOrNic(employerPhone);
    employerNic = employer ? employer.nic : "";
  }

  if (!employerNic || !district || !dsArea) {
    throw new Error("Employer NIC, district key, and DS area key are required.");
  }

  const payment = value("approval-payment");
  const description = [value("approval-description"), payment ? `Payment: ${payment}` : ""]
    .filter(Boolean)
    .join("\n\n");

  const job = {
    title: value("approval-title-input"),
    description,
    employer_nic: employerNic,
    category: value("approval-category"),
    location: dsArea || district,
    status: "open",
    required_skills: csvToArray(value("approval-skills")),
    applied_worker_ids: [],
    accepted_worker_ids: [],
    payments: []
  };

  await insertRow("jobs", job);
  await incrementUserCounter(employerNic, "posted_jobs_count");
  await updateRow("pending_job_posts", approvalContext.id, { status: "approved" });
  alert("Job approved with location keys.");
}

function closeApprovalModal() {
  approvalModal.classList.add("hidden");
  approvalForm.reset();
  approvalFields.innerHTML = "";
  approvalContext = null;
}

async function rejectPending(table, id) {
  if (!confirm("Reject this request?")) {
    return;
  }

  await updateRow(table, id, { status: "rejected" });
  await loadData();
  alert("Rejected.");
}

async function manualRegisterUser() {
  const nic = value("reg-nic").toUpperCase();
  const district = value("reg-district");
  const dsArea = value("reg-ds-area");

  if (!nic || !district || !dsArea) {
    alert("NIC, district key, and DS area key are required.");
    return;
  }

  const user = {
    nic,
    password_hash: value("reg-pin"),
    phone: normalizePhone(value("reg-phone")),
    first_name: value("reg-first-name"),
    last_name: value("reg-last-name"),
    district,
    ds_area: dsArea,
    language: value("reg-language") || "si",
    verified: true,
    availability_status: "available",
    completed_jobs_count: 0,
    applied_jobs_count: 0,
    abandoned_jobs_count: 0,
    posted_jobs_count: 0,
    rating: 0,
    job_category_ids: csvToArray(value("reg-categories")),
    skill_ids: csvToArray(value("reg-skills"))
  };

  try {
    await upsertRow("users", user, "nic");
    alert("User registered.");
  } catch (error) {
    alert("Failed to register user: " + error.message);
  }
}

async function manualPostJob() {
  let employerNic = value("job-employer-nic").toUpperCase();
  const employerPhone = value("job-employer-phone");
  const district = value("job-district");
  const dsArea = value("job-ds-area");

  if (!employerNic && employerPhone) {
    const employer = await findUserByPhoneOrNic(employerPhone);
    employerNic = employer ? employer.nic : "";
  }

  if (!employerNic || !district || !dsArea) {
    alert("Employer NIC, district key, and DS area key are required.");
    return;
  }

  const payment = value("job-payment");
  const description = [value("job-description"), payment ? `Payment: ${payment}` : ""]
    .filter(Boolean)
    .join("\n\n");

  const job = {
    title: value("job-title"),
    description,
    employer_nic: employerNic,
    category: value("job-category"),
    location: dsArea || district,
    status: "open",
    required_skills: csvToArray(value("job-skills")),
    applied_worker_ids: [],
    accepted_worker_ids: [],
    payments: []
  };

  try {
    await insertRow("jobs", job);
    await incrementUserCounter(employerNic, "posted_jobs_count");
    alert("Job posted.");
  } catch (error) {
    alert("Failed to post job: " + error.message);
  }
}

async function submitApplication() {
  const worker = await findUserByPhoneOrNic(value("apply-worker-phone"));
  const jobId = value("apply-job-id");

  if (!worker || !jobId) {
    alert("Registered worker and job ID are required.");
    return;
  }

  try {
    const job = await getSingle("jobs", jobId);
    if (!job) {
      alert("Job not found.");
      return;
    }

    const workerNic = worker.nic.toUpperCase();
    const appliedWorkerIds = uniqueList([...(job.applied_worker_ids || []), workerNic]);

    await upsertRow("applications", {
      job_id: jobId,
      worker_nic: workerNic,
      status: "applied",
      applied_at: new Date().toISOString()
    }, "job_id,worker_nic");

    await updateRow("jobs", jobId, { applied_worker_ids: appliedWorkerIds });
    await incrementUserCounter(workerNic, "applied_jobs_count");
    alert("Application submitted.");
  } catch (error) {
    alert("Failed to submit application: " + error.message);
  }
}

async function submitReview() {
  const worker = await findUserByPhoneOrNic(value("review-worker-phone"));
  const reviewer = await findUserByPhoneOrNic(value("review-employer-phone"));
  const rating = Number(value("review-rating"));

  if (!worker || !rating || rating < 1 || rating > 5) {
    alert("Registered worker and rating from 1 to 5 are required.");
    return;
  }

  try {
    await insertRow("reviews", {
      reviewer_nic: reviewer ? reviewer.nic.toUpperCase() : null,
      worker_nic: worker.nic.toUpperCase(),
      rating,
      comment: value("review-comment"),
      created_at: new Date().toISOString()
    });

    await refreshWorkerRating(worker.nic);
    alert("Review submitted.");
  } catch (error) {
    alert("Failed to submit review: " + error.message);
  }
}

async function getSingle(table, id) {
  const url = `${SUPABASE_URL}/rest/v1/${table}?id=eq.${encodeURIComponent(id)}&select=*`;
  const rows = await fetchRows(url);
  return rows[0] || null;
}

async function findUserByPhoneOrNic(input) {
  const raw = String(input || "").trim();
  if (!raw) {
    return null;
  }

  const nicRows = await fetchRows(
    `${SUPABASE_URL}/rest/v1/users?nic=eq.${encodeURIComponent(raw.toUpperCase())}&select=*`
  );
  if (nicRows.length) {
    return nicRows[0];
  }

  const phoneRows = await fetchRows(
    `${SUPABASE_URL}/rest/v1/users?phone=eq.${encodeURIComponent(normalizePhone(raw))}&select=*`
  );
  return phoneRows[0] || null;
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

  return parseResponse(res);
}

async function upsertRow(table, data, conflictColumns) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/${table}?on_conflict=${encodeURIComponent(conflictColumns)}`,
    {
      method: "POST",
      headers: {
        ...headers,
        Prefer: "resolution=merge-duplicates,return=representation"
      },
      body: JSON.stringify(data)
    }
  );

  return parseResponse(res);
}

async function updateRow(table, id, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?id=eq.${encodeURIComponent(id)}`, {
    method: "PATCH",
    headers,
    body: JSON.stringify(data)
  });

  return parseResponse(res);
}

async function fetchRows(url) {
  const res = await fetch(url, { headers });
  const payload = await parseResponse(res);
  return Array.isArray(payload) ? payload : [];
}

async function parseResponse(res) {
  const text = await res.text();
  const payload = text ? tryParseJson(text) : null;

  if (!res.ok) {
    const message = payload && payload.message ? payload.message : text || res.statusText;
    throw new Error(message);
  }

  return payload;
}

function tryParseJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function incrementUserCounter(nic, key) {
  if (!nic) {
    return;
  }

  const user = await findUserByPhoneOrNic(nic);
  if (!user) {
    return;
  }

  const nextValue = Number(user[key] || 0) + 1;
  await updateRowByColumn("users", "nic", user.nic, { [key]: nextValue });
}

async function updateRowByColumn(table, column, valueToMatch, data) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/${table}?${column}=eq.${encodeURIComponent(valueToMatch)}`,
    {
      method: "PATCH",
      headers,
      body: JSON.stringify(data)
    }
  );

  return parseResponse(res);
}

async function refreshWorkerRating(workerNic) {
  const ratings = await fetchRows(
    `${SUPABASE_URL}/rest/v1/reviews?worker_nic=eq.${encodeURIComponent(workerNic.toUpperCase())}&select=rating`
  );
  const values = ratings
    .map((row) => Number(row.rating))
    .filter((rating) => Number.isFinite(rating));

  if (!values.length) {
    return;
  }

  const average = values.reduce((sum, rating) => sum + rating, 0) / values.length;
  await updateRowByColumn("users", "nic", workerNic.toUpperCase(), { rating: average });
}

function setupLocationSelects(districtId, dsAreaId, districtValue = "", dsAreaValue = "") {
  const districtSelect = document.getElementById(districtId);
  const dsAreaSelect = document.getElementById(dsAreaId);
  if (!districtSelect || !dsAreaSelect) {
    return;
  }

  const districtKey = coerceDistrictKey(districtValue);
  const dsAreaKey = coerceDsKey(dsAreaValue, districtKey);
  const finalDistrictKey = districtKey || districtForDs(dsAreaKey);

  populateDistrictSelect(districtSelect, finalDistrictKey);
  populateDsAreaSelect(dsAreaSelect, finalDistrictKey, dsAreaKey);

  districtSelect.addEventListener("change", () => {
    populateDsAreaSelect(dsAreaSelect, districtSelect.value, "");
  });
}

function populateDistrictSelect(select, selectedValue) {
  select.innerHTML = `<option value="">Select district key</option>` +
    locationData.districts
      .map((district) => option(district.id, locationOptionLabel(district), district.id === selectedValue))
      .join("");
}

function populateDsAreaSelect(select, districtId, selectedValue) {
  const areas = districtId ? locationData.dsAreas[districtId] || [] : [];
  select.innerHTML = `<option value="">Select DS area key</option>` +
    areas
      .map((area) => option(area.id, locationOptionLabel(area), area.id === selectedValue))
      .join("");
}

function option(valueToUse, label, selected) {
  return `<option value="${escapeAttr(valueToUse)}"${selected ? " selected" : ""}>${escapeHtml(label)}</option>`;
}

function coerceDistrictKey(valueToCheck) {
  const raw = String(valueToCheck || "").trim();
  if (!raw) {
    return "";
  }

  const direct = locationData.districts.find((district) =>
    [district.id, district.si, district.ta].includes(raw)
  );
  if (direct) {
    return direct.id;
  }

  return districtEnglishNames[normalizeText(raw)] || "";
}

function coerceDsKey(valueToCheck, districtKey = "") {
  const raw = String(valueToCheck || "").trim();
  if (!raw) {
    return "";
  }

  const districtsToSearch = districtKey
    ? [districtKey]
    : Object.keys(locationData.dsAreas);

  for (const key of districtsToSearch) {
    const match = (locationData.dsAreas[key] || []).find((area) =>
      [area.id, area.si, area.ta].includes(raw)
    );
    if (match) {
      return match.id;
    }
  }

  return "";
}

function districtForDs(dsAreaKey) {
  if (!dsAreaKey) {
    return "";
  }

  return Object.keys(locationData.dsAreas).find((districtId) =>
    (locationData.dsAreas[districtId] || []).some((area) => area.id === dsAreaKey)
  ) || "";
}

function readableDistrict(valueToCheck) {
  const key = coerceDistrictKey(valueToCheck);
  return districtLabel(key) || valueToCheck || "";
}

function readableDsArea(valueToCheck, districtValue) {
  const districtKey = coerceDistrictKey(districtValue);
  const key = coerceDsKey(valueToCheck, districtKey);
  return dsAreaLabel(key, districtKey) || valueToCheck || "";
}

function districtLabel(districtKey) {
  const district = locationData.districts.find((item) => item.id === districtKey);
  return district ? locationOptionLabel(district) : "";
}

function dsAreaLabel(dsAreaKey, districtKey = "") {
  const key = districtKey || districtForDs(dsAreaKey);
  const area = (locationData.dsAreas[key] || []).find((item) => item.id === dsAreaKey);
  return area ? locationOptionLabel(area) : "";
}

function locationOptionLabel(item) {
  return `${item.id} - ${item.si} / ${item.ta}`;
}

function normalizeText(valueToCheck) {
  return String(valueToCheck || "").trim().toLowerCase().replace(/\s+/g, " ");
}

function field(id, label, fieldValue, type = "text", required = false) {
  return `
    <div class="form-field">
      <label for="${id}">${escapeHtml(label)}</label>
      <input id="${id}" type="${type}" value="${escapeAttr(fieldValue)}"${required ? " required" : ""} />
    </div>
  `;
}

function textAreaField(id, label, fieldValue) {
  return `
    <div class="form-field full">
      <label for="${id}">${escapeHtml(label)}</label>
      <textarea id="${id}" required>${escapeHtml(fieldValue)}</textarea>
    </div>
  `;
}

function selectField(id, label, options, selectedValue) {
  return `
    <div class="form-field">
      <label for="${id}">${escapeHtml(label)}</label>
      <select id="${id}">
        ${options.map(([fieldValue, fieldLabel]) => option(fieldValue, fieldLabel, fieldValue === selectedValue)).join("")}
      </select>
    </div>
  `;
}

function selectShell(id, label, note) {
  return `
    <div class="form-field">
      <label for="${id}">${escapeHtml(label)}</label>
      <select id="${id}" required></select>
      <span class="field-note">${escapeHtml(note)}</span>
    </div>
  `;
}

function value(id) {
  const element = document.getElementById(id);
  return element ? element.value.trim() : "";
}

function csvToArray(valueToCheck) {
  return String(valueToCheck || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function arrayToCsv(valueToCheck) {
  if (Array.isArray(valueToCheck)) {
    return valueToCheck.join(", ");
  }

  return String(valueToCheck || "");
}

function uniqueList(items) {
  return [...new Set(items.map((item) => String(item || "").trim()).filter(Boolean))];
}

function normalizePhone(phone) {
  phone = String(phone || "").trim().replace(/[\s().-]+/g, "");

  if (phone.startsWith("0")) {
    return "+94" + phone.substring(1);
  }

  if (phone.startsWith("94")) {
    return "+" + phone;
  }

  return phone;
}

function escapeHtml(valueToCheck) {
  return String(valueToCheck || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function escapeAttr(valueToCheck) {
  return escapeHtml(valueToCheck);
}

function emptyState(message) {
  return `<div class="card item-card"><p>${escapeHtml(message)}</p></div>`;
}
