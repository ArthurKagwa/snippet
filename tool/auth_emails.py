"""Build and publish Snippet's Firebase Auth emails and action page URL.

Colours and fonts come from the :root tokens in site/public/styles.css, so
the emails stay on brand when the site's tokens change.

  python3 tool/auth_emails.py preview OUT_DIR   # write rendered HTML files
  python3 tool/auth_emails.py publish           # update Firebase Auth

publish needs `gcloud auth login` as a project owner. It sets the three
email templates, points action links at https://snippetverses.app/auth/action
and adds snippetverses.app to the authorized domains.
"""

import json
import pathlib
import re
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
EMAILS = ROOT / "site" / "emails"
PROJECT = "snippet-79ab2"
CONFIG_URL = f"https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config"
ACTION_URL = "https://snippetverses.app/auth/action"
DOMAINS = ["snippetverses.app", "www.snippetverses.app"]
SAMPLE = {
    "%LINK%": "https://snippetverses.app/auth/action?mode=resetPassword&oobCode=SAMPLE",
    "%EMAIL%": "reader@example.com",
    "%NEW_EMAIL%": "new.reader@example.com",
}


def tokens():
    css = (ROOT / "site" / "public" / "styles.css").read_text()
    root = re.search(r":root\s*{(.*?)}", css, re.S).group(1)
    return dict(re.findall(r"--([\w-]+):\s*([^;]+);", root))


def render():
    layout = (EMAILS / "layout.html").read_text()
    values = tokens()
    out = {}
    for name, email in json.loads((EMAILS / "emails.json").read_text()).items():
        html = layout
        for field in ("pill", "title", "body", "button", "footnote"):
            html = html.replace("{{%s}}" % field, email[field])
        html = re.sub(r"{{([\w-]+)}}", lambda m: values[m.group(1)], html)
        if "{{" in html:
            sys.exit(f"{name}: unfilled placeholder")
        out[name] = {"subject": email["subject"], "body": html}
    return out


def preview(folder):
    folder = pathlib.Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    for name, email in render().items():
        html = email["body"]
        for key, value in SAMPLE.items():
            html = html.replace(key, value)
        page = f"<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>{email['subject']}</title><body style='margin:0'>{html}"
        (folder / f"{name}.html").write_text(page)
        print(folder / f"{name}.html")


def api(method, url, body=None):
    token = subprocess.run(
        ["gcloud", "auth", "print-access-token"], capture_output=True, text=True, check=True
    ).stdout.strip()
    req = urllib.request.Request(
        url,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "x-goog-user-project": PROJECT,
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req) as res:
        return json.load(res)


def publish():
    current = api("GET", CONFIG_URL)
    domains = current.get("authorizedDomains", [])
    send = {"callbackUri": ACTION_URL}
    for name, email in render().items():
        send[name] = {
            "senderLocalPart": "noreply",
            "senderDisplayName": "Snippet",
            "replyTo": "noreply",
            "subject": email["subject"],
            "body": email["body"],
            "bodyFormat": "HTML",
        }
    mask = ["notification.sendEmail.callbackUri", "authorizedDomains"] + [
        f"notification.sendEmail.{name}" for name in send if name != "callbackUri"
    ]
    body = {
        "notification": {"sendEmail": send},
        "authorizedDomains": domains + [d for d in DOMAINS if d not in domains],
    }
    result = api("PATCH", f"{CONFIG_URL}?updateMask={','.join(mask)}", body)
    sent = result["notification"]["sendEmail"]
    print("callbackUri:", sent["callbackUri"])
    for name in send:
        if name != "callbackUri":
            print(f"{name}: {sent[name]['subject']}")
    print("authorizedDomains:", ", ".join(result["authorizedDomains"]))


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    elif len(sys.argv) == 2 and sys.argv[1] == "publish":
        publish()
    else:
        sys.exit(__doc__)
