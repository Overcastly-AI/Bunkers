/**
 * THE DOCUMENT BLOCK — the ref gutter / text column / margin column triad of
 * DESIGN.md §5, as one component instead of eight copies.
 *
 * "Every heading, proposition block, table, receipt row and note carries a ref
 * code, right-aligned, Mono --t-micro, --ink-3. REF CODES ARE STABLE AND
 * DERIVED FROM DATA, NEVER FROM DOM ORDER."
 *
 * The `code` prop is therefore required and is never auto-numbered from
 * position: a caller passes `§4` or `L-7` or `D-006` because that is what the
 * block IS, not because of where it sits. An auto-incrementing counter here
 * would make ref codes shift when a section is inserted, which is precisely the
 * property that makes a citation worthless.
 *
 * `ref` is not usable as a prop name in React, hence `code`.
 */

import type { ReactNode } from "react";

export function Block({
  code,
  margin,
  wide = false,
  id,
  children,
}: {
  code: ReactNode;
  margin?: ReactNode;
  /** Wide objects span text / margin (~60rem): tables, plates, stave columns. */
  wide?: boolean;
  id?: string;
  children: ReactNode;
}) {
  return (
    <>
      <div className="doc-ref">
        {id ? (
          <a href={`#${id}`} className="ref-anchor">
            {code}
          </a>
        ) : (
          code
        )}
      </div>
      <div className={wide ? "doc-wide" : "doc-text"} id={id}>
        {children}
      </div>
      {margin ? <div className="doc-margin">{margin}</div> : null}
    </>
  );
}

/**
 * §10.3 — "EVERY EDITORIAL SENTENCE THE REGISTER ITSELF WRITES CARRIES A
 * 5-CHARACTER MARGIN TAG, the same scheme the register applies to its sources."
 *
 *   [doc] documented · [inf] inferred from open signals · [clm] claimed
 *
 * The tag is the register grading its own prose by the standard it grades
 * everyone else's. A methodology page whose sentences carried no tag would be
 * exempting the register from its own apparatus.
 */
export function Tag({ k }: { k: "doc" | "inf" | "clm" }) {
  return (
    <span className="apparatus-tag voice-mono" aria-label={`apparatus tag: ${k}`}>
      [{k}]
    </span>
  );
}

/**
 * A section head: the §n ref and a 2px rule (§14.5). The heading level is
 * explicit rather than inferred, because these pages are long and a document
 * outline that skips a level is an accessibility defect.
 */
export function SectionHead({
  code,
  title,
  id,
  margin,
}: {
  code: string;
  title: string;
  id: string;
  margin?: ReactNode;
}) {
  return (
    <Block code={code} id={id} margin={margin}>
      <h2 className="section-head">{title}</h2>
    </Block>
  );
}
