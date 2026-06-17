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


SUPPORTED_LANGUAGES = {"si", "ta", "en"}

TEXT: dict[str, dict[str, str]] = {
    "help": {
        "en": (
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
            "REJECT JobCode WorkerNIC\n"
            "CLOSE JobCode"
        ),
        "si": (
            "Workforce SMS විධාන:\n"
            "REG NIC සම්පූර්ණ නම\n"
            "PROFILE - පැතිකඩ බලන්න\n"
            "NAME සම්පූර්ණ නම\n"
            "AREA දිස්ත්‍රික්කය | ප්‍රදේශය\n"
            "SKILL plumbing,wiring\n"
            "POST රැකියා නම | ප්‍රදේශය | විස්තර\n"
            "JOBS - රැකියා බලන්න\n"
            "APPLY JobCode\n"
            "MYJOBS\n"
            "APPROVE JobCode WorkerNIC\n"
            "REJECT JobCode WorkerNIC\n"
            "CLOSE JobCode"
        ),
        "ta": (
            "Workforce SMS கட்டளைகள்:\n"
            "REG NIC முழு பெயர்\n"
            "PROFILE - சுயவிவரம் பார்க்க\n"
            "NAME முழு பெயர்\n"
            "AREA மாவட்டம் | பகுதி\n"
            "SKILL plumbing,wiring\n"
            "POST வேலை பெயர் | பகுதி | விபரம்\n"
            "JOBS - வேலைகள் பார்க்க\n"
            "APPLY JobCode\n"
            "MYJOBS\n"
            "APPROVE JobCode WorkerNIC\n"
            "REJECT JobCode WorkerNIC\n"
            "CLOSE JobCode"
        ),
    },
    "unregistered": {
        "en": "Please register first. Send: REG NIC Full Name",
        "si": "කරුණාකර පළමුව ලියාපදිංචි වන්න. මෙසේ යවන්න: REG NIC සම්පූර්ණ නම",
        "ta": "முதலில் பதிவு செய்யுங்கள். இப்படி அனுப்புங்கள்: REG NIC முழு பெயர்",
    },
    "register_usage": {
        "en": "Register like this: REG 991234567V Nimal Perera",
        "si": "ලියාපදිංචි වීමට: REG 991234567V Nimal Perera",
        "ta": "பதிவு செய்ய: REG 991234567V Nimal Perera",
    },
    "phone_registered": {
        "en": "This phone is already registered as NIC {nic}. Send PROFILE to view it.",
        "si": "මෙම දුරකථනය NIC {nic} ලෙස ලියාපදිංචි කර ඇත. බලන්න PROFILE යවන්න.",
        "ta": "இந்த தொலைபேசி NIC {nic} ஆக பதிவு செய்யப்பட்டுள்ளது. பார்க்க PROFILE அனுப்புங்கள்.",
    },
    "registered": {
        "en": "Registered {name}. Your PIN is {pin}. Set area: AREA Colombo | Maharagama. Add skills: SKILL plumbing,wiring.",
        "si": "{name} ලියාපදිංචි විය. ඔබේ PIN: {pin}. ප්‍රදේශය: AREA Colombo | Maharagama. කුසලතා: SKILL plumbing,wiring.",
        "ta": "{name} பதிவு செய்யப்பட்டது. உங்கள் PIN: {pin}. பகுதி: AREA Colombo | Maharagama. திறன்கள்: SKILL plumbing,wiring.",
    },
    "profile": {
        "en": "Profile: {name}\nNIC: {nic}\nArea: {area}\nSkills: {skills}\nVerified: {verified}",
        "si": "පැතිකඩ: {name}\nNIC: {nic}\nප්‍රදේශය: {area}\nකුසලතා: {skills}\nසත්‍යාපනය: {verified}",
        "ta": "சுயவிவரம்: {name}\nNIC: {nic}\nபகுதி: {area}\nதிறன்கள்: {skills}\nசரிபார்ப்பு: {verified}",
    },
    "not_set": {"en": "not set", "si": "සකසා නැත", "ta": "அமைக்கப்படவில்லை"},
    "verified_yes": {"en": "yes", "si": "ඔව්", "ta": "ஆம்"},
    "verified_pending": {"en": "pending", "si": "බලාපොරොත්තුවෙන්", "ta": "நிலுவையில்"},
    "name_usage": {
        "en": "Change name like this: NAME Nimal Perera",
        "si": "නම වෙනස් කිරීමට: NAME Nimal Perera",
        "ta": "பெயர் மாற்ற: NAME Nimal Perera",
    },
    "name_updated": {
        "en": "Name updated to {name}.",
        "si": "නම {name} ලෙස යාවත්කාලීන විය.",
        "ta": "பெயர் {name} ஆக புதுப்பிக்கப்பட்டது.",
    },
    "area_usage": {
        "en": "Set area like this: AREA Colombo | Maharagama",
        "si": "ප්‍රදේශය සකසන්න: AREA Colombo | Maharagama",
        "ta": "பகுதி அமைக்க: AREA Colombo | Maharagama",
    },
    "area_updated": {
        "en": "Area updated to {area}.",
        "si": "ප්‍රදේශය {area} ලෙස යාවත්කාලීන විය.",
        "ta": "பகுதி {area} ஆக புதுப்பிக்கப்பட்டது.",
    },
    "skill_usage": {
        "en": "Add skills like this: SKILL plumbing,wiring,driving",
        "si": "කුසලතා එක් කරන්න: SKILL plumbing,wiring,driving",
        "ta": "திறன்கள் சேர்க்க: SKILL plumbing,wiring,driving",
    },
    "skills_updated": {
        "en": "Skills updated: {skills}.",
        "si": "කුසලතා යාවත්කාලීන විය: {skills}.",
        "ta": "திறன்கள் புதுப்பிக்கப்பட்டது: {skills}.",
    },
    "post_usage": {
        "en": "Post job like this: POST Painter needed | Colombo | Paint one room tomorrow",
        "si": "රැකියාව පළ කරන්න: POST Painter needed | Colombo | Paint one room tomorrow",
        "ta": "வேலை பதிவு செய்ய: POST Painter needed | Colombo | Paint one room tomorrow",
    },
    "job_posted": {
        "en": "Job posted. Code {code}. Workers can reply APPLY {code}.",
        "si": "රැකියාව පළ විය. කේතය {code}. සේවකයන් APPLY {code} යවිය හැක.",
        "ta": "வேலை பதிவு செய்யப்பட்டது. குறியீடு {code}. தொழிலாளர்கள் APPLY {code} அனுப்பலாம்.",
    },
    "job_label": {"en": "Job", "si": "රැකියාව", "ta": "வேலை"},
    "area_unknown": {"en": "area unknown", "si": "ප්‍රදේශය නොදනී", "ta": "பகுதி தெரியவில்லை"},
    "open_jobs": {"en": "Open jobs:", "si": "විවෘත රැකියා:", "ta": "திறந்த வேலைகள்:"},
    "no_jobs": {
        "en": "No matching open jobs found now. Try JOBS Colombo or check again later.",
        "si": "ගැලපෙන විවෘත රැකියා දැන් නැත. JOBS Colombo යවන්න හෝ පසුව බලන්න.",
        "ta": "பொருந்தும் திறந்த வேலைகள் இப்போது இல்லை. JOBS Colombo அனுப்பவும் அல்லது பின்னர் பார்க்கவும்.",
    },
    "reply_apply": {
        "en": "Reply APPLY JobCode",
        "si": "අයදුම් කිරීමට APPLY JobCode යවන්න",
        "ta": "விண்ணப்பிக்க APPLY JobCode அனுப்புங்கள்",
    },
    "apply_usage": {"en": "Apply like this: APPLY JobCode", "si": "අයදුම් කරන්න: APPLY JobCode", "ta": "விண்ணப்பிக்க: APPLY JobCode"},
    "job_not_found": {"en": "Job not found.", "si": "රැකියාව හමු නොවීය.", "ta": "வேலை கிடைக்கவில்லை."},
    "job_not_found_jobs": {
        "en": "Job not found. Send JOBS to see open jobs.",
        "si": "රැකියාව හමු නොවීය. විවෘත රැකියා සඳහා JOBS යවන්න.",
        "ta": "வேலை கிடைக்கவில்லை. திறந்த வேலைகளுக்கு JOBS அனுப்புங்கள்.",
    },
    "own_job": {
        "en": "This job was posted by you. Workers can apply to it.",
        "si": "මෙම රැකියාව ඔබ පළ කළ එකකි. සේවකයන්ට අයදුම් කළ හැක.",
        "ta": "இந்த வேலை நீங்கள் பதிவு செய்தது. தொழிலாளர்கள் விண்ணப்பிக்கலாம்.",
    },
    "job_not_open": {"en": "This job is not open now.", "si": "මෙම රැකියාව දැන් විවෘත නැත.", "ta": "இந்த வேலை இப்போது திறந்ததாக இல்லை."},
    "already_applied": {
        "en": "You already applied for {title}.",
        "si": "ඔබ දැනටමත් {title} සඳහා අයදුම් කර ඇත.",
        "ta": "நீங்கள் ஏற்கனவே {title} க்கு விண்ணப்பித்துள்ளீர்கள்.",
    },
    "applied": {
        "en": "Applied for {title} ({code}). Employer will reply by SMS.",
        "si": "{title} ({code}) සඳහා අයදුම් කළා. හිමිකරු SMS මගින් පිළිතුරු දෙයි.",
        "ta": "{title} ({code}) க்கு விண்ணப்பித்தீர்கள். வேலை வழங்குநர் SMS மூலம் பதிலளிப்பார்.",
    },
    "employer_application": {
        "en": "{worker} applied for {title} ({code}). Reply APPROVE {code} {nic} or REJECT {code} {nic}.",
        "si": "{worker} {title} ({code}) සඳහා අයදුම් කළා. APPROVE {code} {nic} හෝ REJECT {code} {nic} යවන්න.",
        "ta": "{worker} {title} ({code}) க்கு விண்ணப்பித்தார். APPROVE {code} {nic} அல்லது REJECT {code} {nic} அனுப்புங்கள்.",
    },
    "no_posted_jobs": {
        "en": "You have not posted jobs yet. Use POST Title | Area | Details.",
        "si": "ඔබ තවම රැකියා පළ කර නැත. POST Title | Area | Details භාවිතා කරන්න.",
        "ta": "நீங்கள் இன்னும் வேலைகள் பதிவு செய்யவில்லை. POST Title | Area | Details பயன்படுத்துங்கள்.",
    },
    "your_jobs": {"en": "Your jobs:", "si": "ඔබේ රැකියා:", "ta": "உங்கள் வேலைகள்:"},
    "requests": {"en": "requests", "si": "ඉල්ලීම්", "ta": "கோரிக்கைகள்"},
    "reply_approve": {
        "en": "Reply APPROVE JobCode WorkerNIC",
        "si": "APPROVE JobCode WorkerNIC ලෙස පිළිතුරු දෙන්න",
        "ta": "APPROVE JobCode WorkerNIC என பதிலளிக்கவும்",
    },
    "employer_reply_usage": {
        "en": "Use: {verb} JobCode WorkerNIC",
        "si": "භාවිතා කරන්න: {verb} JobCode WorkerNIC",
        "ta": "பயன்படுத்து: {verb} JobCode WorkerNIC",
    },
    "only_owner_reply": {
        "en": "Only the job owner can reply to requests for this job.",
        "si": "මෙම රැකියාවේ ඉල්ලීම්වලට පිළිතුරු දිය හැක්කේ හිමිකරුට පමණි.",
        "ta": "இந்த வேலைக்கான கோரிக்கைகளுக்கு வேலை உரிமையாளர் மட்டுமே பதிலளிக்கலாம்.",
    },
    "worker_not_found": {
        "en": "Worker not found. Use the WorkerNIC shown in the request SMS.",
        "si": "සේවකයා හමු නොවීය. ඉල්ලීම් SMS එකේ WorkerNIC භාවිතා කරන්න.",
        "ta": "தொழிலாளர் கிடைக்கவில்லை. கோரிக்கை SMS இல் உள்ள WorkerNIC ஐ பயன்படுத்துங்கள்.",
    },
    "no_request": {
        "en": "No request found from that worker for this job.",
        "si": "මෙම රැකියාවට එම සේවකයාගෙන් ඉල්ලීමක් හමු නොවීය.",
        "ta": "இந்த வேலைக்கு அந்த தொழிலாளரிடமிருந்து கோரிக்கை இல்லை.",
    },
    "worker_accepted": {
        "en": "Good news. You are approved for {title} ({code}). Employer phone: {phone}.",
        "si": "සුභ ආරංචියක්. ඔබ {title} ({code}) සඳහා අනුමතයි. හිමිකරුගේ දුරකථන: {phone}.",
        "ta": "நல்ல செய்தி. நீங்கள் {title} ({code}) க்கு ஒப்புதல் பெற்றுள்ளீர்கள். வேலை வழங்குநர் தொலைபேசி: {phone}.",
    },
    "worker_rejected": {
        "en": "Your request for {title} was not selected.",
        "si": "{title} සඳහා ඔබේ ඉල්ලීම තෝරාගෙන නැත.",
        "ta": "{title} க்கான உங்கள் கோரிக்கை தேர்வு செய்யப்படவில்லை.",
    },
    "employer_accepted": {
        "en": "Approved {worker} for {title}.",
        "si": "{title} සඳහා {worker} අනුමත කළා.",
        "ta": "{title} க்கு {worker} ஒப்புதல் பெற்றார்.",
    },
    "employer_rejected": {
        "en": "Rejected {worker} for {title}.",
        "si": "{title} සඳහා {worker} ප්‍රතික්ෂේප කළා.",
        "ta": "{title} க்கு {worker} நிராகரிக்கப்பட்டார்.",
    },
    "close_usage": {"en": "Close job like this: CLOSE JobCode", "si": "රැකියාව වසන්න: CLOSE JobCode", "ta": "வேலை மூட: CLOSE JobCode"},
    "only_owner_close": {
        "en": "Only the job owner can close this job.",
        "si": "මෙම රැකියාව වසා දැමිය හැක්කේ හිමිකරුට පමණි.",
        "ta": "இந்த வேலையை வேலை உரிமையாளர் மட்டுமே மூட முடியும்.",
    },
    "closed": {"en": "Closed {title} ({code}).", "si": "{title} ({code}) වසා දැමුණි.", "ta": "{title} ({code}) மூடப்பட்டது."},
    "unknown": {
        "en": "Sorry, I did not understand. Send HELP for commands.",
        "si": "සමාවන්න, තේරුම් ගත නොහැක. විධාන සඳහා HELP යවන්න.",
        "ta": "மன்னிக்கவும், புரியவில்லை. கட்டளைகளுக்கு HELP அனுப்புங்கள்.",
    },
}


def language_for_user(user: dict[str, Any] | None) -> str:
    lang = str((user or {}).get("language") or "").lower()
    return lang if lang in SUPPORTED_LANGUAGES else "si"


def t(key: str, lang: str, **values: Any) -> str:
    templates = TEXT[key]
    template = templates.get(lang) or templates["si"]
    return template.format(**values)


def bilingual(key: str, **values: Any) -> str:
    return f"{t(key, 'si', **values)}\n\n{t(key, 'ta', **values)}"


def reply_text(key: str, lang: str, **values: Any) -> str:
    if lang == "both":
        return bilingual(key, **values)
    return t(key, lang, **values)


def help_text(lang: str) -> str:
    return reply_text("help", lang)


def lookup_language(phone_number: str) -> str:
    if not supabase_is_configured():
        return "both"
    try:
        user = get_user_or_reply(phone_number)
    except Exception:
        logger.exception("Could not look up SMS language for %s", phone_number)
        return "both"
    return language_for_user(user) if user else "both"


def unregistered_text() -> str:
    return bilingual("unregistered")


def get_user_or_reply(phone_number: str) -> dict[str, Any] | None:
    user = find_user_by_phone(normalize_phone(phone_number))
    return user if user else None


def handle_register(phone_number: str, body: str, lang: str) -> str:
    parts = body.split(maxsplit=1)
    if len(parts) < 2:
        return reply_text("register_usage", lang)

    phone = normalize_phone(phone_number)
    nic = parts[0].upper()
    first_name, last_name = split_name(parts[1])
    existing = find_user_by_phone(phone)

    if existing and existing.get("nic") and not str(existing["nic"]).startswith("TEMP_"):
        if str(existing["nic"]).upper() != nic:
            return reply_text("phone_registered", language_for_user(existing), nic=existing["nic"])

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
    return reply_text("registered", lang, name=first_name, pin=pin)


def handle_profile(user: dict[str, Any], lang: str) -> str:
    skills = ", ".join(user.get("skill_ids") or []) or t("not_set", lang)
    area = " / ".join(
        part for part in [user.get("district", ""), user.get("ds_area", "")] if part
    ) or t("not_set", lang)
    verified = t("verified_yes", lang) if user.get("verified") else t("verified_pending", lang)
    return t(
        "profile",
        lang,
        name=full_name(user),
        nic=user.get("nic"),
        area=area,
        skills=skills,
        verified=verified,
    )


def handle_name(user: dict[str, Any], body: str, lang: str) -> str:
    if not body:
        return t("name_usage", lang)
    first_name, last_name = split_name(body)
    update_user_by_nic(user["nic"], {"first_name": first_name, "last_name": last_name})
    return t("name_updated", lang, name=f"{first_name} {last_name}")


def handle_area(user: dict[str, Any], body: str, lang: str) -> str:
    if not body:
        return t("area_usage", lang)

    fields = [field.strip() for field in body.split("|") if field.strip()]
    if len(fields) >= 2:
        district, ds_area = fields[0], fields[1]
    else:
        parts = body.split(maxsplit=1)
        district = parts[0]
        ds_area = parts[1] if len(parts) > 1 else ""

    update_user_by_nic(user["nic"], {"district": district, "ds_area": ds_area})
    area_text = f"{district} / {ds_area}" if ds_area else district
    return t("area_updated", lang, area=area_text)


def handle_skill(user: dict[str, Any], body: str, lang: str) -> str:
    skills = parse_skills(body)
    if not skills:
        return t("skill_usage", lang)

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
    return t("skills_updated", lang, skills=", ".join(current_skills))


def handle_post_job(user: dict[str, Any], body: str, lang: str) -> str:
    fields = [field.strip() for field in body.split("|") if field.strip()]
    if len(fields) < 3:
        return t("post_usage", lang)

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
    code = job_code(job)
    return t("job_posted", lang, code=code)


def format_job(job: dict[str, Any], lang: str) -> str:
    title = job.get("title") or t("job_label", lang)
    location = job.get("location") or t("area_unknown", lang)
    return f"{job_code(job)} {title} - {location}"


def handle_jobs(user: dict[str, Any], body: str, lang: str) -> str:
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
        return t("no_jobs", lang)

    lines = [t("open_jobs", lang)]
    lines.extend(format_job(job, lang) for job in matches)
    lines.append(t("reply_apply", lang))
    return "\n".join(lines)


def handle_apply(user: dict[str, Any], body: str, lang: str) -> str:
    if not body:
        return t("apply_usage", lang)

    job = find_job_by_prefix(body.split()[0])
    if not job:
        return t("job_not_found_jobs", lang)
    if job.get("employer_nic") == user.get("nic"):
        return t("own_job", lang)
    if job.get("status") != "open":
        return t("job_not_open", lang)

    worker_nic = user["nic"]
    if application_exists(job["id"], worker_nic):
        return t("already_applied", lang, title=job.get("title") or t("job_label", lang))

    add_application(job["id"], worker_nic)
    update_job_worker_lists(job["id"])

    employer = find_user_by_nic(job.get("employer_nic", ""))
    if employer and employer.get("phone"):
        employer_lang = language_for_user(employer)
        safe_send_sms(
            employer["phone"],
            t(
                "employer_application",
                employer_lang,
                worker=full_name(user),
                title=job.get("title") or t("job_label", employer_lang),
                code=job_code(job),
                nic=worker_nic,
            ),
        )

    return t("applied", lang, title=job.get("title") or t("job_label", lang), code=job_code(job))


def handle_my_jobs(user: dict[str, Any], lang: str) -> str:
    jobs = list_jobs_by_employer(user["nic"], limit=10)
    if not jobs:
        return t("no_posted_jobs", lang)

    lines = [t("your_jobs", lang)]
    for job in jobs[:5]:
        applications = list_applications_for_job(job["id"])
        waiting = sum(1 for app in applications if app.get("status") == "applied")
        lines.append(f"{format_job(job, lang)} [{job.get('status')}] {waiting} {t('requests', lang)}")
    lines.append(t("reply_approve", lang))
    return "\n".join(lines)


def handle_employer_reply(user: dict[str, Any], body: str, status: str, lang: str) -> str:
    parts = body.split()
    if len(parts) < 2:
        verb = "APPROVE" if status == "accepted" else "REJECT"
        return t("employer_reply_usage", lang, verb=verb)

    job = find_job_by_prefix(parts[0])
    if not job:
        return t("job_not_found", lang)
    if job.get("employer_nic") != user.get("nic"):
        return t("only_owner_reply", lang)

    worker_key = parts[1].upper()
    worker = find_user_by_nic(worker_key) or find_user_by_phone(worker_key)
    if not worker:
        return t("worker_not_found", lang)

    application = find_application(job["id"], worker["nic"])
    if not application:
        return t("no_request", lang)

    set_application_status(job["id"], worker["nic"], status)
    update_job_worker_lists(job["id"])

    if status == "accepted":
        update_job_by_id(job["id"], {"status": "assigned", "updated_at": utc_now()})
        worker_lang = language_for_user(worker)
        worker_message = t(
            "worker_accepted",
            worker_lang,
            title=job.get("title") or t("job_label", worker_lang),
            code=job_code(job),
            phone=user.get("phone") or t("not_set", worker_lang),
        )
        employer_message = t(
            "employer_accepted",
            lang,
            worker=full_name(worker),
            title=job.get("title") or t("job_label", lang),
        )
    else:
        worker_lang = language_for_user(worker)
        worker_message = t(
            "worker_rejected",
            worker_lang,
            title=job.get("title") or t("job_label", worker_lang),
        )
        employer_message = t(
            "employer_rejected",
            lang,
            worker=full_name(worker),
            title=job.get("title") or t("job_label", lang),
        )

    if worker.get("phone"):
        safe_send_sms(worker["phone"], worker_message)
    return employer_message


def handle_close_job(user: dict[str, Any], body: str, lang: str) -> str:
    if not body:
        return t("close_usage", lang)

    job = find_job_by_prefix(body.split()[0])
    if not job:
        return t("job_not_found", lang)
    if job.get("employer_nic") != user.get("nic"):
        return t("only_owner_close", lang)

    update_job_by_id(job["id"], {"status": "closed", "updated_at": utc_now()})
    return t("closed", lang, title=job.get("title") or t("job_label", lang), code=job_code(job))


def build_sms_reply(phone_number: str, message: str) -> str:
    text = (message or "").strip()
    if not text:
        return help_text(lookup_language(phone_number))

    command = text.split()[0].upper()
    body = command_body(text)

    if command in {"HI", "HELLO", "HELP", "MENU", "START"}:
        return help_text(lookup_language(phone_number))

    require_supabase()

    if command in {"REG", "REGISTER"}:
        return handle_register(phone_number, body, lookup_language(phone_number))

    user = get_user_or_reply(phone_number)
    if not user:
        return unregistered_text()
    lang = language_for_user(user)

    if command == "PROFILE":
        return handle_profile(user, lang)
    if command == "NAME":
        return handle_name(user, body, lang)
    if command == "AREA":
        return handle_area(user, body, lang)
    if command in {"SKILL", "SKILLS"}:
        return handle_skill(user, body, lang)
    if command in {"POST", "JOBPOST"}:
        return handle_post_job(user, body, lang)
    if command in {"JOB", "JOBS", "FIND"}:
        return handle_jobs(user, body, lang)
    if command in {"APPLY", "YES"}:
        return handle_apply(user, body, lang)
    if command in {"MYJOBS", "MYJOB"}:
        return handle_my_jobs(user, lang)
    if command in {"APPROVE", "ACCEPT"}:
        return handle_employer_reply(user, body, "accepted", lang)
    if command in {"REJECT", "NO"}:
        return handle_employer_reply(user, body, "rejected", lang)
    if command in {"CLOSE", "DONE"}:
        return handle_close_job(user, body, lang)

    # Shorthand from job notification: "ABC123 1" means apply.
    shorthand = text.split()
    if len(shorthand) >= 2 and shorthand[1] == "1":
        return handle_apply(user, shorthand[0], lang)

    return t("unknown", lang)


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


@app.head("/")
def root_head() -> None:
    return None


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "supabase_configured": supabase_is_configured(),
        "sms_gateway_configured": bool(settings.sms_gateway_key),
        "webhook_signature_configured": bool(settings.sms_webhook_key),
    }


@app.head("/health")
def health_head() -> None:
    return None


@app.get("/commands")
def commands() -> dict[str, str]:
    return {
        "si": help_text("si"),
        "ta": help_text("ta"),
        "en": help_text("en"),
        "unregistered_default": help_text("both"),
    }


@app.post("/sms/webhook")
async def sms_webhook(request: Request) -> dict[str, Any]:
    form_data = await request.form()
    signature = request.headers.get("x-sg-signature")
    logger.info("SMS webhook received with fields: %s", list(form_data.keys()))

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
                logger.info("Processed inbound SMS from %s", phone)
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
