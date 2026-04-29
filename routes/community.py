from fastapi import APIRouter, HTTPException, Query
from database import get_db
from pydantic import BaseModel
import sqlite3

router = APIRouter(prefix="/community", tags=["Community"])

class MessageCreate(BaseModel):
    message: str

@router.get("/{group_id}/messages")
def get_messages(group_id: str):
    with get_db() as db:
        messages = db.execute("""
            SELECT m.id, m.group_id, m.sender_nic, m.message, m.created_at, 
                   u.first_name, u.last_name 
            FROM community_messages m
            JOIN users u ON m.sender_nic = u.nic
            WHERE m.group_id = ?
            ORDER BY m.created_at ASC
        """, (group_id,)).fetchall()
        return [dict(m) for m in messages]

@router.post("/{group_id}/messages")
def post_message(group_id: str, sender_nic: str = Query(...), msg: MessageCreate = None):
    with get_db() as db:
        if not msg or not msg.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
            
        cursor = db.execute(
            """
            INSERT INTO community_messages(group_id, sender_nic, message)
            VALUES (?, ?, ?)
            """,
            (group_id, sender_nic, msg.message.strip())
        )
        db.commit()
        return {"id": cursor.lastrowid, "message": "Message posted"}
