"""Exercise verification rules against a local Firestore emulator only.

Run via firebase emulators:exec --only firestore --project demo-snippet \
  'python3 tool/test_firestore_rules.py'
"""

import base64
import json
import os
import time
import urllib.error
import urllib.request


def token(uid, provider="password", verified=False):
    def encode(value):
        return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip("=")

    project = "demo-snippet"
    now = int(time.time())
    claims = {
        "aud": project, "iss": f"https://securetoken.google.com/{project}",
        "sub": uid, "user_id": uid, "iat": now, "exp": now + 3600,
        "email": "reader@example.com", "email_verified": verified,
        "firebase": {"sign_in_provider": provider, "identities": {}},
    }
    return f'{encode({"alg": "none", "typ": "JWT"})}.{encode(claims)}.'


def check(method, path, jwt, expected, data=None):
    host = os.environ["FIRESTORE_EMULATOR_HOST"]
    if not host.startswith(("127.0.0.1:", "localhost:", "[::1]:")):
        raise RuntimeError("Only a local emulator is allowed")
    url = f"http://{host}/v1/projects/demo-snippet/databases/(default)/documents/{path}"
    headers = {"Content-Type": "application/json"}
    if jwt:
        headers["Authorization"] = f"Bearer {jwt}"
    request = urllib.request.Request(
        url, method=method, headers=headers,
        data=json.dumps(data).encode() if data is not None else None,
    )
    try:
        with urllib.request.urlopen(request) as response:
            status = response.status
    except urllib.error.HTTPError as error:
        status = error.code
    assert status == expected, f"{method} {path}: expected {expected}, got {status}"


def main():
    card = {"fields": {
        "id": {"stringValue": "card"}, "text": {"stringValue": "Be still"},
        "savedAt": {"stringValue": "2026-10-21T00:00:00Z"},
    }}
    path = "users/reader/cards/card"
    pending = token("reader")
    verified = token("reader", verified=True)
    check("PATCH", path, None, 403, card)
    check("PATCH", path, pending, 403, card)
    check("PATCH", path, verified, 200, card)
    check("PATCH", path, pending, 403, card)
    check("PATCH", path, token("other", verified=True), 403, card)
    # Owners can still clean up an account that has not finished setup.
    check("GET", path, pending, 200)
    check("DELETE", path, pending, 200)
    check("PATCH", path, token("reader", "google.com", True), 200, card)
    check("DELETE", path, verified, 200)
    print("9 Firestore verification rule checks passed.")


if __name__ == "__main__":
    main()
