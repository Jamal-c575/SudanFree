import requests
import uuid

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_postpayments():
    # Step 1: Sign in as client user (create new user if needed)
    email = f"client_{uuid.uuid4().hex[:8]}@example.com"
    password = "TestPass123!"

    # Register new user (client)
    signup_resp = requests.post(
        f"{BASE_URL}/auth/signUpWithEmail",
        json={"email": email, "password": password},
        timeout=TIMEOUT,
    )
    assert signup_resp.status_code == 200, f"SignUp failed: {signup_resp.text}"
    signup_data = signup_resp.json()

    # Sign in to get token
    signin_resp = requests.post(
        f"{BASE_URL}/auth/signInWithEmail",
        json={"email": email, "password": password},
        timeout=TIMEOUT,
    )
    assert signin_resp.status_code == 200, f"SignIn failed: {signin_resp.text}"
    signin_data = signin_resp.json()
    token = signin_data.get("token") or signin_data.get("authToken") or signin_data.get("accessToken")
    assert token, "Authentication token not found in signIn response"

    headers = {"Authorization": f"Bearer {token}"}

    # Step 2: Create freelancer user to reference as freelancerId in payment
    freelancer_email = f"freelancer_{uuid.uuid4().hex[:8]}@example.com"
    freelancer_password = "TestPass123!"
    signup_resp_f = requests.post(
        f"{BASE_URL}/auth/signUpWithEmail",
        json={"email": freelancer_email, "password": freelancer_password},
        timeout=TIMEOUT,
    )
    assert signup_resp_f.status_code == 200, f"Freelancer SignUp failed: {signup_resp_f.text}"
    signin_resp_f = requests.post(
        f"{BASE_URL}/auth/signInWithEmail",
        json={"email": freelancer_email, "password": freelancer_password},
        timeout=TIMEOUT,
    )
    assert signin_resp_f.status_code == 200, f"Freelancer SignIn failed: {signin_resp_f.text}"
    signin_data_f = signin_resp_f.json()
    freelancer_token = signin_data_f.get("token") or signin_data_f.get("authToken") or signin_data_f.get("accessToken")
    assert freelancer_token, "Freelancer auth token not found"
    headers_f = {"Authorization": f"Bearer {freelancer_token}"}

    # Fetch freelancer userId by listing freelancers and matching email
    freelancers_resp = requests.get(
        f"{BASE_URL}/users/freelancers",
        headers=headers_f,
        timeout=TIMEOUT
    )
    assert freelancers_resp.status_code == 200, f"Failed to get freelancers list: {freelancers_resp.text}"
    freelancers = freelancers_resp.json()
    freelancer_id = None
    for user in freelancers:
        if user.get("email") == freelancer_email:
            freelancer_id = user.get("id") or user.get("userId")
            break
    assert freelancer_id, "Failed to get freelancer userId from freelancers list"

    # Step 3: Create a new job by client user to link payment to jobId
    job_payload = {
        "title": "Test Job " + uuid.uuid4().hex[:6],
        "description": "Job for payment test",
        "budget": 100.0,
        "category": "testing",
        "location": "remote"
    }
    job_resp = requests.post(
        f"{BASE_URL}/jobs",
        json=job_payload,
        headers=headers,
        timeout=TIMEOUT,
    )
    assert job_resp.status_code == 200, f"Job creation failed: {job_resp.text}"

    # Getting job id: the API docs do not specify the job ID in response,
    # so try to fetch list and get the newest job by title matching
    jobs_list_resp = requests.get(
        f"{BASE_URL}/jobs",
        headers=headers,
        timeout=TIMEOUT,
        params={"category": "testing"}
    )
    assert jobs_list_resp.status_code == 200, f"Jobs listing failed: {jobs_list_resp.text}"
    jobs = jobs_list_resp.json()
    job_id = None
    for job in jobs:
        if job.get("title") == job_payload["title"]:
            job_id = job.get("id") or job.get("jobId")
            break
    assert job_id, "Created job ID not found"

    try:
        # Step 4: Create payment record
        payment_payload = {
            "jobId": job_id,
            "amount": 100.0,
            "freelancerId": freelancer_id,
        }
        payment_resp = requests.post(
            f"{BASE_URL}/payments",
            json=payment_payload,
            headers=headers,
            timeout=TIMEOUT,
        )
        assert payment_resp.status_code == 200, f"Payment creation failed: {payment_resp.text}"
    finally:
        # Cleanup: Delete created job (if supported)
        del_job_resp = requests.delete(
            f"{BASE_URL}/jobs/{job_id}",
            headers=headers,
            timeout=TIMEOUT,
        )
        if del_job_resp.status_code != 200:
            # Log cleanup failure, but do not fail test here
            print(f"Warning: Failed to delete job {job_id}: {del_job_resp.status_code} {del_job_resp.text}")

        # Delete client user to cleanup (if supported)
        del_client_resp = requests.delete(
            f"{BASE_URL}/auth/deleteUser",
            headers=headers,
            timeout=TIMEOUT,
        )
        if del_client_resp.status_code != 200:
            print(f"Warning: Failed to delete client user: {del_client_resp.status_code} {del_client_resp.text}")

        # Delete freelancer user to cleanup (if supported)
        del_freelancer_resp = requests.delete(
            f"{BASE_URL}/auth/deleteUser",
            headers=headers_f,
            timeout=TIMEOUT,
        )
        if del_freelancer_resp.status_code != 200:
            print(f"Warning: Failed to delete freelancer user: {del_freelancer_resp.status_code} {del_freelancer_resp.text}")


test_postpayments()
