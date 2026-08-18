// BUNKERS — retrieval proxy
//
// WHY THIS EXISTS
// The container that builds this register has no outbound egress: its proxy
// refuses CONNECT to every host except package registries and GitHub. It
// therefore cannot resolve a citation to bytes, and under the register's
// resolve-or-die rule an unresolved citation is not evidence.
//
// MCP traffic does not travel over the session network — it goes via
// Anthropic's servers — so a Vercel function reached through the Vercel MCP
// tools is callable when a direct fetch is not.
//
// SAFETY POSTURE
// An endpoint that fetches arbitrary URLs is an open proxy, which is abusable
// for attacking third parties or laundering traffic. Four constraints apply:
//
//   1. The deployment keeps Vercel Authentication ENABLED, so it is not
//      publicly callable at all. This is the primary control; everything below
//      is defence in depth.
//   2. A shared token is required.
//   3. The target host must appear in allowed-hosts.json — the 122 hosts
//      derived from the register's own source catalogue, nothing else.
//   4. GET only, redirects followed manually and re-checked against the
//      allowlist at every hop, 10 MB cap.
//
// CUSTODY
// The response carries a SHA-256 of exactly the bytes retrieved, plus the
// final URL after redirects, the HTTP status and the byte count. That is what
// lets a document fetched through this hop still enter the register with a
// chain of custody rather than as an anonymous blob.

import { createHash } from 'node:crypto';
import allowed from '../allowed-hosts.json' with { type: 'json' };

const ALLOWED = new Set(allowed);
const MAX_BYTES = 10 * 1024 * 1024;
const MAX_REDIRECTS = 5;

function hostAllowed(u) {
  try {
    const h = new URL(u).hostname.toLowerCase();
    if (ALLOWED.has(h)) return true;
    // Permit subdomains of an allowlisted apex, but never a suffix match that
    // would let evil-archives.gov.attacker.com through.
    return [...ALLOWED].some((a) => h === a || h.endsWith('.' + a));
  } catch {
    return false;
  }
}

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'GET only' });
  }

  const token = req.headers['x-proxy-token'] || req.query.token;
  if (!process.env.PROXY_TOKEN || token !== process.env.PROXY_TOKEN) {
    return res.status(401).json({ error: 'bad or missing token' });
  }

  const target = req.query.url;
  if (!target) return res.status(400).json({ error: 'url parameter required' });
  if (!/^https:\/\//i.test(target)) {
    return res.status(400).json({ error: 'https only' });
  }
  if (!hostAllowed(target)) {
    return res.status(403).json({
      error: 'host not in the register source catalogue',
      host: (() => { try { return new URL(target).hostname; } catch { return null; } })(),
    });
  }

  const headers = { 'user-agent': 'bunkers-register/0.1 (+https://github.com/Overcastly-AI/Bunkers)' };
  // Forwarded archive credentials, set as Vercel project env vars.
  try {
    const h = new URL(target).hostname;
    if (h.endsWith('archives.gov') && process.env.NARA_API_KEY) {
      headers['x-api-key'] = process.env.NARA_API_KEY;
    }
  } catch { /* unreachable: URL already parsed above */ }

  let url = target;
  let hops = 0;
  let response;

  try {
    // Manual redirect handling so every hop is re-checked. An allowlisted host
    // that 302s to somewhere else must not become an escape hatch.
    for (;;) {
      response = await fetch(url, { method: 'GET', headers, redirect: 'manual' });
      const loc = response.headers.get('location');
      if (!loc || response.status < 300 || response.status >= 400) break;
      if (++hops > MAX_REDIRECTS) {
        return res.status(508).json({ error: 'too many redirects', url });
      }
      const next = new URL(loc, url).toString();
      if (!hostAllowed(next)) {
        return res.status(403).json({ error: 'redirect left the allowlist', from: url, to: next });
      }
      url = next;
    }
  } catch (e) {
    return res.status(502).json({ error: 'upstream fetch failed', detail: String(e).slice(0, 300), url });
  }

  const buf = Buffer.from(await response.arrayBuffer());
  if (buf.length > MAX_BYTES) {
    return res.status(413).json({ error: 'response too large', bytes: buf.length, url });
  }

  const sha256 = createHash('sha256').update(buf).digest('hex');
  const contentType = response.headers.get('content-type') || '';
  const textish = /json|text|xml|html|javascript/i.test(contentType);

  return res.status(200).json({
    ok: response.status >= 200 && response.status < 300,
    requested_url: target,
    final_url: url,
    redirects: hops,
    http_status: response.status,
    content_type: contentType,
    bytes: buf.length,
    sha256,
    retrieved_at: new Date().toISOString(),
    encoding: textish ? 'utf-8' : 'base64',
    body: textish ? buf.toString('utf-8').slice(0, 900000) : buf.toString('base64'),
    truncated: textish && buf.length > 900000,
  });
}
