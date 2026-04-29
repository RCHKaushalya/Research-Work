from fastapi import APIRouter, Request, Form, Response, Depends, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from database import get_db
import json

router = APIRouter(tags=["Frontend"])
templates = Jinja2Templates(directory="templates")

def get_current_user(request: Request):
    user_data = request.cookies.get("user_session")
    if not user_data:
        return None
    try:
        return json.loads(user_data)
    except:
        return None

@router.get("/", response_class=HTMLResponse)
async def index(request: Request):
    user = get_current_user(request)
    if user:
        return RedirectResponse(url="/dashboard")
    return RedirectResponse(url="/login")

@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    user = get_current_user(request)
    if user:
        return RedirectResponse(url="/dashboard")
    return templates.TemplateResponse("login.html", {"request": request, "show_header": False})

@router.post("/login")
async def login(request: Request, nic: str = Form(...), pin: str = Form(...)):
    with get_db() as db:
        user = db.execute(
            """
            SELECT nic, first_name, last_name, role, district
            FROM users
            WHERE nic = ? AND pin = ?
            """,
            (nic, pin),
        ).fetchone()
        
        if not user:
            return templates.TemplateResponse("login.html", {
                "request": request, 
                "error": "Invalid NIC or PIN",
                "show_header": False
            })
        
        user_dict = dict(user)
        if user_dict['role'] not in ['admin', 'volunteer']:
             return templates.TemplateResponse("login.html", {
                "request": request, 
                "error": "Access denied. Admins and Volunteers only.",
                "show_header": False
            })

        response = RedirectResponse(url="/dashboard", status_code=303)
        response.set_cookie(key="user_session", value=json.dumps(user_dict), httponly=True)
        return response

@router.get("/logout")
async def logout():
    response = RedirectResponse(url="/login")
    response.delete_cookie("user_session")
    return response

@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    user = get_current_user(request)
    if not user:
        return RedirectResponse(url="/login")
    
    with get_db() as db:
        # Stats
        user_count = db.execute("SELECT COUNT(*) FROM users").fetchone()[0]
        job_count = db.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]
        app_count = db.execute("SELECT COUNT(*) FROM applications").fetchone()[0]
        volunteer_count = db.execute("SELECT COUNT(*) FROM users WHERE role = 'volunteer'").fetchone()[0]
        
        stats = {
            "total_users": user_count,
            "total_jobs": job_count,
            "total_applications": app_count,
            "total_volunteers": volunteer_count
        }
        
        # Registry
        users_list = db.execute("SELECT nic, first_name, last_name, role, district FROM users LIMIT 10").fetchall()
        jobs_list = db.execute("SELECT title, district, status FROM jobs LIMIT 10").fetchall()
        
        return templates.TemplateResponse("dashboard.html", {
            "request": request,
            "user": user,
            "stats": stats,
            "users": [dict(u) for u in users_list],
            "jobs": [dict(j) for j in jobs_list],
            "show_header": True
        })
