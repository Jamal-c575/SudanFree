import requests

BASE_URL = "http://localhost:5001"
TIMEOUT = 30

def test_get_user_profile_by_userid():
    # Test data for sign in
    email = "testuser@getuser.com"
    password = "StrongPass!23"

    # 1. Sign in with email to get auth token and userId
    signin_url = f"{BASE_URL}/auth/signInWithEmail"
    signin_payload = {
        "email": email,
        "password": password
    }
    try:
        signin_resp = requests.post(signin_url, json=signin_payload, timeout=TIMEOUT)
        assert signin_resp.status_code == 200, f"SignIn failed with status {signin_resp.status_code}"
        signin_data = signin_resp.json()
        # Assuming response has keys: 'token' and 'user' with 'uid'
        token = signin_data.get("token")
        user = signin_data.get("user")
        assert token, "Auth token not returned in sign-in response"
        assert user and "uid" in user, "User ID not found in sign-in response"
        user_id = user["uid"]

        # 2. Use token to get user profile by userId
        profile_url = f"{BASE_URL}/users/{user_id}"
        headers = {
            "Authorization": f"Bearer {token}"
        }
        profile_resp = requests.get(profile_url, headers=headers, timeout=TIMEOUT)
        assert profile_resp.status_code == 200, f"Get user profile failed with status {profile_resp.status_code}"
        profile_data = profile_resp.json()

        # Validate that response conforms to expected UserModel structure minimally
        # Required fields based on typical UserModel might be id, email, name etc.
        assert isinstance(profile_data, dict), "User profile response is not a JSON object"
        assert "id" in profile_data and profile_data["id"] == user_id, "Returned user id mismatch"
        assert "email" in profile_data and profile_data["email"] == email, "Returned user email mismatch"

    finally:
        # Cleanup: no resource created to delete since this test only signs in existing user
        pass

test_get_user_profile_by_userid()