import requests

base_url = "http://localhost:5001"
timeout = 30

def test_postjobs():
    # Step 1: Sign in with email to get auth token
    signin_url = f"{base_url}/auth/signInWithEmail"
    signin_payload = {
        "email": "client@example.com",
        "password": "Password123!"
    }
    try:
        signin_resp = requests.post(signin_url, json=signin_payload, timeout=timeout)
        assert signin_resp.status_code == 200, f"Sign in failed with status {signin_resp.status_code}"
        signin_data = signin_resp.json()
        assert "token" in signin_data or "authToken" in signin_data or "accessToken" in signin_data, "No auth token in sign in response"
        # Determine token key
        token = signin_data.get("token") or signin_data.get("authToken") or signin_data.get("accessToken")
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    except Exception as e:
        assert False, f"Sign in failed: {e}"

    # Step 2: Post a new job
    jobs_post_url = f"{base_url}/jobs"
    job_data = {
        "title": "Backend Developer Needed",
        "description": "Looking for an experienced backend developer to build APIs.",
        "budget": 1500.00,
        "category": "development",
        "location": "Khartoum"
    }
    try:
        post_resp = requests.post(jobs_post_url, json=job_data, headers=headers, timeout=timeout)
        assert post_resp.status_code == 200, f"Job post failed with status {post_resp.status_code}, response: {post_resp.text}"
    except Exception as e:
        assert False, f"Job post request failed: {e}"

test_postjobs()