from __future__ import annotations

import os
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests

_ENV_FILE = Path(__file__).with_name(".env")


def _load_local_env_file() -> None:
    if not _ENV_FILE.exists():
        return

    for raw_line in _ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_local_env_file()

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
DEFAULT_COUNTRY_CODE = os.getenv("DEFAULT_COUNTRY_CODE", "+94")

_API_KEY = SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def is_configured() -> bool:
    return bool(SUPABASE_URL and _API_KEY)


def _headers(prefer: str = "return=representation") -> dict[str, str]:
    return {
        "apikey": _API_KEY,
        "Authorization": f"Bearer {_API_KEY}",
        "Content-Type": "application/json",
        "Prefer": prefer,
    }


def _request(
    method: str,
    table: str,
    *,
    params: dict[str, Any] | None = None,
    json: Any | None = None,
    prefer: str = "return=representation",
    timeout: int = 20,
) -> Any:
    if not is_configured():
        raise RuntimeError("Supabase is not configured.")

    response = requests.request(
        method,
        f"{SUPABASE_URL}/rest/v1/{table}",
        headers=_headers(prefer),
        params=params,
        json=json,
        timeout=timeout,
    )
    response.raise_for_status()
    if not response.content:
        return None
    return response.json()


def _normalize_phone(phone_number: str) -> str:
    phone = re.sub(r"[\s().-]+", "", str(phone_number or ""))
    if not phone:
        return phone
    if phone.startswith("00"):
        return f"+{phone[2:]}"
    if phone.startswith("+"):
        return phone

    country = DEFAULT_COUNTRY_CODE
    country_digits = country.lstrip("+")
    if phone.startswith("0") and country:
        return f"{country}{phone[1:]}"
    if phone.startswith(country_digits):
        return f"+{phone}"
    return f"+{phone}"


def _phone_variants(phone_number: str) -> list[str]:
    normalized = _normalize_phone(phone_number)
    variants = [normalized]
    digits = normalized.lstrip("+")
    if digits:
        variants.append(digits)
    if normalized.startswith(DEFAULT_COUNTRY_CODE):
        variants.append(f"0{normalized[len(DEFAULT_COUNTRY_CODE):]}")

    clean: list[str] = []
    for value in variants:
        if value and value not in clean:
            clean.append(value)
    return clean


def insert_sms_message(sms_data: dict[str, Any]) -> None:
    _request("POST", "sms_messages", json=sms_data)


def log_incoming_sms(phone_number: str, message: str) -> None:
    insert_sms_message(
        {
            "id": f"in_{uuid.uuid4().hex}",
            "phone_number": _normalize_phone(phone_number),
            "message": message,
            "direction": "incoming",
            "status": "received",
            "created_at": _utc_now(),
            "sent_at": None,
        }
    )


def find_user_by_phone(phone_number: str) -> dict[str, Any] | None:
    for phone in _phone_variants(phone_number):
        rows = _request(
            "GET",
            "users",
            params={"phone": f"eq.{phone}", "select": "*", "limit": 1},
        )
        if rows:
            return rows[0]
    return None


def find_user_by_nic(nic: str) -> dict[str, Any] | None:
    if not nic:
        return None
    rows = _request(
        "GET",
        "users",
        params={"nic": f"eq.{nic.upper()}", "select": "*", "limit": 1},
    )
    return rows[0] if rows else None


def upsert_user(user_data: dict[str, Any]) -> None:
    payload = dict(user_data)
    payload["nic"] = str(payload["nic"]).upper()
    payload["updated_at"] = _utc_now()
    _request(
        "POST",
        "users",
        params={"on_conflict": "nic"},
        json=payload,
        prefer="resolution=merge-duplicates,return=representation",
    )


def update_user_by_nic(nic: str, changes: dict[str, Any]) -> None:
    payload = {**changes, "updated_at": _utc_now()}
    _request(
        "PATCH",
        "users",
        params={"nic": f"eq.{nic.upper()}"},
        json=payload,
    )


def insert_job(job_data: dict[str, Any]) -> str:
    allowed = {
        "id",
        "title",
        "description",
        "employer_nic",
        "category",
        "location",
        "status",
        "required_skills",
        "applied_worker_ids",
        "accepted_worker_ids",
        "payments",
        "created_at",
        "updated_at",
    }
    payload = {key: value for key, value in job_data.items() if key in allowed}
    result = _request("POST", "jobs", json=payload)
    if isinstance(result, list) and result:
        return str(result[0]["id"])
    return str(payload.get("id", ""))


def update_job_by_id(job_id: str, changes: dict[str, Any]) -> None:
    payload = {**changes, "updated_at": changes.get("updated_at", _utc_now())}
    _request("PATCH", "jobs", params={"id": f"eq.{job_id}"}, json=payload)


def find_job_by_id(job_id: str) -> dict[str, Any] | None:
    rows = _request(
        "GET",
        "jobs",
        params={"id": f"eq.{job_id}", "select": "*", "limit": 1},
    )
    return rows[0] if rows else None


def find_job_by_prefix(prefix: str) -> dict[str, Any] | None:
    needle = str(prefix or "").strip().lower()
    if not needle:
        return None

    if len(needle) >= 32:
        exact = find_job_by_id(needle)
        if exact:
            return exact

    rows = _request(
        "GET",
        "jobs",
        params={"select": "*", "order": "created_at.desc", "limit": 300},
    )
    for row in rows or []:
        if str(row.get("id", "")).lower().startswith(needle):
            return row
    return None


def list_open_jobs(area: str = "", limit: int = 20) -> list[dict[str, Any]]:
    params: dict[str, Any] = {
        "status": "eq.open",
        "select": "*",
        "order": "created_at.desc",
        "limit": max(limit, 1),
    }
    if area:
        params["location"] = f"ilike.*{area}*"
    return list(_request("GET", "jobs", params=params) or [])


def find_open_jobs_for_area(area: str) -> list[dict[str, Any]]:
    return list_open_jobs(area=area, limit=20)


def list_jobs_by_employer(employer_nic: str, limit: int = 10) -> list[dict[str, Any]]:
    return list(
        _request(
            "GET",
            "jobs",
            params={
                "employer_nic": f"eq.{employer_nic.upper()}",
                "select": "*",
                "order": "created_at.desc",
                "limit": max(limit, 1),
            },
        )
        or []
    )


def add_application(job_id: str, worker_nic: str) -> None:
    _request(
        "POST",
        "applications",
        json={
            "job_id": job_id,
            "worker_nic": worker_nic.upper(),
            "status": "applied",
            "applied_at": _utc_now(),
        },
    )


def application_exists(job_id: str, worker_nic: str) -> bool:
    return bool(find_application(job_id, worker_nic))


def find_application(job_id: str, worker_nic: str) -> dict[str, Any] | None:
    rows = _request(
        "GET",
        "applications",
        params={
            "job_id": f"eq.{job_id}",
            "worker_nic": f"eq.{worker_nic.upper()}",
            "select": "*",
            "limit": 1,
        },
    )
    return rows[0] if rows else None


def list_applications_for_job(job_id: str) -> list[dict[str, Any]]:
    applications = list(
        _request(
            "GET",
            "applications",
            params={
                "job_id": f"eq.{job_id}",
                "select": "*",
                "order": "applied_at.desc",
            },
        )
        or []
    )
    for application in applications:
        application["worker"] = find_user_by_nic(application["worker_nic"])
    return applications


def set_application_status(job_id: str, worker_nic: str, status: str) -> None:
    _request(
        "PATCH",
        "applications",
        params={"job_id": f"eq.{job_id}", "worker_nic": f"eq.{worker_nic.upper()}"},
        json={"status": status},
    )


def update_job_worker_lists(job_id: str) -> None:
    applications = list_applications_for_job(job_id)
    applied_worker_ids = [
        application["worker_nic"]
        for application in applications
        if application.get("status") in {"applied", "accepted"}
    ]
    accepted_worker_ids = [
        application["worker_nic"]
        for application in applications
        if application.get("status") == "accepted"
    ]
    update_job_by_id(
        job_id,
        {
            "applied_worker_ids": applied_worker_ids,
            "accepted_worker_ids": accepted_worker_ids,
        },
    )

