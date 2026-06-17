from __future__ import annotations

import base64
import hashlib
import hmac
import json
import logging
import os
import re
import secrets
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from supabase_service import (
    add_application,
    application_exists,
    find_application,
    find_job_by_prefix,
    find_user_by_nic,
    find_user_by_phone,
    insert_job,
    insert_sms_message,
    is_configured as supabase_is_configured,
    list_applications_for_job,
    list_jobs_by_employer,
    list_open_jobs,
    log_incoming_sms,
    set_application_status,
    update_job_by_id,
    update_job_worker_lists,
    update_user_by_nic,
    upsert_user,
)

BASE_DIR = Path(__file__).resolve().parent
ENV_FILE = BASE_DIR / ".env"


def load_local_env_file() -> None:
    if not ENV_FILE.exists():
        return

    for raw_line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_local_env_file()

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s - %(message)s",
)
logger = logging.getLogger("sms-system")


@dataclass(frozen=True)
class Settings:
    sms_gateway_url: str = os.getenv(
        "SMS_GATEWAY_SEND_URL",
        "https://app.sms-gateway.app/services/send.php",
    )
    sms_gateway_key: str = os.getenv("SMS_GATEWAY_API_KEY") or os.getenv("SMS_API_KEY", "")
    sms_webhook_key: str = (
        os.getenv("SMS_GATEWAY_WEBHOOK_KEY")
        or os.getenv("SMS_GATEWAY_API_KEY")
        or os.getenv("SMS_API_KEY", "")
    )
    sms_devices: str = os.getenv("SMS_GATEWAY_DEVICES", "")
    sms_type: str = os.getenv("SMS_GATEWAY_TYPE", "sms")
    sms_prioritize: str = os.getenv("SMS_GATEWAY_PRIORITIZE", "0")
    default_country_code: str = os.getenv("DEFAULT_COUNTRY_CODE", "+94")
    admin_api_key: str = os.getenv("ADMIN_API_KEY", "")
    cors_origins: str = os.getenv("CORS_ORIGINS", "*")


settings = Settings()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def normalize_phone(phone_number: str) -> str:
    phone = re.sub(r"[\s().-]+", "", str(phone_number or ""))
    if not phone:
        return phone
    if phone.startswith("00"):
        return f"+{phone[2:]}"
    if phone.startswith("+"):
        return phone

    country = settings.default_country_code
    country_digits = country.lstrip("+")
    if phone.startswith("0") and country:
        return f"{country}{phone[1:]}"
    if phone.startswith(country_digits):
        return f"+{phone}"
    return f"+{phone}"


def full_name(user: dict[str, Any] | None) -> str:
    if not user:
        return ""
    return " ".join(
        part for part in [user.get("first_name", ""), user.get("last_name", "")] if part
    ).strip()


def split_name(name: str) -> tuple[str, str]:
    parts = [part for part in name.strip().split() if part]
    if not parts:
        return "SMS", "User"
    if len(parts) == 1:
        return parts[0], "User"
    return parts[0], " ".join(parts[1:])


def parse_skills(raw: str) -> list[str]:
    skills = [item.strip() for item in re.split(r"[,/]+", raw or "") if item.strip()]
    if len(skills) == 1 and " " in skills[0]:
        skills = [item.strip() for item in skills[0].split() if item.strip()]
    return [skill.upper().replace(" ", "_") for skill in skills[:12]]


def job_code(job: dict[str, Any]) -> str:
    return str(job.get("id", ""))[:6].upper()


def command_body(message: str) -> str:
    parts = message.strip().split(maxsplit=1)
    return parts[1].strip() if len(parts) > 1 else ""


def require_supabase() -> None:
    if not supabase_is_configured():
        raise HTTPException(
            status_code=503,
            detail="Supabase is not configured. Add SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.",
        )


def require_admin(request: Request) -> None:
    if not settings.admin_api_key:
        return
    supplied = request.headers.get("x-admin-key") or request.query_params.get("admin_key")
    if not supplied or not hmac.compare_digest(supplied, settings.admin_api_key):
        raise HTTPException(status_code=401, detail="Invalid admin key")


def verify_gateway_signature(raw_payload: str, signature: str | None) -> None:
    if not settings.sms_webhook_key:
        raise HTTPException(
            status_code=503,
            detail="SMS_GATEWAY_WEBHOOK_KEY or SMS_GATEWAY_API_KEY is not configured.",
        )
    if not signature:
        raise HTTPException(status_code=400, detail="Signature missing")

    expected = base64.b64encode(
        hmac.new(
            settings.sms_webhook_key.encode("utf-8"),
            raw_payload.encode("utf-8"),
            hashlib.sha256,
        ).digest()
    ).decode("utf-8")

    if not hmac.compare_digest(expected, signature):
        raise HTTPException(status_code=401, detail="Invalid signature")


def log_outgoing_sms(phone_number: str, message: str, status: str) -> None:
    if not supabase_is_configured():
        return

    try:
        insert_sms_message(
            {
                "id": f"out_{uuid.uuid4().hex}",
                "phone_number": normalize_phone(phone_number),
                "message": message,
                "direction": "outgoing",
                "status": status,
                "created_at": utc_now(),
                "sent_at": utc_now() if status in {"sent", "queued"} else None,
            }
        )
    except Exception:
        logger.exception("Could not log outgoing SMS")


def send_sms(phone_number: str, message: str) -> dict[str, Any]:
    if not settings.sms_gateway_key:
        raise HTTPException(
            status_code=503,
            detail="SMS gateway is not configured. Add SMS_GATEWAY_API_KEY.",
        )

    phone = normalize_phone(phone_number)
    text = message.strip()
    params: dict[str, Any] = {
        "key": settings.sms_gateway_key,
        "number": phone,
        "message": text,
        "type": settings.sms_type,
        "prioritize": settings.sms_prioritize,
    }
    if settings.sms_devices:
        params["devices"] = settings.sms_devices

    try:
        response = requests.get(settings.sms_gateway_url, params=params, timeout=20)
        response.raise_for_status()
        payload = response.json()
        success = bool(payload.get("success"))
    except requests.RequestException as exc:
        log_outgoing_sms(phone, text, "failed")
        logger.exception("SMS gateway request failed")
        raise HTTPException(status_code=502, detail=f"SMS gateway request failed: {exc}") from exc
    except ValueError as exc:
        log_outgoing_sms(phone, text, "failed")
        logger.exception("SMS gateway returned invalid JSON")
        raise HTTPException(status_code=502, detail="SMS gateway returned invalid JSON") from exc

    status = "queued" if success else "failed"
    log_outgoing_sms(phone, text, status)
    if not success:
        raise HTTPException(status_code=502, detail=payload.get("error") or payload)

    return {"success": True, "phone_number": phone, "status": status, "gateway": payload}


def safe_send_sms(phone_number: str, message: str) -> bool:
    try:
        send_sms(phone_number, message)
        return True
    except Exception:
        logger.exception("Could not send SMS to %s", phone_number)
        return False


HELP_TEXT = (
    "Workforce SMS commands:\n"
    "REG NIC Full Name\n"
    "PROFILE\n"
    "NAME Full Name\n"
    "AREA District | DS Area\n"
    "SKILL plumbing,wiring\n"
    "POST Title | Area | Details\n"
    "JOBS\n"
    "APPLY JobCode\n"
    "MYJOBS\n"
    "APPROVE JobCode WorkerNIC\n"
    "REJECT JobCode WorkerNIC"
)


def unregistered_text() -> str:
    return "Please register first. Send: REG NIC Full Name"


def get_user_or_reply(phone_number: str) -> dict[str, Any] | None:
    user = find_user_by_phone(normalize_phone(phone_number))
    return user if user else None


def handle_register(phone_number: str, body: str) -> str:
    parts = body.split(maxsplit=1)
    if len(parts) < 2:
        return "Register like this: REG 991234567V Nimal Perera"

    phone = normalize_phone(phone_number)
    nic = parts[0].upper()
    first_name, last_name = split_name(parts[1])
    existing = find_user_by_phone(phone)

    if existing and existing.get("nic") and not str(existing["nic"]).startswith("TEMP_"):
        if str(existing["nic"]).upper() != nic:
            return f"This phone is already registered as NIC {existing['nic']}. Send PROFILE to view it."

    pin = f"{secrets.randbelow(1_000_000):06d}"
    upsert_user(
        {
            "nic": nic,
            "first_name": first_name,
            "last_name": last_name,
            "phone": phone,
            "password_hash": pin,
            "district": existing.get("district", "") if existing else "",
            "ds_area": existing.get("ds_area", "") if existing else "",
            "language": existing.get("language", "si") if existing else "si",
            "verified": bool(existing.get("verified", False)) if existing else False,
            "profile_photo_url": existing.get("profile_photo_url") if existing else None,
            "rating": existing.get("rating", 0) if existing else 0,
            "completed_jobs_count": existing.get("completed_jobs_count", 0) if existing else 0,
            "abandoned_jobs_count": existing.get("abandoned_jobs_count", 0) if existing else 0,
            "posted_jobs_count": existing.get("posted_jobs_count", 0) if existing else 0,
            "applied_jobs_count": existing.get("applied_jobs_count", 0) if existing else 0,
            "removed_jobs_count": existing.get("removed_jobs_count", 0) if existing else 0,
            "availability_status": existing.get("availability_status", "available") if existing else "available",
            "job_category_ids": existing.get("job_category_ids", []) if existing else [],
            "skill_ids": existing.get("skill_ids", []) if existing else [],
        }
    )
    return (
        f"Registered {first_name}. Your PIN is {pin}. "
        "Set area: AREA Colombo | Maharagama. Add skills: SKILL plumbing,wiring."
    )


def handle_profile(user: dict[str, Any]) -> str:
    skills = ", ".join(user.get("skill_ids") or []) or "not set"
    area = " / ".join(
        part for part in [user.get("district", ""), user.get("ds_area", "")] if part
    ) or "not set"
    verified = "yes" if user.get("verified") else "pending"
    return (
        f"Profile: {full_name(user)}\n"
        f"NIC: {user.get('nic')}\n"
        f"Area: {area}\n"
        f"Skills: {skills}\n"
        f"Verified: {verified}"
    )


def handle_name(user: dict[str, Any], body: str) -> str:
    if not body:
        return "Change name like this: NAME Nimal Perera"
    first_name, last_name = split_name(body)
    update_user_by_nic(user["nic"], {"first_name": first_name, "last_name": last_name})
    return f"Name updated to {first_name} {last_name}."


def handle_area(user: dict[str, Any], body: str) -> str:
    if not body:
        return "Set area like this: AREA Colombo | Maharagama"

    fields = [field.strip() for field in body.split("|") if field.strip()]
    if len(fields) >= 2:
        district, ds_area = fields[0], fields[1]
    else:
        parts = body.split(maxsplit=1)
        district = parts[0]
        ds_area = parts[1] if len(parts) > 1 else ""

    update_user_by_nic(user["nic"], {"district": district, "ds_area": ds_area})
    area_text = f"{district} / {ds_area}" if ds_area else district
    return f"Area updated to {area_text}."


def handle_skill(user: dict[str, Any], body: str) -> str:
    skills = parse_skills(body)
    if not skills:
        return "Add skills like this: SKILL plumbing,wiring,driving"

    current_skills = list(user.get("skill_ids") or [])
    current_categories = list(user.get("job_category_ids") or [])
    for skill in skills:
        if skill not in current_skills:
            current_skills.append(skill)
        category = f"CAT_{skill}"
        if category not in current_categories:
            current_categories.append(category)

    update_user_by_nic(
        user["nic"],
        {"skill_ids": current_skills, "job_category_ids": current_categories},
    )
    return f"Skills updated: {', '.join(current_skills)}."


def handle_post_job(user: dict[str, Any], body: str) -> str:
    fields = [field.strip() for field in body.split("|") if field.strip()]
    if len(fields) < 3:
        return "Post job like this: POST Painter needed | Colombo | Paint one room tomorrow"

    title, location, description = fields[0], fields[1], fields[2]
    skills = parse_skills(fields[3]) if len(fields) >= 4 else []
    job_id = insert_job(
        {
            "title": title[:120],
            "description": description[:1200],
            "employer_nic": user["nic"],
            "category": skills[0] if skills else "General",
            "location": location[:120],
            "status": "open",
            "required_skills": skills,
            "applied_worker_ids": [],
            "accepted_worker_ids": [],
            "payments": [],
            "created_at": utc_now(),
            "updated_at": utc_now(),
        }
    )
    job = find_job_by_prefix(job_id) or {"id": job_id}
    return f"Job posted. Code {job_code(job)}. Workers can reply APPLY {job_code(job)}."


def format_job(job: dict[str, Any]) -> str:
    return f"{job_code(job)} {job.get('title', 'Job')} - {job.get('location', 'area unknown')}"


def handle_jobs(user: dict[str, Any], body: str) -> str:
    preferred_area = body.strip() or user.get("ds_area") or user.get("district") or ""
    jobs = list_open_jobs(area=preferred_area, limit=25)
    user_skills = {str(skill).upper() for skill in (user.get("skill_ids") or [])}

    matches: list[dict[str, Any]] = []
    for job in jobs:
        if job.get("employer_nic") == user.get("nic"):
            continue
        required = {str(skill).upper() for skill in (job.get("required_skills") or [])}
        if not required or not user_skills or user_skills.intersection(required):
            matches.append(job)
        if len(matches) >= 5:
            break

    if not matches:
        return "No matching open jobs found now. Try JOBS Colombo or check again later."

    lines = ["Open jobs:"]
    lines.extend(format_job(job) for job in matches)
    lines.append("Reply APPLY JobCode")
    return "\n".join(lines)


def handle_apply(user: dict[str, Any], body: str) -> str:
    if not body:
        return "Apply like this: APPLY JobCode"

    job = find_job_by_prefix(body.split()[0])
    if not job:
        return "Job not found. Send JOBS to see open jobs."
    if job.get("employer_nic") == user.get("nic"):
        return "This job was posted by you. Workers can apply to it."
    if job.get("status") != "open":
        return "This job is not open now."

    worker_nic = user["nic"]
    if application_exists(job["id"], worker_nic):
        return f"You already applied for {job.get('title', 'this job')}."

    add_application(job["id"], worker_nic)
    update_job_worker_lists(job["id"])

    employer = find_user_by_nic(job.get("employer_nic", ""))
    if employer and employer.get("phone"):
        safe_send_sms(
            employer["phone"],
            (
                f"{full_name(user)} applied for {job.get('title', 'your job')} "
                f"({job_code(job)}). Reply APPROVE {job_code(job)} {worker_nic} "
                f"or REJECT {job_code(job)} {worker_nic}."
            ),
        )

    return f"Applied for {job.get('title', 'job')} ({job_code(job)}). Employer will reply by SMS."


def handle_my_jobs(user: dict[str, Any]) -> str:
    jobs = list_jobs_by_employer(user["nic"], limit=10)
    if not jobs:
        return "You have not posted jobs yet. Use POST Title | Area | Details."

    lines = ["Your jobs:"]
    for job in jobs[:5]:
        applications = list_applications_for_job(job["id"])
        waiting = sum(1 for app in applications if app.get("status") == "applied")
        lines.append(f"{format_job(job)} [{job.get('status')}] {waiting} requests")
    lines.append("Reply APPROVE JobCode WorkerNIC")
    return "\n".join(lines)


def handle_employer_reply(user: dict[str, Any], body: str, status: str) -> str:
    parts = body.split()
    if len(parts) < 2:
        verb = "APPROVE" if status == "accepted" else "REJECT"
        return f"Use: {verb} JobCode WorkerNIC"

    job = find_job_by_prefix(parts[0])
    if not job:
        return "Job not found."
    if job.get("employer_nic") != user.get("nic"):
        return "Only the job owner can reply to requests for this job."

    worker_key = parts[1].upper()
    worker = find_user_by_nic(worker_key) or find_user_by_phone(worker_key)
    if not worker:
        return "Worker not found. Use the WorkerNIC shown in the request SMS."

    application = find_application(job["id"], worker["nic"])
    if not application:
        return "No request found from that worker for this job."

    set_application_status(job["id"], worker["nic"], status)
    update_job_worker_lists(job["id"])

    if status == "accepted":
        update_job_by_id(job["id"], {"status": "assigned", "updated_at": utc_now()})
        worker_message = (
            f"Good news. You are approved for {job.get('title', 'the job')} "
            f"({job_code(job)}). Employer phone: {user.get('phone', 'not available')}."
        )
        employer_message = f"Approved {full_name(worker)} for {job.get('title', 'job')}."
    else:
        worker_message = f"Your request for {job.get('title', 'the job')} was not selected."
        employer_message = f"Rejected {full_name(worker)} for {job.get('title', 'job')}."

    if worker.get("phone"):
        safe_send_sms(worker["phone"], worker_message)
    return employer_message


def handle_close_job(user: dict[str, Any], body: str) -> str:
    if not body:
        return "Close job like this: CLOSE JobCode"

    job = find_job_by_prefix(body.split()[0])
    if not job:
        return "Job not found."
    if job.get("employer_nic") != user.get("nic"):
        return "Only the job owner can close this job."

    update_job_by_id(job["id"], {"status": "closed", "updated_at": utc_now()})
    return f"Closed {job.get('title', 'job')} ({job_code(job)})."


def build_sms_reply(phone_number: str, message: str) -> str:
    text = (message or "").strip()
    if not text:
        return HELP_TEXT

    command = text.split()[0].upper()
    body = command_body(text)

    if command in {"HI", "HELLO", "HELP", "MENU", "START"}:
        return HELP_TEXT

    require_supabase()

    if command in {"REG", "REGISTER"}:
        return handle_register(phone_number, body)

    user = get_user_or_reply(phone_number)
    if not user:
        return unregistered_text()

    if command == "PROFILE":
        return handle_profile(user)
    if command == "NAME":
        return handle_name(user, body)
    if command == "AREA":
        return handle_area(user, body)
    if command in {"SKILL", "SKILLS"}:
        return handle_skill(user, body)
    if command in {"POST", "JOBPOST"}:
        return handle_post_job(user, body)
    if command in {"JOB", "JOBS", "FIND"}:
        return handle_jobs(user, body)
    if command in {"APPLY", "YES"}:
        return handle_apply(user, body)
    if command in {"MYJOBS", "MYJOB"}:
        return handle_my_jobs(user)
    if command in {"APPROVE", "ACCEPT"}:
        return handle_employer_reply(user, body, "accepted")
    if command in {"REJECT", "NO"}:
        return handle_employer_reply(user, body, "rejected")
    if command in {"CLOSE", "DONE"}:
        return handle_close_job(user, body)

    # Shorthand from job notification: "ABC123 1" means apply.
    shorthand = text.split()
    if len(shorthand) >= 2 and shorthand[1] == "1":
        return handle_apply(user, shorthand[0])

    return "Sorry, I did not understand. Send HELP for commands."


def process_incoming_sms(phone_number: str, message: str) -> str:
    phone = normalize_phone(phone_number)

    if supabase_is_configured():
        try:
            log_incoming_sms(phone, message)
        except Exception:
            logger.exception("Could not log incoming SMS")

    reply = build_sms_reply(phone, message)
    send_sms(phone, reply)
    return reply


class IncomingSMSTest(BaseModel):
    phone_number: str
    message: str
    send_reply: bool = True


allow_origins = ["*"] if settings.cors_origins == "*" else split_csv(settings.cors_origins)

app = FastAPI(
    title="Workforce Platform SMS System",
    description="FastAPI SMS portal for registration, profile management, job posting, applications, and employer replies.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root() -> dict[str, Any]:
    return {
        "service": "Workforce Platform SMS System",
        "status": "running",
        "docs": "/docs",
        "health": "/health",
        "commands": "/commands",
    }


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "supabase_configured": supabase_is_configured(),
        "sms_gateway_configured": bool(settings.sms_gateway_key),
        "webhook_signature_configured": bool(settings.sms_webhook_key),
    }


@app.get("/commands")
def commands() -> dict[str, str]:
    return {"sms_commands": HELP_TEXT}


@app.post("/sms/webhook")
async def sms_webhook(request: Request) -> dict[str, Any]:
    form_data = await request.form()
    signature = request.headers.get("x-sg-signature")

    if "messages" in form_data:
        messages_raw = str(form_data["messages"])
        verify_gateway_signature(messages_raw, signature)
        try:
            messages = json.loads(messages_raw)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=400, detail="Invalid messages JSON") from exc

        processed = 0
        failed = 0
        for item in messages:
            phone = item.get("number")
            text = item.get("message")
            if not phone or text is None:
                failed += 1
                continue
            try:
                process_incoming_sms(phone, str(text))
                processed += 1
            except Exception:
                failed += 1
                logger.exception("Could not process inbound SMS")

        return {"status": "received", "processed": processed, "failed": failed}

    if "ussdRequest" in form_data:
        ussd_raw = str(form_data["ussdRequest"])
        verify_gateway_signature(ussd_raw, signature)
        logger.info("USSD request received: %s", ussd_raw)
        return {"status": "received", "type": "ussd"}

    raise HTTPException(status_code=400, detail="No messages or ussdRequest field found")


@app.post("/sms/incoming")
def simulate_incoming_sms(payload: IncomingSMSTest, request: Request) -> dict[str, Any]:
    require_admin(request)
    if payload.send_reply:
        reply = process_incoming_sms(payload.phone_number, payload.message)
    else:
        reply = build_sms_reply(payload.phone_number, payload.message)
    return {"reply": reply}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
