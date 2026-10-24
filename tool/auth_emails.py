"""Build and publish Snippet's Firebase Auth emails and action page URL.

Colours and fonts come from the :root tokens in site/public/styles.css, so
the emails stay on brand when the site's tokens change.

  python3 tool/auth_emails.py logo              # draw site/public/email-logo.png
  python3 tool/auth_emails.py preview OUT_DIR   # write rendered HTML files
  python3 tool/auth_emails.py publish           # update Firebase Auth

Mail apps rarely load web fonts, so the header uses email-logo.png (the
arch mark and the Syne wordmark) from the deployed site. Run `logo` after
changing the brand tokens, then deploy the site.

publish needs `gcloud auth login` as a project owner. It sets the three
email templates, points action links at https://snippetverses.app/auth/action
and adds snippetverses.app to the authorized domains.
"""

import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
EMAILS = ROOT / "site" / "emails"
PROJECT = "snippet-79ab2"
CONFIG_URL = f"https://identitytoolkit.googleapis.com/admin/v2/projects/{PROJECT}/config"
ACTION_URL = "https://snippetverses.app/auth/action"
DOMAINS = ["snippetverses.app", "www.snippetverses.app"]
LOGO = ROOT / "site" / "public" / "email-logo.png"
LOGO_HEIGHT = 32  # CSS pixels in the email; the PNG is drawn at 3x
SAMPLE = {
    "%LINK%": "https://snippetverses.app/auth/action?mode=resetPassword&oobCode=SAMPLE",
    "%EMAIL%": "reader@example.com",
    "%NEW_EMAIL%": "new.reader@example.com",
}


def tokens():
    css = (ROOT / "site" / "public" / "styles.css").read_text()
    root = re.search(r":root\s*{(.*?)}", css, re.S).group(1)
    return dict(re.findall(r"--([\w-]+):\s*([^;]+);", root))


def logo():
    from PIL import Image, ImageDraw, ImageFont

    values = tokens()
    stone, lime = values["stone"].strip(), values["lime"].strip()
    scale = LOGO_HEIGHT * 3 / 80  # the mark's viewBox is 64 x 80
    font = ImageFont.truetype(str(ROOT / "assets" / "fonts" / "Syne-Variable.ttf"), round(62 * scale))
    font.set_variation_by_axes([800])
    word, gap, tracking = "snippet", round(24 * scale), -0.04 * font.size
    width = sum(font.getlength(c) + tracking for c in word) - tracking
    image = Image.new("RGBA", (round(64 * scale + gap + width) + 4, round(80 * scale)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Mark: an arch (half circle over a block) with a sun in its crown.
    draw.pieslice([4 * scale, 4 * scale, 60 * scale, 60 * scale], 180, 360, fill=stone)
    draw.rectangle([4 * scale, 32 * scale, 60 * scale, 80 * scale], fill=stone)
    draw.ellipse([19 * scale, 19 * scale, 45 * scale, 45 * scale], fill=lime)
    x, baseline = 64 * scale + gap, 56 * scale
    for c in word:
        draw.text((x, baseline), c, font=font, fill=stone, anchor="ls")
        x += font.getlength(c) + tracking
    image.save(LOGO)
    print(LOGO, image.size)


def logo_width():
    from PIL import Image

    w, h = Image.open(LOGO).size
    return round(w * LOGO_HEIGHT / h)


def render():
    layout = (EMAILS / "layout.html").read_text()
    values = tokens()
    out = {}
    for name, email in json.loads((EMAILS / "emails.json").read_text()).items():
        html = layout
        for field in ("pill", "title", "body", "button", "footnote"):
            html = html.replace("{{%s}}" % field, email[field])
        html = html.replace("{{logo-width}}", str(logo_width())).replace("{{logo-height}}", str(LOGO_HEIGHT))
        html = re.sub(r"{{([\w-]+)}}", lambda m: values[m.group(1)], html)
        if "{{" in html:
            sys.exit(f"{name}: unfilled placeholder")
        out[name] = {"subject": email["subject"], "body": html}
    return out


def preview(folder):
    folder = pathlib.Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    (folder / LOGO.name).write_bytes(LOGO.read_bytes())
    for name, email in render().items():
        html = email["body"]
        for key, value in SAMPLE.items():
            html = html.replace(key, value)
        # Show the local logo, since the site may not be deployed yet.
        html = html.replace("https://snippetverses.app/email-logo.png", LOGO.name)
        page = f"<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>{email['subject']}</title><body style='margin:0'>{html}"
        (folder / f"{name}.html").write_text(page)
        print(folder / f"{name}.html")


def api(method, url, body=None):
    # curl uses the system certificate store; python.org builds of Python
    # often ship without one, which breaks urllib over HTTPS.
    token = subprocess.run(
        ["gcloud", "auth", "print-access-token"], capture_output=True, text=True, check=True
    ).stdout.strip()
    cmd = [
        "curl", "-sS", "--fail-with-body", "-X", method, url,
        "-H", f"Authorization: Bearer {token}",
        "-H", f"x-goog-user-project: {PROJECT}",
        "-H", "Content-Type: application/json",
    ]
    if body is not None:
        cmd += ["--data-binary", "@-"]
    res = subprocess.run(
        cmd, input=None if body is None else json.dumps(body), capture_output=True, text=True
    )
    if res.returncode:
        sys.exit(f"{method} failed: {res.stdout or res.stderr}")
    return json.loads(res.stdout)


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
    if len(sys.argv) == 2 and sys.argv[1] == "logo":
        logo()
    elif len(sys.argv) == 3 and sys.argv[1] == "preview":
        preview(sys.argv[2])
    elif len(sys.argv) == 2 and sys.argv[1] == "publish":
        publish()
    else:
        sys.exit(__doc__)
