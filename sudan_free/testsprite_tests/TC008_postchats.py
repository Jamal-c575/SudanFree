import requests
import random
import string
import time

BASE_URL = "http://localhost:5001"  # Removed trailing slash
TIMEOUT = 30


def generate_random_email():
    return "testuser_" + "".join(random.choices(string.ascii_lowercase + string.digits, k=8)) + "@example.com"


def sign_up_email(email, password):
    url = f"{BASE_URL}/auth/signUpWithEmail"
    payload = {"email": email, "password": password}
    resp = requests.post(url, json=payload, timeout=TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def sign_in_email(email, password):
    url = f"{BASE_URL}/auth/signInWithEmail"
    payload = {"email": email, "password": password}
    resp = requests.post(url, json=payload, timeout=TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def get_user_profile(user_id, token):
    url = f"{BASE_URL}/users/{user_id}"
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(url, headers=headers, timeout=TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def delete_user(token):
    url = f"{BASE_URL}/auth/deleteUser"
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.delete(url, headers=headers, timeout=TIMEOUT)
    # Can be 200 or 400 (Requires recent login), handle accordingly
    return resp


def post_chat(user2_id, token):
    url = f"{BASE_URL}/chats"
    headers = {"Authorization": f"Bearer {token}"}
    payload = {"user2Id": user2_id}
    resp = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
    return resp


def test_postchats():
    # Create two test users and authenticate to get tokens and userIds
    password = "TestPass123!"
    # User 1
    email1 = generate_random_email()
    sign_up_email(email1, password)
    signin_resp1 = sign_in_email(email1, password)
    token1 = signin_resp1.get("token")
    user1_id = signin_resp1.get("userId")
    assert token1, "User1 token missing"
    assert user1_id, "User1 userId missing"

    # User 2
    email2 = generate_random_email()
    sign_up_email(email2, password)
    signin_resp2 = sign_in_email(email2, password)
    token2 = signin_resp2.get("token")
    user2_id = signin_resp2.get("userId")
    assert token2, "User2 token missing"
    assert user2_id, "User2 userId missing"

    # Wait briefly to ensure backend consistency if needed
    time.sleep(1)

    try:
        # User1 creates or gets chat with User2
        resp1 = post_chat(user2_id, token1)
        assert resp1.status_code == 200, f"User1 chat creation/get failed: {resp1.status_code} {resp1.text}"
        chat_doc1 = resp1.json()
        assert "id" in chat_doc1, "ChatDocument missing id for User1"

        # User2 creates or gets chat with User1 (should return same chat)
        resp2 = post_chat(user1_id, token2)
        assert resp2.status_code == 200, f"User2 chat creation/get failed: {resp2.status_code} {resp2.text}"
        chat_doc2 = resp2.json()
        assert "id" in chat_doc2, "ChatDocument missing id for User2"

        # Both responses should represent the same chat (id matches)
        id1 = chat_doc1.get("id")
        id2 = chat_doc2.get("id")
        assert id1 == id2, "Chat IDs mismatch between users"

        # Additional validation on ChatDocument structure:
        # Check participants or user IDs includes both users
        participants = chat_doc1.get("participants") or chat_doc1.get("users") or []
        assert user1_id in participants and user2_id in participants, "ChatDocument participants missing users"

    finally:
        # Clean up: delete test users
        if token1:
            try:
                delete_user(token1)
            except Exception:
                pass
        if token2:
            try:
                delete_user(token2)
            except Exception:
                pass


test_postchats()
