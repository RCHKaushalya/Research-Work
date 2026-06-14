from __future__ import annotations

import os
from datetime import datetime
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
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


_load_local_env_file()

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")

_API_KEY = SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY


def is_configured() -> bool:
    return bool(SUPABASE_URL and _API_KEY)


def _headers() -> dict[str, str]:
    return {
        "apikey": _API_KEY,
        "Authorization": f"Bearer {_API_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }


def insert_sms_message(sms_data: dict[str, Any]) -> None:
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/sms_messages",
        headers=_headers(),
        json=sms_data,
        timeout=15,
    )
    response.raise_for_status()


def list_pending_sms() -> list[dict[str, Any]]:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/sms_messages",
        headers=_headers(),
        params={
            "direction": "eq.outgoing",
            "status": "eq.pending",
            "select": "*",
        },
        timeout=15,
    )
    response.raise_for_status()
    return response.json()


def mark_sms_as_sent(sms_id: str) -> None:
    response = requests.patch(
        f"{SUPABASE_URL}/rest/v1/sms_messages",
        headers=_headers(),
        params={"id": f"eq.{sms_id}"},
        json={"status": "sent", "sent_at": datetime.utcnow().isoformat() + "Z"},
        timeout=15,
    )
    response.raise_for_status()


def find_user_by_phone(phone_number: str) -> dict[str, Any] | None:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/users",
        headers=_headers(),
        params={"phone": f"eq.{phone_number}", "select": "*", "limit": 1},
        timeout=15,
    )
    response.raise_for_status()
    rows = response.json()
    return rows[0] if rows else None


def upsert_user(user_data: dict[str, Any]) -> None:
    payload = dict(user_data)
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/users",
        headers={
            **_headers(),
            "Prefer": "resolution=merge-duplicates,return=representation",
        },
        params={"on_conflict": "nic"},
        json=payload,
        timeout=15,
    )
    response.raise_for_status()


def update_user_by_nic(nic: str, changes: dict[str, Any]) -> None:
    response = requests.patch(
        f"{SUPABASE_URL}/rest/v1/users",
        headers=_headers(),
        params={"nic": f"eq.{nic.upper()}"},
        json=changes,
        timeout=15,
    )
    response.raise_for_status()


def find_open_jobs_for_area(area: str) -> list[dict[str, Any]]:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/jobs",
        headers=_headers(),
        params={
            "status": "eq.open",
            "location": f"eq.{area}",
            "select": "*",
        },
        timeout=15,
    )
    response.raise_for_status()
    return list(response.json())


def find_job_by_prefix(prefix: str) -> dict[str, Any] | None:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/jobs",
        headers=_headers(),
        params={"id": f"like.{prefix}%", "select": "*", "limit": 1},
        timeout=15,
    )
    response.raise_for_status()
    rows = response.json()
    return rows[0] if rows else None


def add_application(job_id: str, worker_nic: str) -> None:
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/applications",
        headers=_headers(),
        json={
            "job_id": job_id,
            "worker_nic": worker_nic.upper(),
            "status": "applied",
            "applied_at": datetime.utcnow().isoformat() + "Z",
        },
        timeout=15,
    )
    response.raise_for_status()


def application_exists(job_id: str, worker_nic: str) -> bool:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/applications",
        headers=_headers(),
        params={
            "job_id": f"eq.{job_id}",
            "worker_nic": f"eq.{worker_nic.upper()}",
            "select": "id",
            "limit": 1,
        },
        timeout=15,
    )
    response.raise_for_status()
    return bool(response.json())


def log_incoming_sms(phone_number: str, message: str) -> None:
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/sms_messages",
        headers=_headers(),
        json={
            "id": f"incoming_{datetime.utcnow().timestamp()}",
            "phone_number": phone_number,
            "message": message,
            "direction": "incoming",
            "status": "received",
            "created_at": datetime.utcnow().isoformat() + "Z",
            "sent_at": None,
        },
        timeout=15,
    )
    response.raise_for_status()


def list_pending_users() -> list[dict[str, Any]]:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/users",
        headers=_headers(),
        params={"verified": "eq.false", "select": "*"},
        timeout=15,
    )
    response.raise_for_status()
    return list(response.json())


def verify_user(nic: str) -> None:
    response = requests.patch(
        f"{SUPABASE_URL}/rest/v1/users",
        headers=_headers(),
        params={"nic": f"eq.{nic.upper()}"},
        json={"verified": True},
        timeout=15,
    )
    response.raise_for_status()


def list_support_queries() -> list[dict[str, Any]]:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/messages",
        headers=_headers(),
        params={"community_channel": "eq.support", "select": "*"},
        timeout=15,
    )
    response.raise_for_status()
    return list(response.json())


def respond_to_support_query(sender_nic: str, receiver_nic: str, content: str) -> None:
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/messages",
        headers=_headers(),
        json={
            "sender_nic": sender_nic.upper(),
            "receiver_nic": receiver_nic.upper(),
            "community_channel": "support",
            "content": content,
            "created_at": datetime.utcnow().isoformat() + "Z",
        },
        timeout=15,
    )
    response.raise_for_status()


def insert_job(job_data: dict[str, Any]) -> str:
    """Insert a new job into the jobs table and return the job ID"""
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/jobs",
        headers=_headers(),
        json=job_data,
        timeout=15,
    )
    response.raise_for_status()
    result = response.json()
    return result[0]["id"] if isinstance(result, list) and result else job_data.get("id")


def upsert_user_for_registration(
    phone_number: str, user_data: dict[str, Any]
) -> None:
    """Upsert a user pending registration (from Google Forms)"""
    payload = {
        **user_data,
        "phone": phone_number,
        # Generate a temporary NIC placeholder from phone
        "nic": f"TEMP_{phone_number.replace('+', '').replace('-', '')[-9:]}",
    }
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/users",
        headers={
            **_headers(),
            "Prefer": "resolution=merge-duplicates,return=representation",
        },
        params={"on_conflict": "phone"},
        json=payload,
        timeout=15,
    )
    response.raise_for_status()
