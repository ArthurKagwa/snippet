# Snippet website

Cloudflare Workers serves the static files in `public/` using `wrangler.jsonc`.

## Security contact

`public/.well-known/security.txt` publishes the existing support inbox for
private vulnerability reports. Review the contact and renew `Expires` before
October 23, 2027. Keep the expiry less than one year ahead when renewing.

Deploy the website from this directory:

```sh
pnpm dlx wrangler deploy
```

Then verify both domains return HTTP 200, a `text/plain` content type, and the
expected security contact:

```sh
curl -i https://snippetverses.app/.well-known/security.txt
curl -i https://www.snippetverses.app/.well-known/security.txt
```

Cloudflare also offers [managed security.txt](https://developers.cloudflare.com/security-center/infrastructure/security-file/)
under **Security > Settings > Web application exploits > Security.txt**. If using
that option, configure the same contact, expiry, language, and canonical URLs;
keep the managed configuration and this file in sync.

## Cloudflare bot settings

These settings are configured on the `snippetverses.app` zone in Cloudflare,
separately from the Workers deployment:

1. Open **Security > Settings** and filter by **Bot traffic**.
2. Turn on [Bot Fight Mode](https://developers.cloudflare.com/bots/get-started/bot-fight-mode/).
3. Turn on [AI Labyrinth](https://developers.cloudflare.com/bots/additional-configurations/ai-labyrinth/).
4. Verify both toggles remain on after refreshing the dashboard.
5. Check the website and review **Security > Analytics > Events** for unexpected
   challenges after enabling the settings.

Bot Fight Mode applies across the domain and can challenge API clients or mobile
apps. Check any clients using this domain; WAF skip rules cannot bypass Bot Fight
Mode. AI Labyrinth injects hidden crawler honeypot links into HTML responses.
