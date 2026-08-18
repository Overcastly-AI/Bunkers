import { Fragment } from "react";
import type { Metadata } from "next";

/**
 * §2 — SELF-HOSTED. NO GOOGLE FONTS REQUEST.
 *
 * "A register whose readers' viewports should not be logged by a vendor should
 * not ship their font requests to one either; this is the same decision as the
 * self-hosted basemap and it belongs on /method."
 *
 * These imports inline the woff2 files from node_modules at build time. No
 * request leaves the reader's browser for a font, ever.
 */
import "@fontsource-variable/ibm-plex-sans";
import "@fontsource/ibm-plex-mono/400.css";
import "@fontsource/ibm-plex-mono/600.css";
import "@fontsource/ibm-plex-serif/400.css";
import "@fontsource/ibm-plex-serif/400-italic.css";

import "./globals.css";
import "./components.css";
import { SvgDefs } from "@/components/SvgDefs";
import { getRepository } from "@/lib/repository";
import { REGISTER_STATE, standingFootLine } from "@/lib/seed";

export const metadata: Metadata = {
  title: "BUNKERS — a register of hardened and buried facilities in the United States",
  description:
    "Not a map of secrets. A map of what can be established, from what, and how well.",
};

/**
 * §13 — THE CONTENTS LINE. Not an app rail. Items separated by middots, no
 * buttons, no chips. `/limits` is TOP LEVEL and permanently linked: "a page
 * that can be demoted into a subsection is a page that will be."
 */
const CONTENTS: { href: string; label: string }[] = [
  { href: "/", label: "Register" },
  { href: "/claims", label: "Claims" },
  { href: "/plate", label: "Plate" },
  { href: "/method", label: "Method" },
  { href: "/limits", label: "Limits" },
  { href: "/telemetry", label: "Telemetry" },
  { href: "/sources", label: "Sources" },
  { href: "/decisions", label: "Decisions" },
  { href: "/corrections", label: "Corrections" },
  { href: "/calibration", label: "Calibration" },
  { href: "/api", label: "API" },
];

export default async function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const state = await getRepository().getRegisterState();

  return (
    <html lang="en">
      <body>
        {/*
          §6, §8.2 — the two pattern fills, defined once and referenced by every
          stave, every hatched margin and every uncertainty region on the site.
          They are patterns and never alpha, because alpha-compositing makes
          two overlapping uncertainty regions look like corroboration.
        */}
        <SvgDefs />

        {/*
          §5 RUNNING HEAD — 36px, one line, Mono micro, 2px solid ink beneath.

          The descriptive tail is its own span so it can be dropped below 768px.
          The head is `nowrap` and clipped, so on a phone the alternative is
          losing the RIGHT-hand field — the candidate count — off the edge. The
          count is the instrument reporting its own state and is the half worth
          keeping; the subtitle is a gloss on a name the reader can already see.
        */}
        <header className="running-head">
          <span>
            BUNKERS
            <span className="running-head-tail">
              {" "}
              · A REGISTER OF HARDENED AND BURIED FACILITIES IN THE UNITED STATES
            </span>
          </span>
          <span>
            BES v0.2 · {state.candidates_published} CANDIDATES
          </span>
        </header>

        {/*
          THE CONTENTS LINE. Items separated by middots, no buttons, no chips.

          The separator carries LITERAL SPACES around the middot, and that is
          load-bearing rather than cosmetic: with no whitespace text node between
          the items the browser has no break opportunity, so the whole line
          becomes one unbreakable 631px word and every page it sits on scrolls
          horizontally at phone widths. §15 forbids that outright — "the page
          body never scrolls horizontally" — and the violation was site-wide,
          because this line is in the root layout.
        */}
        <nav className="contents-line" aria-label="Contents">
          {CONTENTS.map((c, i) => (
            <Fragment key={c.href}>
              {i > 0 ? (
                <span className="sep" aria-hidden="true">
                  {" · "}
                </span>
              ) : null}
              <a href={c.href}>{c.label}</a>
            </Fragment>
          ))}
        </nav>

        <main style={{ paddingBottom: "var(--s-8)" }}>{children}</main>

        {/*
          §5 STANDING FOOT. THIS IS WHERE THE D-006 PUBLICATION OBLIGATION IS
          STRUCTURALLY DISCHARGED — at the same weight and in the same voice as
          the table versions, because that is exactly what it is: a property of
          the instrument's current configuration. Composed from REGISTER_STATE
          so it cannot drift from the counts it reports.
        */}
        <footer className="standing-foot">
          <span>{standingFootLine(REGISTER_STATE)}</span>
          <a href="/limits#L-1">▸</a>
        </footer>
      </body>
    </html>
  );
}
