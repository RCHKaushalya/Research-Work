import os
import re
from pathlib import Path
from typing import Any

import requests

def load_env_file() -> None:
    env_file = Path(__file__).resolve().parent.parent / ".env"
    if not env_file.exists():
        return
    for raw_line in env_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))

load_env_file()

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://your-project.supabase.co")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY") or os.getenv("SUPABASE_KEY") or ""
SMS_GATEWAY_URL = os.getenv("SMS_GATEWAY_URL", "https://app.sms-gateway.app/services/send.php")
SMS_GATEWAY_API_KEY = os.getenv("SMS_GATEWAY_API_KEY", "")
SMS_GATEWAY_DEVICES = os.getenv("SMS_GATEWAY_DEVICES", "10959|1")
DEFAULT_COUNTRY_CODE = os.getenv("DEFAULT_COUNTRY_CODE", "+94")

def api_headers(prefer_representation: bool = False) -> dict:
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json",
    }
    if prefer_representation:
        headers["Prefer"] = "return=representation"
    return headers


def normalize_phone(phone_number: str) -> str:
    phone = re.sub(r"[\s().-]+", "", str(phone_number or ""))
    if not phone:
        return phone
    if phone.startswith("+"):
        return phone
    if phone.startswith("0"):
        return f"{DEFAULT_COUNTRY_CODE}{phone[1:]}"
    if phone.startswith(DEFAULT_COUNTRY_CODE.lstrip("+")):
        return f"+{phone}"
    return f"+{phone}"


def send_sms_via_gateway(phone_number: str, message: str, timeout: int = 10) -> dict[str, Any]:
    if not SMS_GATEWAY_API_KEY:
        raise RuntimeError("SMS_GATEWAY_API_KEY is not configured in Employee Management System/.env")

    response = requests.get(
        SMS_GATEWAY_URL,
        params={
            "key": SMS_GATEWAY_API_KEY,
            "number": normalize_phone(phone_number),
            "message": message,
            "devices": SMS_GATEWAY_DEVICES,
            "type": "sms",
            "prioritize": "0",
        },
        timeout=timeout,
    )
    response.raise_for_status()
    payload = response.json()
    if not payload.get("success"):
        raise RuntimeError(str(payload.get("error") or payload))
    return payload
