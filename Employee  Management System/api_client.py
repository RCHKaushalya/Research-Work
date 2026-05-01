import requests

class ApiClient:
    def __init__(self, base_url):
        self.base_url = base_url
        self.token = None

    def login(self, nic, pin):
        try:
            response = requests.post(f"{self.base_url}/auth/login", json={
                "nic": nic,
                "pin": pin
            })
            if response.status_code == 200:
                self.token = response.json()["access_token"]
                return True, "Login Successful"
            return False, response.json().get("detail", "Login Failed")
        except Exception as e:
            return False, str(e)

    def get_headers(self):
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}

    def get_my_posted_jobs(self):
        try:
            # We use the existing endpoint or a new admin-like one if needed
            # For this app, we'll fetch jobs where current user is employer
            response = requests.get(f"{self.base_url}/jobs/posted", headers=self.get_headers())
            return response.json() if response.status_code == 200 else []
        except:
            return []

    def get_job_applications(self, job_id):
        # We might need an endpoint to get applicants for a specific job
        # For now we'll assume the backend has /jobs/{id}/applications
        try:
            response = requests.get(f"{self.base_url}/jobs/{job_id}/applications", headers=self.get_headers())
            return response.json() if response.status_code == 200 else []
        except:
            return []

    def update_job_status(self, job_id, status, worker_id=None):
        try:
            payload = {"status": status}
            if worker_id:
                payload["assigned_worker_id"] = worker_id
            response = requests.put(f"{self.base_url}/jobs/{job_id}/status", json=payload, headers=self.get_headers())
            return response.status_code == 200
        except:
            return False
