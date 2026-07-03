import requests

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_postposts():
    # Step 1: Sign up a new user to get a valid token
    signup_url = f"{BASE_URL}/auth/signUpWithEmail"
    signin_url = f"{BASE_URL}/auth/signInWithEmail"
    posts_url = f"{BASE_URL}/posts"
    signout_url = f"{BASE_URL}/auth/signOut"

    email = "testuser_postposts@example.com"
    password = "TestPassword123!"

    try:
        # Sign up user (ignore if already exists)
        signup_payload = {"email": email, "password": password}
        signup_resp = requests.post(signup_url, json=signup_payload, timeout=TIMEOUT)
        if signup_resp.status_code not in (200, 400):
            signup_resp.raise_for_status()

        # Sign in user to get token
        signin_payload = {"email": email, "password": password}
        signin_resp = requests.post(signin_url, json=signin_payload, timeout=TIMEOUT)
        assert signin_resp.status_code == 200, f"SignIn failed with status {signin_resp.status_code}"
        signin_data = signin_resp.json()
        token = signin_data.get("token") or signin_data.get("authToken") or signin_data.get("accessToken")
        assert token, "Auth token not found in signin response"

        headers = {"Authorization": f"Bearer {token}"}

        # Step 2: Create a new social post with valid content
        post_payload = {
            "content": "This is a test post content from TC007.",
            "imageUrls": ["https://example.com/image1.jpg"],
            "videoUrl": ""
        }
        post_resp = requests.post(posts_url, json=post_payload, headers=headers, timeout=TIMEOUT)
        assert post_resp.status_code == 200, f"Post creation failed with status {post_resp.status_code}"
        # Response is void (empty body) expected, so no JSON assertion

    finally:
        # Sign out the user to clean up session
        try:
            if 'token' in locals() and token:
                requests.post(signout_url, headers={"Authorization": f"Bearer {token}"}, timeout=TIMEOUT)
        except Exception:
            pass

test_postposts()