import json
from pathlib import Path
from typing import Dict, List

GROUPS_FILE = Path(__file__).resolve().parent.parent.parent / "groups.json"

def load_groups_for_employer(employer_nic: str) -> Dict[str, List[str]]:
    if not GROUPS_FILE.exists():
        return {}
    try:
        all_groups = json.loads(GROUPS_FILE.read_text(encoding="utf-8"))
        return all_groups.get(employer_nic, {})
    except Exception:
        return {}

def save_groups_for_employer(employer_nic: str, groups: Dict[str, List[str]]) -> None:
    all_groups = {}
    if GROUPS_FILE.exists():
        try:
            all_groups = json.loads(GROUPS_FILE.read_text(encoding="utf-8"))
        except Exception:
            all_groups = {}
    all_groups[employer_nic] = groups
    GROUPS_FILE.write_text(json.dumps(all_groups, indent=4), encoding="utf-8")
