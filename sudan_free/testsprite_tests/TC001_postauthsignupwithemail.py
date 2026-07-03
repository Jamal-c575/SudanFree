import requests
import uuid

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_post_auth_sign_up_with_email():
    signup_url = f"{BASE_URL}/auth/signUpWithEmail"

    # Generate unique email to avoid conflicts
    unique_email = f"testuser_{uuid.uuid4().hex[:8]}@example.com"
    password = "ValidPassword123!"

    payload = {
        "email": unique_email,
        "password": password
    }
    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(signup_url, json=payload, headers=headers, timeout=TIMEOUT)
        # Expect HTTP 200
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        # Validate response has UserCredential schema (should be a JSON object with at least uid or token)
        json_resp = response.json()
        assert isinstance(json_resp, dict), "Response is not a JSON object"
        # Assuming UserCredential includes "uid" and "email" at minimum
        assert "uid" in json_resp, "UserCredential missing 'uid'"
        assert json_resp.get("email") == unique_email, "Email in response does not match signup email"
    except requests.exceptions.RequestException as e:
        assert False, f"Request failed: {e}"

test_post_auth_sign_up_with_email()