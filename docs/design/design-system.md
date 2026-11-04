# Design System — "Ashen Codex"

The visual language of Wyrd: carved stone, ink, ember. Serious, quiet, legible.
Implemented in `app/lib/design/` (tokens, theme, components). Tokens are the single source
of truth — no raw colours, sizes or durations in feature code.

## 1. Principles

1. **Stone, not plastic.** Flat layered surfaces, 1 px hairlines, sharp-ish corners. No drop
   shadows, no glossy gradients, no bubbly radii.
2. **Ember is rare.** Crimson marks the one primary action on a screen, progression, and
   significant events. If two things are crimson, one of them is wrong.
3. **Ink first.** Content legibility beats atmosphere. Body text is always a high-contrast
   sans (Inter / Vazirmatn). Display type is ornamental and short.
4. **Direction-agnostic.** Every token and component is defined with start/end, never
   left/right. Icons that imply direction mirror in RTL.
5. **Calm motion.** Motion explains change (a bar filling, a card settling). Nothing loops
   for attention. Reduced-motion users get instant state changes.

## Version 2 (2026-11): livelier, still dark fantasy

v2 keeps the stone-and-ember identity but adds energy:

- **Saturated attribute pigments** and two sparing secondary accents: `arcane` `#8B6CFF`
  (radar fill, chronicle, class pills) and `gold` `#E2B45C` (titles, medals, milestones).
  `emberGlow` `#FF8A4C` completes the ember gradient (`crimson → ember → emberGlow`).
- **Gradients instead of flat fills:** stone-lit card surfaces (lighter at the top), ember
  gradients on progress, primary buttons and the quick-add button, one radial backdrop glow
  behind all tabs, and a static radial burst behind the reward total.
- **Softer, modern shapes:** cards 18 px, controls 14 px, pills for buttons, chips, tab and
  navigation indicators.
- **Game-like components:** circular XP ring around the portrait, hexagonal attribute radar
  (mirrored in RTL), tinted attribute and stat tiles, category badges on quest cards.
- **Performance budget:** no blur filters or backdrop blurs; soft shadows only on a few hero
  elements (FAB, level badge, primary button, completed seals); custom painters isolated with
  `RepaintBoundary`; animations are single tweens that respect reduced motion.

## 2. Colour tokens

### Surfaces and ink

| Token | Hex | Use | Contrast vs `void` |
| --- | --- | --- | --- |
| `void` | `#09090E` | App background | — |
| `abyss` | `#111320` | Lowest surface, sidebars | — |
| `slate` | `#181C2B` | Cards, panels | — |
| `slateHigh` | `#222839` | Hover, selected rows, inputs | — |
| `hairline` | `#2C3346` | 1 px borders, dividers | 1.9 : 1 (decorative) |
| `wine` | `#4A1A26` | Secondary containers, selected chips | — |
| `crimson` | `#C0202D` | Primary action fill, XP fill, key events | fills only (bone on crimson 5.1 : 1) |
| `ember` | `#FF5A64` | Crimson used as text/icon on dark | 6.4 : 1 |
| `bone` | `#F1EBDF` | Headings, high-emphasis text, on-crimson text | 15.6 : 1 |
| `ash` | `#C9CCD6` | Body text | 11.4 : 1 |
| `ashMuted` | `#8E94A3` | Secondary text, captions | 6.0 : 1 |
| `ashFaint` | `#5A6074` | Disabled, decorative glyphs only | 3.2 : 1 |

Text on `crimson` uses `bone` (5.1 : 1). Body text never uses `ashFaint`.

### Attributes
Muted pigments, distinguishable for common colour-vision deficiencies when paired with
their sigils (colour is never the only signal).

| Attribute | Token | Hex | Sigil |
| --- | --- | --- | --- |
| Strength | `attrStrength` | `#F0663E` rust | upward chevron over bar |
| Intelligence | `attrIntelligence` | `#5B95FF` steel | open eye in diamond |
| Discipline | `attrDiscipline` | `#D9B260` tarnished brass | vertical blade between rails |
| Creativity | `attrCreativity` | `#B476FF` amethyst | spiral quill |
| Vitality | `attrVitality` | `#3FCB8E` moss | leaf in circle |
| Social | `attrSocial` | `#FF73A8` rose | three linked rings |

### Feedback
`success` = `attrVitality`, `warning` `#F0A93B`, `danger` = `ember`, `info` = `attrIntelligence`.

## 3. Typography

| Role | Latin | Arabic script (fa) | Size / line height | Weight |
| --- | --- | --- | --- | --- |
| `display` | Cinzel | Vazirmatn | 32 / 40 | 600 (fa 800) |
| `title` | Cinzel | Vazirmatn | 22 / 30 | 600 (fa 700) |
| `heading` | Inter | Vazirmatn | 17 / 24 | 600 |
| `body` | Inter | Vazirmatn | 15 / 22 (fa 15 / 26) | 400 |
| `label` | Inter | Vazirmatn | 13 / 18 | 500 |
| `caption` | Inter | Vazirmatn | 12 / 16 (fa 12 / 20) | 400 |
| `numeral` | Inter tabular | Vazirmatn (Persian digits when enabled) | contextual | 600 |
| `overline` | Cinzel, tracking +1.2 | Vazirmatn, tracking 0 | 11 / 16 | 600 |

Rules: Arabic script never receives letter-spacing (it breaks joining). Persian line heights
are taller to fit diacritics and descenders. Cinzel is used only for short Latin labels;
mixed-script strings fall back per glyph via the font fallback chain
(`Inter → Vazirmatn` and `Vazirmatn → Inter`). Fonts are bundled (OFL), never fetched at
runtime.

## 4. Space, shape, elevation

- **Spacing scale (4-pt):** `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`, `xxxl 48`.
- **Radius (v2):** `sharp 8` (small badges), `soft 14` (inputs, tiles), `card 18` (cards),
  `pill 999` (buttons, chips, indicators, bars).
- **Borders:** 1 px `hairline`; focused elements get a 1 px `ember` outline plus a 2 px
  outer glow at 24 % alpha (also the keyboard focus ring).
- **Elevation:** expressed by surface step (`void → abyss → slate → slateHigh`), never by
  shadow. Modals add a 60 % `void` scrim.
- **Texture:** a very low-contrast noise and vignette on the app background only (≤ 3 %),
  disabled in "reduced effects" mode.

## 5. Motion

| Token | Duration | Curve | Use |
| --- | --- | --- | --- |
| `quick` | 120 ms | standard | hover, press, toggle |
| `base` | 200 ms | standard | expand, sheet, page fade |
| `settle` | 320 ms | emphasized-decelerate | cards entering, list reorder |
| `reveal` | 900 ms | emphasized | XP bar fill and attribute delta on reward |

`standard = cubic(0.2, 0, 0, 1)`, `emphasized-decelerate = cubic(0.05, 0.7, 0.1, 1)`.
With `MediaQuery.disableAnimations` or the in-app "reduced motion" toggle, durations are 0.

## 6. Components

| Component | Anatomy and behaviour |
| --- | --- |
| **Panel** | `slate` fill, 1 px `hairline`, radius `soft`, optional overline header with a hairline rule extending to the end edge |
| **Primary button** | `crimson` fill, `bone` label, 44 px min height (48 on touch). One per view. Pressed: darken 8 %. |
| **Secondary button** | transparent, 1 px `hairline`, `ash` label; hover `slateHigh` |
| **Quiet button** | text-only `ember`; for tertiary actions |
| **Text field** | `abyss` fill, 1 px `hairline`, focus `ember` ring; label above, helper below; RTL-aware prefix/suffix |
| **Chip** | `sharp` radius, `abyss` fill, selected = `wine` fill + `bone` text |
| **XP bar** | 6 px track `abyss`, fill `crimson`, true proportion only; numeric label "1 240 / 1 520" in tabular numerals |
| **Attribute row** | sigil (attribute colour) · name · rank · thin bar in attribute colour · +delta today in `ashMuted` |
| **Quest tile** | completion seal (circle → filled crimson seal on complete), title, meta row (tier glyph, due, estimate, category), trailing overflow; swipe-to-complete on touch, checkbox + hotkey on desktop |
| **Reward card** | sheet showing per-attribute deltas with sigils, rationale lines, adjustments in plain language, "Why this reward?" expander linking to the ledger entry |
| **Feed item** | actor avatar seal, action sentence (respecting share level), relative time, reaction bar (Honour, Steel, Flame, Laurel), comment count |
| **Empty state** | small sigil illustration in `ashFaint`, one sentence in voice, one action |
| **Loading** | skeleton panels with a slow (1.6 s) opacity breathe; never spinners on primary surfaces |
| **Error state** | `ember` hairline at the start edge, plain-language message, retry action; never blames the user |
| **Toast** | `slateHigh`, bottom-start on desktop, bottom-centre on mobile, auto-dismiss 4 s, action optional |

## 7. Voice and copy

Second person, present tense, calm. Fantasy flavour in nouns (quest, contract, guild,
chronicle, seal, deed), plain language in verbs and explanations.

| Instead of | Write |
| --- | --- |
| "You failed your streak!" | "This week's target wasn't reached. Your record stands at 6 weeks." |
| "Don't lose your progress!" | "Your progress is safe. Pick one small quest when you're ready." |
| "Epic win!!!" | "Contract sealed." |
| "You're lazy today" | (never) |

No copy may reference the user's worth, mood, or body. No guilt, urgency, or loss framing.

## 8. Accessibility

- WCAG 2.2 AA: text ≥ 4.5 : 1, large text and UI components ≥ 3 : 1.
- Every interactive element ≥ 44 × 44 (48 × 48 on touch) and has a semantic label.
- Supports text scaling to 200 % without clipping (layouts reflow; bars stack).
- Keyboard: full traversal, visible focus, shortcuts listed in a help sheet (desktop/web).
- Colour is never the only carrier of meaning (sigils + labels for attributes).
