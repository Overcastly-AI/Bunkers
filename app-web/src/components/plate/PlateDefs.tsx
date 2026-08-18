/**
 * SVG PATTERN DEFINITIONS — the dot screen, and why it is not a wash.
 *
 * DESIGN.md §8.2:
 *
 * > "Dot screen, not translucent wash. Interiors are a 4px-pitch SVG
 * > `<pattern>` at `--screen`, never `fill-opacity`. Three reasons, the third
 * > decisive:
 * >   1. A flat wash reads as a CHOROPLETH VALUE — 'this area is hot' — a
 * >      different and false claim.
 * >   2. A dot screen reads as SAMPLING / UNRESOLVED, which is the true claim.
 * >   3. ALPHA-COMPOSITING MAKES OVERLAP LOOK LIKE CORROBORATION. Two
 * >      overlapping translucent regions darken into a blob that appears more
 * >      confident than either. A phase-locked dot screen moirés instead of
 * >      compounding. Translucent fills lie by stacking, and this register
 * >      cannot afford that particular lie."
 *
 * PHASE-LOCKING, CONCRETELY. Both patterns use `patternUnits="userSpaceOnUse"`
 * and the overlay's user space IS screen space, so every dot-screened region on
 * the plate shares one origin and one lattice. Two overlapping regions land dot
 * ON dot, not dot in gap: the union has the same COVERAGE as either one alone.
 * Coverage is what the eye reads as "how much ink is here", so overlap does not
 * read as more evidence. A `fill-opacity` wash has no lattice and no such
 * property, which is why it is banned rather than merely discouraged.
 *
 * These ids are global to the plate's single overlay `<svg>`; the legend
 * symbols carry their own `<defs>` because each legend symbol is its own tiny
 * `<svg>` and cannot reference another document's fragment.
 */

export const DOT_SCREEN_ID = "plate-dot-screen";
export const HATCH_45_ID = "plate-hatch45";

/** 4px pitch, per §8.2. Baked at a fixed device-pixel pitch (§16). */
export const DOT_PITCH = 4;

export function PlateDefs({ idPrefix = "" }: { idPrefix?: string }) {
  const dot = idPrefix + DOT_SCREEN_ID;
  const hatch = idPrefix + HATCH_45_ID;
  return (
    <defs>
      <pattern
        id={dot}
        patternUnits="userSpaceOnUse"
        width={DOT_PITCH}
        height={DOT_PITCH}
        x={0}
        y={0}
      >
        {/* No background rect. The gaps are the ground showing through — a
            wash would fill them, and filling them is the lie. */}
        <circle cx={1} cy={1} r={0.7} fill="var(--screen)" />
      </pattern>

      {/* §6 / §18 — 45° hatch. Used for a SURVEYED footprint's interior (a
          known extent, hairline-hatched) and never for an uncertainty region,
          which is dot-screened. The two interiors are different marks because
          they are different claims. */}
      <pattern id={hatch} patternUnits="userSpaceOnUse" width={4} height={4}>
        <path d="M0 4 L4 0" stroke="var(--hatch)" strokeWidth={1} fill="none" />
      </pattern>
    </defs>
  );
}

export const dotScreenFill = (idPrefix = "") => `url(#${idPrefix}${DOT_SCREEN_ID})`;
export const hatchFill = (idPrefix = "") => `url(#${idPrefix}${HATCH_45_ID})`;
