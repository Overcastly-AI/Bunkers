# Resolving a citation to bytes

**For agents.** This is how you turn an unresolved citation into evidence.

---

## The problem this solves

The container you run in has **no outbound egress**. Its proxy refuses `CONNECT` to every host except
package registries and GitHub. `WebFetch` returns `EGRESS_BLOCKED` for `catalog.archives.gov`,
`ngmdb.usgs.gov`, and essentially every archive this project depends on. `WebSearch` works, but it
returns *snippets and summaries* — never the source document.

That matters more here than in most projects, because of one rule:

> **Resolve-or-die.** An unresolved citation is not evidence.

A search result describing a CREST document is evidence that *a description exists*. It is not evidence
of the document's contents. The register grades those differently, and grades the second one at the
floor. This is not pedantry — the single most dangerous failure available to an LLM agent here is
emitting a plausible, well-formed accession number for a document that does not exist. That is
precisely the confabulation this register was built to detect.

## The mechanism

GitHub Actions runners have full internet access. So retrieval happens there, and the bytes come back
through git.

```
you append to research/harvest-queue.json
        ↓ commit and push to main
GitHub Actions fires (push trigger on that path)
        ↓ fetches, hashes, commits
research/custody/blobs/<sha256>   ← the exact bytes
research/custody/ledger.jsonl     ← url, timestamp, status, size, hash
        ↓ git pull
you read the document
```

The request and the record of the request are **the same committed object**. A citation cannot be
resolved without leaving a permanent trace of who asked and when.

## How to queue a document

Append an item to `research/harvest-queue.json`, then commit and push to `main`. The push is the
trigger; there is nothing else to call.

```json
{
  "id": "crest-raven-rock-1963",
  "url": "https://www.cia.gov/readingroom/document/cia-rdp80b01676r001200080001-2",
  "note": "Cited by Site R claim; verifying the document exists and says what is claimed"
}
```

| field | required | meaning |
|---|---|---|
| `id` | yes | Stable key. Reference it from your candidate record. |
| `url` | yes | Absolute `https://` URL. |
| `note` | no | Why you want it. Write this — a future agent reads it. |
| `headers` | no | Extra request headers. |
| `refetch` | no | `true` re-retrieves something already in the ledger. |

**The NARA API key is injected automatically** for `catalog.archives.gov` when the repository secret
`NARA_API_KEY` is set. Do not put keys in the queue file — it is public.

## Reading what came back

```bash
git pull
tail -5 research/custody/ledger.jsonl | python3 -m json.tool
```

Each ledger line:

```json
{"id":"...","url":"...","retrieved_at":"2026-08-18T11:34:17+00:00",
 "ok":true,"http_status":"200","content_type":"application/json",
 "bytes":48211,"sha256":"9f2c...","blob":"research/custody/blobs/9f2c....json"}
```

Read the blob at that path. **That is the document.** You may now cite it as resolved.

## What each outcome means for grading

| Ledger state | What you may claim |
|---|---|
| `ok: true`, 2xx | **Resolved.** You have the bytes. Cite the `sha256`. Read it before claiming what it says. |
| `http_status: 404` | The document **does not exist at that URL**. If a source cited it, that is a finding — record it. |
| `http_status: 401`/`403` | Exists but needs credentials. Not resolved. Note which key is missing. |
| `ok: false`, `curl_exit` | Transport failure. Not the archive's answer. Retry once, then record as unreachable. |
| Absent from ledger | **Never requested.** Do not claim anything about it. |

A `404` on a cited document is one of the most valuable results this register can produce. It is
evidence that a citation somewhere in the ecosystem is hollow, and hollow citations are how folklore
acquires the appearance of documentation.

## Rules

1. **Never invent an identifier.** If you do not have a URL, queue nothing and say you could not find
   one. A fabricated accession number that returns 404 wastes a fetch; one that accidentally resolves
   to an unrelated document corrupts the register.
2. **Retrieval is not reading.** A 200 means bytes arrived. It does not mean they support the claim.
   Open the blob. A real, correctly-cited document that simply does not say what was attributed to it
   is the subtlest failure in this domain, and only reading catches it.
3. **Queue what you will actually use.** These are public archives run on public money. The harvester
   already paces itself per host; do not make it work harder than the research requires.
4. **Identical bytes are one source.** Blobs are content-addressed, so two citations that resolve to
   the same `sha256` collapse to one file. When that happens it is a **lineage finding**: sources
   claimed to be independent served the same artifact. Record it.
5. **Batch when you can.** One commit adding ten items costs one workflow run; ten commits cost ten.

## Current limitations

- **Only allowlisted hosts.** The queue accepts any URL, but the harvester runs on GitHub's network and
  the register's own catalogue is the intended scope. Off-catalogue hosts will fetch, but ask whether
  they belong in the source registry first.
- **The schedule trigger is commented out.** Continuous ingest is the goal, but an unattended scraper
  is not switched on before a manual run has been inspected.
- **`NARA_API_KEY` may not be set yet.** Check the ledger: a 401/403 from `catalog.archives.gov` means
  egress works and the key is what is missing.
