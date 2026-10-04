---
name: Sovereign Ledger
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#43474d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#74777e'
  outline-variant: '#c4c6ce'
  surface-tint: '#476080'
  primary: '#00162d'
  on-primary: '#ffffff'
  primary-container: '#0f2b48'
  on-primary-container: '#7a93b5'
  inverse-primary: '#afc8ed'
  secondary: '#904d00'
  on-secondary: '#ffffff'
  secondary-container: '#fe932c'
  on-secondary-container: '#663500'
  tertiary: '#001a0f'
  on-tertiary: '#ffffff'
  tertiary-container: '#003120'
  on-tertiary-container: '#26a476'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d2e4ff'
  primary-fixed-dim: '#afc8ed'
  on-primary-fixed: '#001c37'
  on-primary-fixed-variant: '#2f4867'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77d'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  currency-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  currency-ledger:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies the precision, security, and poise required by modern business operators and financial professionals. Melding Material 3 functional mechanics with the visual polish of contemporary enterprise fintech, the interface balances executive authority with effortless operational clarity. 

The aesthetic is Modern Android Corporate: ultra-crisp surfaces, structural clarity, high-contrast numeric legibility, and refined tactile feedback. The primary emotional objective is uncompromised trust and speed—ensuring high-density fiscal metrics remain immediately digestible during rapid decision-making while maintaining the ergonomics required for daily, touch-heavy mobile usage.

## Colors

The palette establishes an unmistakable hierarchy of stability, actionable status, and fiscal performance:

- **Primary Deep Navy (`#0F2B48`)**: Anchors primary app bars, high-prominence actions, and master titles. Paired with Deep Slate Dark (`#0A1E33`) for deepest contrast zones and Navy Soft Tint (`#F0F4F8`) for secondary container backgrounds.
- **Secondary Amber/Gold (`#D97706` / Accent `#F59E0B`)**: Reserved strictly for high-value transactional highlights, pending states, alerts, and critical contextual callouts. Supported by Amber Light Tint (`#FEF3C7`).
- **Semantic Success/Received Emerald (`#059669` / `#10B981`)**: Dictates incoming capital, verified transactions, and positive cash flow states. Supported by Soft Emerald (`#ECFDF5`).
- **Semantic Danger/Overdue Crimson (`#DC2626` / `#EF4444`)**: Dictates liabilities, overdue receivables, debit flows, and critical security warnings. Supported by Soft Red (`#FEF2F2`).
- **Neutral Slate (`#64748B`)**: Drives secondary copy and icons. Structural surfaces rely on Card Surface White (`#FFFFFF`), Canvas Canvas Tone (`#F8FAFC`), and Hairline Dividing Slate (`#E2E8F0`).

## Typography

Typography is architected specifically around legibility in tabular figures, financial strings, and hierarchical density:

- **Display & Headlines (Plus Jakarta Sans)**: Delivers a clean, contemporary executive tone for dashboard figures, total portfolio summaries, and section headers.
- **Data & Body (Inter)**: Handles all continuous body copy, form labels, and financial data grids. Always enable tabular numbers (`tnum`) and slashed zeros (`zero`) across all monetary representations.
- **Indian Rupee (₹) Formatting Guidelines**: The currency glyph `₹` must strictly align with the cap-height of adjacent numerals. Never allow standard spacing between the currency symbol and the value (e.g., `₹1,24,500.00`). Follow Indian grouping nomenclature (lakhs and crores: `2,00,000` rather than `200,000`).

## Layout & Spacing

This design system adheres to a strict 4-point base grid using an 8-point structural cadence:

- **Canvas & Grids**: Handheld interfaces operate on a single-column stacked layout with a fixed horizontal page margin of `16px` (`1rem`). On foldable and tablet displays, expand into an 8-column layout with `24px` gutters.
- **Touch Targets**: In accordance with Android accessibility standards, all touchable nodes (action buttons, list items, checkboxes, menu triggers) enforce a strict minimum boundary of `48x48dp`.
- **Rhythm & Stacking**: Content grouping inside financial cards utilizes `12px` (`0.75rem`) to `16px` (`1rem`) internal padding. Related metric modules must maintain `8px` (`0.5rem`) internal separation, while distinct analytical cards separate by `16px` (`1rem`).

## Elevation & Depth

Visual hierarchy uses a refined ambient elevation system combined with low-contrast structural borders:

- **Flat Canvas (Level 0)**: Tone `#F8FAFC`. Used for primary screen backgrounds behind floating card structures.
- **Card Base (Level 1)**: Tone `#FFFFFF` with a 1px border of `#E2E8F0` and an ambient shadow: `box-shadow: 0px 1px 3px rgba(15, 43, 72, 0.05), 0px 4px 12px rgba(15, 43, 72, 0.03)`.
- **Raised Interactive (Level 2 - Hover/Active/Sheet)**: Tone `#FFFFFF` with an expanded ambient shadow: `box-shadow: 0px 4px 8px rgba(15, 43, 72, 0.08), 0px 12px 24px rgba(15, 43, 72, 0.06)`.
- **Floating Overlays & Dialogs (Level 3)**: Tone `#FFFFFF` with backdrop blur (`backdrop-filter: blur(4px)`) over a `#0A1E33` 40% alpha scrim: `box-shadow: 0px 12px 32px rgba(10, 30, 51, 0.16)`.
- **Rule on Color Shadows**: Shadows never use pure black; they are explicitly tinted with Navy (`#0F2B48`) to maintain brand coherence and avoid visual murkiness.

## Shapes

The interface balances modern curvature with high-density data discipline:

- **Primary Cards & Modals**: Enforce `16px` (`rounded-2xl` equivalent) corner radius for primary content cards, summary banners, and bottom sheets, delivering an authentic Material 3 feel.
- **Interactive Controls (Inputs, Buttons, Dropdowns)**: Sized with `12px` corner radius (`0.75rem`) to ensure tight layout cohesion.
- **Badges & Status Chips**: Strictly fully pill-shaped (`9999px`) to immediately distinguish informational metadata from actionable surfaces.

## Components

### Primary & Secondary Buttons
- **Primary Action**: Solid `#0F2B48` background, `#FFFFFF` text, `48px` minimum height, `12px` border radius, horizontal padding `24px`. Text styled with `label-lg`. Pressed state applies a ripple with `rgba(255, 255, 255, 0.16)`.
- **Accent / Highlight Action**: Solid `#D97706` background, `#FFFFFF` text. Used exclusively for high-importance financial triggers (e.g., "Collect Payment", "Settle Balance").
- **Tonal / Outlined**: 1px border `#E2E8F0`, `#0F2B48` text, `#FFFFFF` background. Pressed state sets surface to `#F0F4F8`.

### Status Chips & Badges
- Pill-shaped (`9999px`), `24px` height, horizontal padding `10px`, typography `label-sm`.
- **Success / Received**: Background `#ECFDF5`, text `#059669`, border `1px solid rgba(16, 185, 129, 0.2)`.
- **Overdue / Pending Action**: Background `#FEF2F2`, text `#DC2626`, border `1px solid rgba(239, 68, 68, 0.2)`.
- **Awaiting Settlement / Review**: Background `#FEF3C7`, text `#D97706`, border `1px solid rgba(245, 158, 11, 0.25)`.
- **Neutral / Draft**: Background `#F0F4F8`, text `#64748B`, border `1px solid #E2E8F0`.

### High-Clarity Ledger Items
- Standard vertical height `68px` to `76px` with continuous touch target zones.
- Left-aligned: Circular `40px` entity avatar or category glyph container in `#F0F4F8`, primary description styled with `headline-sm`, subtitle with timestamp and transaction ID in `body-sm` (`#64748B`).
- Right-aligned: Transaction amount set in `currency-ledger`. Credited amounts prepend a `+` and use `#059669`; debited amounts prepend a `-` and use `#0A1E33` or `#DC2626`. Directly beneath the amount, place a micro status chip or settlement label.

### Input Fields & Selectors
- Height `52px`, container background `#FFFFFF`, border `1.5px solid #E2E8F0`, corner radius `12px`.
- Active/Focused state: Border color changes to `#0F2B48` with a non-blurring ring `3px rgba(15, 43, 72, 0.1)`.
- Monetary input mode: Always embed an immutable prefix `₹` in `#0F2B48` (`Plus Jakarta Sans 600`) with high tactile font scale.

### Cards & Summary Modules
- Built on `#FFFFFF` with `16px` border radius and Level 1 elevation.
- Financial metric summary cards place secondary uppercase metadata tags (`label-sm`, `#64748B`) at the top, leading values in `currency-display`, and footer micro-sparklines or period comparisons (`+12.4% vs last month`) anchored to semantic tokens.