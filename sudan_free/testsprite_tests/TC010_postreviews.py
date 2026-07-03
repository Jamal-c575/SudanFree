import requests
import uuid
import time

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_postreviews():
    # Test data for email sign-up and sign-in
    test_email = f"testuser_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "TestPass123!"

    headers = {"Content-Type": "application/json"}

    # Step 1: Sign up a client user (to act as reviewer)
    signup_payload = {"email": test_email, "password": test_password}
    resp = requests.post(f"{BASE_URL}/auth/signUpWithEmail", json=signup_payload, headers=headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Sign up failed: {resp.status_code} {resp.text}"
    # Extract user credentials (assuming some userId in response to use later)
    client_user_cred = resp.json()
    assert "userId" in client_user_cred or "uid" in client_user_cred, f"Sign up response missing userId: {resp.text}"
    client_user_id = client_user_cred.get("userId") or client_user_cred.get("uid")

    # Step 2: Sign in client user to get auth token
    signin_payload = {"email": test_email, "password": test_password}
    resp = requests.post(f"{BASE_URL}/auth/signInWithEmail", json=signin_payload, headers=headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Sign in failed: {resp.status_code} {resp.text}"
    sign_in_data = resp.json()
    assert "token" in sign_in_data, f"Sign in response missing token: {resp.text}"
    client_token = sign_in_data["token"]
    auth_headers = {"Authorization": f"Bearer {client_token}", "Content-Type": "application/json"}

    # Step 3: Sign up a freelancer user (to be reviewed)
    freelancer_email = f"freelancer_{uuid.uuid4().hex[:8]}@example.com"
    freelancer_password = "FreelancerPass1!"
    freelancer_signup_payload = {"email": freelancer_email, "password": freelancer_password}
    resp = requests.post(f"{BASE_URL}/auth/signUpWithEmail", json=freelancer_signup_payload, headers=headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Freelancer sign up failed: {resp.status_code} {resp.text}"
    freelancer_user_cred = resp.json()
    freelancer_user_id = freelancer_user_cred.get("userId") or freelancer_user_cred.get("uid")

    # Step 4: Sign in freelancer user to get auth token for job creation and proposals
    resp = requests.post(f"{BASE_URL}/auth/signInWithEmail", json={"email": freelancer_email, "password": freelancer_password}, headers=headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Freelancer sign in failed: {resp.status_code} {resp.text}"
    freelancer_sign_in_data = resp.json()
    freelancer_token = freelancer_sign_in_data.get("token")
    assert freelancer_token, f"Freelancer sign in token missing: {resp.text}"
    freelancer_auth_headers = {"Authorization": f"Bearer {freelancer_token}", "Content-Type": "application/json"}

    # Step 5: Client creates a job to link the review and proposal
    job_payload = {
        "title": "Test Job for Review",
        "description": "Job to test review creation and stats update",
        "budget": 500,
        "category": "testing",
        "location": "Khartoum"
    }
    # Use client token to create job
    resp = requests.post(f"{BASE_URL}/jobs", headers=auth_headers, json=job_payload, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Job creation failed: {resp.status_code} {resp.text}"

    # Step 6: Client gets job list to find the jobId or try to get it from response headers?? 
    # No indication job creation returns jobId, assuming we must GET jobs and pick latest matching
    resp = requests.get(f"{BASE_URL}/jobs", headers=auth_headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to get jobs: {resp.status_code} {resp.text}"
    jobs = resp.json()
    # Find the job by title and client user?
    job = next((j for j in jobs if j.get("title") == job_payload["title"]), None)
    assert job and "id" in job, "Created job not found in job list"
    job_id = job["id"]

    # Step 7: Freelancer submits a proposal for the job
    proposal_payload = {
        "jobId": job_id,
        "coverLetter": "I am a skilled freelancer for this job.",
        "proposedBudget": 450,
        "timeline": "2 weeks"
    }
    resp = requests.post(f"{BASE_URL}/proposals", headers=freelancer_auth_headers, json=proposal_payload, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Proposal submission failed: {resp.status_code} {resp.text}"

    # Step 8: Client retrieves proposals for the job to find the proposalId
    resp = requests.get(f"{BASE_URL}/jobs/{job_id}/proposals", headers=auth_headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to get proposals: {resp.status_code} {resp.text}"
    proposals = resp.json()
    proposal = next((p for p in proposals if p.get("freelancerId") == freelancer_user_id or p.get("userId") == freelancer_user_id), None)
    assert proposal and "id" in proposal, "Proposal by freelancer not found"
    proposal_id = proposal["id"]

    # Step 9: Client accepts the proposal (to assign freelancer to job)
    resp = requests.put(f"{BASE_URL}/proposals/{proposal_id}/status", headers=auth_headers, json={"status": "accepted"}, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to update proposal status: {resp.status_code} {resp.text}"
    resp = requests.post(f"{BASE_URL}/proposals/{proposal_id}/accept", headers=auth_headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to accept proposal: {resp.status_code} {resp.text}"

    # Step 10: Client marks job as completed (to enable review)
    resp = requests.post(f"{BASE_URL}/jobs/{job_id}/complete", headers=auth_headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to complete job: {resp.status_code} {resp.text}"

    # Step 11: Post the review for freelancer by client
    review_payload = {
        "freelancerId": freelancer_user_id,
        "rating": 5,
        "comment": "Excellent work done!",
        "jobId": job_id
    }
    resp = requests.post(f"{BASE_URL}/reviews", headers=auth_headers, json=review_payload, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to post review: {resp.status_code} {resp.text}"

    # Step 12: Validate freelancer reviews updated
    resp = requests.get(f"{BASE_URL}/users/{freelancer_user_id}/reviews", headers=auth_headers, timeout=TIMEOUT)
    assert resp.status_code == 200, f"Failed to get freelancer reviews: {resp.status_code} {resp.text}"
    reviews = resp.json()
    assert any(r.get("jobId") == job_id and r.get("rating") == 5 for r in reviews), "Posted review not found in freelancer reviews"

    # Step 13: Cleanup - delete created users and job if allowed
    # Delete freelancer user
    try:
        resp = requests.delete(f"{BASE_URL}/auth/deleteUser", headers=freelancer_auth_headers, timeout=TIMEOUT)
        # Deletion might require recent login; ignore if 400
        assert resp.status_code in (200,400), f"Freelancer delete user failed: {resp.status_code} {resp.text}"
    except Exception:
        pass

    # Delete client user
    try:
        resp = requests.delete(f"{BASE_URL}/auth/deleteUser", headers=auth_headers, timeout=TIMEOUT)
        assert resp.status_code in (200,400), f"Client delete user failed: {resp.status_code} {resp.text}"
    except Exception:
        pass

test_postreviews()