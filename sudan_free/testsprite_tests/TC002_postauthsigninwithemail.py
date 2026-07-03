import requests

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_post_auth_signin_with_email():
    signup_url = f"{BASE_URL}/auth/signUpWithEmail"
    signin_url = f"{BASE_URL}/auth/signInWithEmail"
    test_email = "testuser_tc002@example.com"
    test_password = "StrongPassword!123"

    # Step 1: Register the user to ensure valid credentials are available
    signup_payload = {
        "email": test_email,
        "password": test_password
    }
    try:
        signup_resp = requests.post(signup_url, json=signup_payload, timeout=TIMEOUT)
        assert signup_resp.status_code == 200, f"Sign up failed with status {signup_resp.status_code}: {signup_resp.text}"
        signup_data = signup_resp.json()
        assert "user" in signup_data or "uid" in signup_data, "Signup response missing user identification"

        # Step 2: Sign in with the previously registered user credentials
        signin_payload = {
            "email": test_email,
            "password": test_password
        }
        signin_resp = requests.post(signin_url, json=signin_payload, timeout=TIMEOUT)
        assert signin_resp.status_code == 200, f"Sign in failed with status {signin_resp.status_code}: {signin_resp.text}"

        signin_data = signin_resp.json()

        # Validate response contains UserCredential and auth token
        # UserCredential is likely a user object or uid inside response data
        assert isinstance(signin_data, dict), "Sign in response is not a JSON object"
        assert ("user" in signin_data or "uid" in signin_data or "id" in signin_data), "UserCredential missing in sign in response"
        assert "token" in signin_data or "authToken" in signin_data or "accessToken" in signin_data, "Auth token missing in sign in response"

    finally:
        # Cleanup: Delete the created user if possible by signing in and calling deleteUser
        try:
            # Sign in to get auth token to delete user
            signin_resp = requests.post(signin_url, json={"email": test_email, "password": test_password}, timeout=TIMEOUT)
            if signin_resp.status_code == 200:
                signin_data = signin_resp.json()
                token = signin_data.get("token") or signin_data.get("authToken") or signin_data.get("accessToken")
                if token:
                    headers = {"Authorization": f"Bearer {token}"}
                    delete_url = f"{BASE_URL}/auth/deleteUser"
                    delete_resp = requests.delete(delete_url, headers=headers, timeout=TIMEOUT)
                    # Accept 200 or 400 requires recent login (can't do better cleanup then)
                    assert delete_resp.status_code in (200,400), f"User deletion returned unexpected status {delete_resp.status_code}"
        except Exception:
            pass

test_post_auth_signin_with_email()