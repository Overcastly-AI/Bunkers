/**
 * THE SHARED PATTERN DEFINITIONS.
 *
 * Two fills exist on this site and both are PATTERNS, never alpha.
 *
 *  `#hatch45`  45° hatch — the unreached ladder span and the inert / specimen
 *              margin rules.
 *  `#screen4`  4px dot screen — uncertainty area interiors on the plate.
 *
 * DESIGN.md §8.2 gives the decisive reason and it applies to both: "ALPHA-
 * COMPOSITING MAKES OVERLAPPING UNCERTAINTY REGIONS LOOK LIKE CORROBORATION.
 * Two overlapping translucent regions darken into a blob that appears more
 * confident than either. A phase-locked dot screen moirés instead of
 * compounding. Translucent fills lie by stacking, and this register cannot
 * afford that particular lie."
 *
 * Patterns are `patternUnits="userSpaceOnUse"` so the pitch is fixed in device
 * space and does not rescale with the mark it fills — a hatch whose pitch
 * tracked the shape would encode size as density, which is a quantity no row
 * carries. §16: patterns are baked at fixed device-pixel pitch.
 *
 * Rendered once, in the layout, inside a zero-size SVG. Every stave on the page
 * references these by id.
 */
export function SvgDefs() {
  return (
    <svg
      width="0"
      height="0"
      aria-hidden="true"
      focusable="false"
      style={{ position: "absolute" }}
    >
      <defs>
        <pattern
          id="hatch45"
          patternUnits="userSpaceOnUse"
          width="4"
          height="4"
          patternTransform="rotate(45)"
        >
          <line
            x1="0"
            y1="0"
            x2="0"
            y2="4"
            stroke="var(--hatch)"
            strokeWidth="1"
          />
        </pattern>

        <pattern id="screen4" patternUnits="userSpaceOnUse" width="4" height="4">
          <circle cx="1" cy="1" r="0.6" fill="var(--screen)" />
        </pattern>
      </defs>
    </svg>
  );
}
