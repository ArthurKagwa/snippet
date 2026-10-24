// Handles Firebase Auth email links (the project's custom action URL):
// ?mode=resetPassword|verifyEmail|verifyAndChangeEmail|recoverEmail
//  &oobCode=...&apiKey=...
// Talks to the Identity Toolkit REST API with the key the link carries.
(() => {
  const q = new URLSearchParams(location.search);
  const mode = q.get('mode');
  const code = q.get('oobCode');
  const key = q.get('apiKey');
  // Local testing against the Auth emulator: ?emulator=127.0.0.1:9099
  const emulator = /^(localhost|127\.0\.0\.1)$/.test(location.hostname) && q.get('emulator');
  const api = `${emulator ? `http://${emulator}/` : 'https://'}identitytoolkit.googleapis.com/v1`;

  const $ = (id) => document.getElementById(id);
  const card = document.querySelector('.auth-card');

  const errors = {
    EXPIRED_OOB_CODE: 'This link has expired.',
    INVALID_OOB_CODE: 'This link has already been used or is not valid.',
    USER_DISABLED: 'This account has been disabled.',
    USER_NOT_FOUND: 'We could not find this account. It may have been deleted.',
    WEAK_PASSWORD: 'Choose a stronger password.',
    TOO_MANY_ATTEMPTS_TRY_LATER: 'Too many attempts. Wait a few minutes and try again.',
  };
  const retry = 'Open Snippet and ask for a new email.';

  async function call(path, body) {
    const res = await fetch(`${api}/${path}?key=${encodeURIComponent(key)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const reason = String(data.error?.message || 'UNKNOWN').split(/[ :]/)[0];
      throw Object.assign(new Error(reason), { reason });
    }
    return data;
  }

  function show({ pill, title, message, state = 'done' }) {
    card.dataset.state = state;
    if (pill) $('pill').textContent = pill;
    $('title').textContent = title;
    $('message').replaceChildren(...message);
    document.title = `${title} · Snippet Verses`;
  }

  // Message parts: strings, or {strong: text} for a bold run.
  const parts = (...items) => items.map((i) => {
    if (typeof i === 'string') return document.createTextNode(i);
    const b = document.createElement('strong');
    b.textContent = i.strong;
    return b;
  });

  function fail(err, fallback) {
    const known = errors[err.reason];
    const expired = err.reason === 'EXPIRED_OOB_CODE' || err.reason === 'INVALID_OOB_CODE';
    show({
      pill: 'LINK PROBLEM',
      title: expired ? 'Link expired' : 'Something went wrong',
      message: parts(known || fallback, ' ', expired ? retry : 'Try the link again in a moment.'),
      state: 'error',
    });
    if (!known) console.error(err);
  }

  function action(label, run) {
    const b = $('secondary');
    b.textContent = label;
    b.hidden = false;
    $('actions').hidden = false;
    b.onclick = async () => {
      b.disabled = true;
      try { await run(); } catch (e) { fail(e, 'We could not finish that.'); }
      b.hidden = true;
    };
  }

  async function verifyEmail() {
    await call('accounts:update', { oobCode: code });
    show({
      pill: 'ALL SET',
      title: 'Email verified',
      message: parts('Go back to Snippet and tap ', { strong: 'I’ve verified my email' }, '. Your cards will start syncing.'),
    });
  }

  async function changeEmail() {
    const res = await call('accounts:update', { oobCode: code });
    show({
      pill: 'ALL SET',
      title: 'Email changed',
      message: parts('You now sign in to Snippet with ', { strong: res.email || 'your new email' }, '.'),
    });
  }

  async function recoverEmail() {
    const info = await call('accounts:resetPassword', { oobCode: code });
    await call('accounts:update', { oobCode: code });
    show({
      pill: 'RESTORED',
      title: 'Email restored',
      message: parts('Your sign-in email is back to ', { strong: info.email }, '. If you didn’t ask for the change, reset your password too.'),
    });
    action('Send a password reset email', async () => {
      await call('accounts:sendOobCode', { requestType: 'PASSWORD_RESET', email: info.email });
      show({ title: 'Check your inbox', message: parts('We sent a reset link to ', { strong: info.email }, '.') });
    });
  }

  const rules = {
    length: (p) => p.length >= 8,
    case: (p) => /[A-Z]/.test(p) && /[a-z]/.test(p),
    number: (p) => /[0-9]/.test(p),
  };

  async function resetPassword() {
    const { email } = await call('accounts:resetPassword', { oobCode: code });
    show({ pill: 'NEW PASSWORD', title: 'Choose a new password', message: parts('For ', { strong: email }, '.'), state: 'form' });
    const form = $('reset');
    const pw = $('password');
    const confirm = $('confirm');
    const error = $('form-error');
    form.hidden = false;
    pw.focus();

    const tick = () => {
      for (const li of form.querySelectorAll('[data-rule]')) {
        li.classList.toggle('met', rules[li.dataset.rule](pw.value));
      }
    };
    pw.addEventListener('input', tick);
    $('show').addEventListener('click', (e) => {
      const hidden = pw.type === 'password';
      pw.type = confirm.type = hidden ? 'text' : 'password';
      e.currentTarget.textContent = hidden ? 'Hide' : 'Show';
    });

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const problem = !Object.values(rules).every((r) => r(pw.value))
        ? 'Choose a password that ticks every point above.'
        : confirm.value !== pw.value ? 'The passwords do not match.' : null;
      error.hidden = !problem;
      error.textContent = problem || '';
      if (problem) return;
      $('save').disabled = true;
      try {
        await call('accounts:resetPassword', { oobCode: code, newPassword: pw.value });
        form.hidden = true;
        show({ pill: 'ALL SET', title: 'Password updated', message: parts('Sign in to Snippet with ', { strong: email }, ' and your new password.') });
      } catch (err) {
        $('save').disabled = false;
        if (err.reason === 'WEAK_PASSWORD') {
          error.hidden = false;
          error.textContent = errors.WEAK_PASSWORD;
        } else {
          form.hidden = true;
          fail(err, 'We could not save your password.');
        }
      }
    });
  }

  const handlers = { verifyEmail, resetPassword, recoverEmail, verifyAndChangeEmail: changeEmail };
  const run = handlers[mode];
  if (!run || !code || !key) {
    show({ pill: 'LINK PROBLEM', title: 'This link is incomplete', message: parts('Open the newest email from Snippet and tap its button again.'), state: 'error' });
    return;
  }
  run().catch((e) => fail(e, 'We could not check this link.'));
})();
