import requests
import uuid

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

# Test data for auth and users (should be replaced with valid existing freelancer and client credentials)
FREELANCER_EMAIL = "freelancer@example.com"
FREELANCER_PASSWORD = "StrongPassword123!"
CLIENT_EMAIL = "client@example.com"
CLIENT_PASSWORD = "StrongPassword123!"

def sign_in_with_email(email, password):
    url = f"{BASE_URL}/auth/signInWithEmail"
    payload = {"email": email, "password": password}
    resp = requests.post(url, json=payload, timeout=TIMEOUT)
    resp.raise_for_status()
    data = resp.json()
    assert "token" in data or "authToken" in data or "accessToken" in data or isinstance(data, dict)
    # Auth token extraction logic based on known response keys:
    token = data.get("token") or data.get("authToken") or data.get("accessToken") or data.get("user") and data["user"].get("token")
    if not token:
        # fallback: maybe the entire response is token (string)
        if isinstance(data, str):
            token = data
        else:
            token = None
    assert token is not None, "Auth token not found in login response"
    return token

def create_job(token):
    url = f"{BASE_URL}/jobs"
    job_data = {
        "title": "Test Job for Proposal " + str(uuid.uuid4()),
        "description": "This is a test job description.",
        "budget": 1500,
        "category": "testing",
        "location": "Khartoum"
    }
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    resp = requests.post(url, json=job_data, headers=headers, timeout=TIMEOUT)
    resp.raise_for_status()
    # The POST /jobs endpoint returns 200 void, no body returned
    # The job ID must be retrieved another way: get jobs or use a custom property?
    # Since response does not return jobId, query jobs to find our created job
    
    # List jobs filtered by category to find it
    params = {"category": "testing"}
    resp_list = requests.get(f"{BASE_URL}/jobs", headers=headers, params=params, timeout=TIMEOUT)
    resp_list.raise_for_status()
    jobs = resp_list.json()
    # jobs is an array of job objects, find the one matching title
    job_id = None
    for job in jobs:
        if job.get("title") == job_data["title"]:
            job_id = job.get("id") or job.get("jobId") or job.get("uid")
            break
    assert job_id is not None, "Created job ID not found"
    return job_id

def delete_job(token, job_id):
    url = f"{BASE_URL}/jobs/{job_id}"
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    resp = requests.delete(url, headers=headers, timeout=TIMEOUT)
    if resp.status_code not in (200, 204):
        resp.raise_for_status()

def test_postproposals():
    # Authenticate freelancer user to submit proposals
    freelancer_token = sign_in_with_email(FREELANCER_EMAIL, FREELANCER_PASSWORD)
    # Authenticate client user to create a job, then clean up
    client_token = sign_in_with_email(CLIENT_EMAIL, CLIENT_PASSWORD)

    headers_proposal = {"Authorization": f"Bearer {freelancer_token}"}
    headers_client = {"Authorization": f"Bearer {client_token}"}

    job_id = None
    try:
        # Client creates a job to apply to
        job_id = create_job(client_token)

        # Prepare a valid proposal for the job
        proposal_payload = {
            "jobId": job_id,
            "coverLetter": "I am very interested in this job and confident to deliver high quality work.",
            "proposedBudget": 1200,
            "timeline": "2 weeks"
        }

        # Submit proposal as freelancer
        resp = requests.post(f"{BASE_URL}/proposals", json=proposal_payload, headers=headers_proposal, timeout=TIMEOUT)
        # Expect 200 void response
        assert resp.status_code == 200
        assert resp.text == "" or resp.text == "null"
        
        # Optional: verify proposals listing for that job includes our submission
        resp_list = requests.get(f"{BASE_URL}/jobs/{job_id}/proposals", headers=headers_proposal, timeout=TIMEOUT)
        assert resp_list.status_code == 200
        proposals = resp_list.json()
        assert isinstance(proposals, list)
        # Find at least one proposal matching freelancer or coverLetter
        found = False
        for p in proposals:
            if p.get("jobId") == job_id and p.get("coverLetter") == proposal_payload["coverLetter"]:
                found = True
                break
        assert found, "Submitted proposal not found in proposals list"

    finally:
        # Clean up: delete the created job
        if job_id:
            delete_job(client_token, job_id)

test_postproposals()