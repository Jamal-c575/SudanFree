import requests

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_putusersuserid():
    # Test credentials - these should be valid in the test environment
    test_email = "testuser_putprofile@example.com"
    test_password = "TestPass123!"

    headers = {"Content-Type": "application/json"}

    # Step 1: Register user (sign up) - to create resource for update
    signup_payload = {"email": test_email, "password": test_password}
    signup_resp = requests.post(f"{BASE_URL}/auth/signUpWithEmail", json=signup_payload, headers=headers, timeout=TIMEOUT)

    assert signup_resp.status_code == 200, f"SignUp failed: {signup_resp.text}"
    signup_data = signup_resp.json()
    assert "userId" in signup_data or "uid" in signup_data, "User ID missing in signUp response"
    user_id = signup_data.get("userId") or signup_data.get("uid")

    # Step 2: Sign in user to obtain auth token
    signin_payload = {"email": test_email, "password": test_password}
    signin_resp = requests.post(f"{BASE_URL}/auth/signInWithEmail", json=signin_payload, headers=headers, timeout=TIMEOUT)
    assert signin_resp.status_code == 200, f"SignIn failed: {signin_resp.text}"
    signin_data = signin_resp.json()
    assert "token" in signin_data or "authToken" in signin_data, "Auth token missing in signIn response"
    token = signin_data.get("token") or signin_data.get("authToken")
    auth_headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # Step 3: Prepare user profile update payload
    update_payload = {
        "name": "Updated Test User",
        "bio": "This is a test bio updated in TC004.",
        "skills": ["python", "testing", "api"],
        "location": "Khartoum, Sudan"
    }

    # Step 4: Send PUT request to update user profile
    try:
        put_resp = requests.put(f"{BASE_URL}/users/{user_id}", json=update_payload, headers=auth_headers, timeout=TIMEOUT)
        assert put_resp.status_code == 200, f"Updating user profile failed: {put_resp.status_code} {put_resp.text}"
        # Response 200 void expected, so no content
        assert put_resp.text == "" or put_resp.text is None, "Expected empty response body for 200 void"
    finally:
        # Cleanup: delete user account to not pollute test data
        del_resp = requests.delete(f"{BASE_URL}/auth/deleteUser", headers=auth_headers, timeout=TIMEOUT)
        # Deletion may require recent login; if failed, log but do not fail test here
        if del_resp.status_code != 200:
            print(f"Warning: Failed to delete user in cleanup: {del_resp.status_code} {del_resp.text}")

test_putusersuserid()