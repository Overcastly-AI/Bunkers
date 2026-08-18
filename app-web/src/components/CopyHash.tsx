"use client";

/**
 * THE HASH — DESIGN.md §10.2.
 *
 * "The truncated `sha256` is CLICK-TO-COPY. Showing a hash is not decoration;
 * it is THE REPRODUCIBILITY CLAIM, and it is the most instrument-like gesture
 * available."
 *
 * The one piece of client JavaScript on a reading page, and it is an
 * enhancement rather than a path: the element is a `<button>` whose accessible
 * name is the FULL hash, so with scripting disabled the value is still present
 * in the DOM, still selectable, still reachable by keyboard and still read out
 * in full by a screen reader. Nothing about the evidence becomes unreadable if
 * the copy never fires. §16: "The entire site works with JavaScript disabled
 * except the map canvas."
 */

import { useState } from "react";

export function CopyHash({ sha256 }: { sha256: string }) {
  const [copied, setCopied] = useState(false);
  const short = `${sha256.slice(0, 4)}…${sha256.slice(-3)}`;

  return (
    <button
      type="button"
      className="copy-hash voice-mono"
      title={sha256}
      aria-label={`sha256 ${sha256}. Activate to copy.`}
      onClick={() => {
        void navigator.clipboard?.writeText(sha256).then(
          () => setCopied(true),
          () => setCopied(false),
        );
      }}
    >
      sha256 {short}
      {copied ? <span className="t-micro copy-ack"> copied</span> : null}
    </button>
  );
}
