/**
 * SPECIMEN CONTAINMENT — DESIGN.md §18.
 *
 * "Specimen containment is STRICT, because a project whose entire premise is
 * the separation of established from claimed CANNOT AFFORD FIXTURES BEING
 * MISTAKEN FOR ENTRIES."
 *
 * Six mechanisms are specified. Three of them are this component:
 *
 *   3. a persistent header rule on every specimen sheet
 *   4. a FULL-HEIGHT HATCHED LEFT MARGIN RULE (`url(#hatch45)`, 6px wide)
 *      running the length of the page
 *   5. the marker embedded in every stave `aria-label` on the page — carried by
 *      `containment.aria_prefix` and threaded into every stave by the sheet
 *
 * The other three are elsewhere by construction: the URL namespace is the route
 * (1), `noindex, nofollow` is page metadata (2), and exclusion from every count
 * is the repository holding two different arrays (6).
 *
 * §21.9 records the residual risk in the register's own voice, and this
 * component prints it rather than hiding it: "Publishing specimen sheets risks
 * fixtures being screenshotted as findings. Six containment mechanisms are
 * specified and NONE OF THEM CLOSES IT FULLY."
 *
 * The hatch is the same `#hatch45` pattern the unreached ladder span uses. It
 * is drawn as an SVG rather than as a CSS gradient because §5 forbids
 * gradients outright and because a pattern prints, scales and survives
 * greyscale where a background gradient does not.
 */
export function SpecimenFrame({
  headerRule,
  children,
}: {
  headerRule: string;
  children: React.ReactNode;
}) {
  return (
    <div className="specimen">
      {/* Mechanism 4 — the full-height hatched margin rule. */}
      <svg
        className="specimen-hatch"
        width="6"
        preserveAspectRatio="none"
        aria-hidden="true"
        focusable="false"
      >
        <rect x="0" y="0" width="6" height="100%" fill="url(#hatch45)" />
      </svg>

      {/* Mechanism 3 — the persistent header rule. Not dismissible, not a
          banner, not styled as a warning: it is a statement of what the sheet
          is, at the top of the sheet, in the register's own voice. */}
      <div className="specimen-rule voice-mono t-micro" role="note">
        {headerRule}
      </div>

      {children}
    </div>
  );
}

/** The residual-risk note, printed once per specimen page. */
export function SpecimenResidual() {
  return (
    <p className="t-small specimen-residual">
      Six containment mechanisms separate this sheet from a register entry — a separate URL
      namespace, <span className="voice-mono">noindex, nofollow</span>, this header rule, the
      hatched margin, the marker inside every stave&rsquo;s accessible name, and exclusion from
      every count on the register, the telemetry and the plate. No provenance beacon is emitted.
      None of the six closes the risk fully, and the register publishes that rather than implying
      otherwise.
    </p>
  );
}
