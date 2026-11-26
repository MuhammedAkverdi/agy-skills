---
name: ui-design
description: >-
  Hybrid anti-slop frontend & UI design skill combining art direction, two-pass design thesis
  (swap test), craft floor rules, real-Chrome visual verification, and cognitive-load critique/polish.
  Use whenever building, designing, redesigning, auditing, critiquing, or polishing a web page,
  landing page, SaaS UI, dashboard, component, form, or app interface — or when the user says
  "UI tasarla", "arayüz yap", "landing page", "dashboard", "tasarımı güzelleştir", "redesign",
  "polish", "critique", "audit", "AI gibi görünüyor", "make it look professional".
---

# UI Design — Hybrid Anti-Slop & Visual Gate Skill

Build interfaces that look authored for one specific product and audience — never generic AI templates. Combines the **art-direction discipline** of `taste-skill`, the **two-pass design thesis** of `frontend-design`, and the **craft floor + critique/polish rigor** of `impeccable`.

## Antigravity Tool Mapping

- **Pre-brief & decisions:** `ask_question` (put the recommended option first with `(Recommended)`).
- **Real Chrome verification (`chrome-devtools` MCP via `call_mcp_tool`):** `new_page`, `emulate` *(best for exact viewports like `"1440x900x1"` and `"390x844x2,mobile,touch"`, since Windows Chrome caps `resize_page` at ~500px minimum width)*, `resize_page`, `take_snapshot`, `take_screenshot` *(omit `filePath` so screenshots save to `.system_generated/steps/...` cleanly)*, `click`, `evaluate_script`, `list_console_messages`, `close_page`.
- **Visual inspection:** `read_file` on captured PNG screenshots (always inspect rendered desktop `1440×900` and mobile `390×844` views).
- **Bespoke imagery:** Invoke the **`gemini-image`** skill (Google Flow, Nano Banana Pro, 0 credits) when the design needs real photography or custom brand artwork not provided by the user.

---

## 0. Classify Surface Mode & Business Kind (First Step)

Declare both on line 1 of your design plan before writing any code:

| Surface Mode | Visitor's Goal | Design Commitment |
|---|---|---|
| **Persuade** | Decide and act (landing pages, marketing, pricing, launches) | Bold POV, strong visual anchor, clear primary CTA |
| **Operate** | Complete tasks reliably (dashboards, SaaS apps, editors, admin, settings) | Scanability, high legibility, consistent controls, restraint |
| **Read** | Understand content (docs, articles, guides, changelogs) | Clean reading measure (`65–75ch`), typographic calm |
| **Experience** | Immerse in the work (portfolios, galleries, showcases) | Artifact leads from the first viewport; chrome recedes |

And classify the **Business Kind** to enforce the **Tech-only effects rule**:
- **Tech (`software`, `gaming`, `hardware`):** Live HTML product UI (actual interactive screens/diffs/tables, never fake gray boxes), pulsing diagrams, dark modes, and subtle WebGL/CSS atmospheres are allowed where justified.
- **Non-Tech (`place`, `product`, `service`):** Cafes, restaurants, hotels, shops, clinics, agencies, physical goods. **No dark-neon tech effects, no shaders, no pulsing network diagrams.** Lead with real photography (`/gemini-image` or user photos), flat tactile surfaces, and disciplined typography.

---

## 1. Sub-commands (Routing)

If the user specifies a mode, route directly:
- **Default (new build / redesign):** Full 5-stage pipeline (`Brief → Two-Pass Thesis → Build → Browser Gate → Critique & Polish`).
- **`critique [target]`:** Load [references/critique-and-polish.md](references/critique-and-polish.md), run Chrome DOM & screenshot inspection, and deliver a P0–P3 + cognitive-load review without rewriting the visual world.
- **`polish [target]`:** Load [references/critique-and-polish.md](references/critique-and-polish.md) and [references/craft-floor.md](references/craft-floor.md); fix functional, spacing, contrast, responsive, and state defects while preserving the incumbent identity.
- **`bolder` / `quieter`:** Shift visual intensity (typography contrast, surface tension, color weight, motion) up or down intentionally.
- **`audit [target]`:** Run the Chrome DevTools DOM, accessibility, console, and responsive audit only.

---

## 2. Pre-brief (Skip if detailed or user says "hızlıca" / "direkt" / "test")

If the request is a short 1–2 sentence prompt and lacks key direction, ask **at most 3 short questions** in ONE `ask_question` call in the user's language:
1. **Hedef & Yüzey:** Landing page (`Persuade`) / Uygulama & Dashboard (`Operate`) / Portföy (`Experience`)
2. **Görsel Dünya & Ton:** Açık editoryal & teknik / Koyu yüksek kontrast / Sıcak doğal & fotoğraf odaklı / Marka renklerine göre
3. **Görsel Kaynağı:** `/gemini-image` ile özel görseller üret / Mevcut görselleri kullan / Canlı interaktif HTML arayüzü

Skip immediately when the user already answered these or asked for quick/direct output.

---

## 3. Two-Pass Design Thesis (Anti-Slop Swap Test)

Never jump straight into HTML/CSS. Write a compact plan first:

1. **Pass 1 — Design Plan:**
   - **Mode & Kind:** e.g. `Persuade / software`
   - **Palette (4–6 named hex tokens):** background, surface, primary ink, muted ink, primary accent, semantic status.
   - **Typography (1–2 intentional families):** display/body + monospace (if data/code), explicit scale & `tabular-nums` for numbers.
   - **Layout Wireframe (ASCII):** clear grid structure, alignment rule, and **one primary action** per viewport.
   - **ONE Authored Focal Moment:** either a live interactive product widget, a commanding typographic/photographic hero, or one orchestrated entrance/interaction — never scattered animations everywhere.

2. **Pass 2 — Anti-Slop Swap Test (Mandatory Review):**
   Check Pass 1 against the **2026 AI-Slop Tells** in [references/craft-floor.md](references/craft-floor.md) (warm cream + terracotta default, dark `#0B0B0B` + neon/purple glow, 3 identical icon cards, ALL-CAPS eyebrows above every heading, `01/02/03` on non-sequences, gradient text, single italicized/colored word in h1, `→` on every button). If any free axis fell back to a generic cliché, **revise that choice explicitly before coding**.

---

## 4. Build Rules

**ALWAYS read [references/craft-floor.md](references/craft-floor.md) before writing UI code.**
- **Real content & active UX copy:** Never use Lorem Ipsum. Write domain-authentic copy in the user's language. CTAs name verb + object (*"Kayıtları filtrele"*, *"Projeyi başlat"* — not *"Submit"*). Error/empty states state what happened and how to recover.
- **Responsive & accessible floor:** Mobile-first / fluid grids down to `390px` (no horizontal overflow), visible `:focus-visible` rings, `44×44px` minimum tap targets on mobile, semantic landmarks (`header`, `main`, `nav`, `footer`), `prefers-reduced-motion` support.
- **Browser surfaces:** Always theme `::selection`, `caret-color`, `:focus-visible`, custom scrollbars, `text-underline-offset`, and `font-variant-numeric: tabular-nums`.
- **Single-file or project-native:** Match the active workspace stack (React/Next/Tailwind/Svelte or standalone semantic HTML/CSS/JS). Keep CSS specificity clean.

---

## 5. Mandatory Real-Browser Gate & Polish Loop (`chrome-devtools` MCP)

Every UI deliverable MUST be verified in real Chrome before presenting to the user:

1. **Open in Chrome:** Use `new_page` on the dev server URL (`http://localhost:...`) or static `file:///...` path.
2. **Desktop Gate (`1440×900`):**
   - Call `emulate` (`viewport: "1440x900x1"`).
   - Run the DOM & Style Audit script from [references/critique-and-polish.md](references/critique-and-polish.md) via `evaluate_script`.
   - Test interactive controls (`click` tabs, filters, drawers, forms) to verify real state changes.
   - Check `list_console_messages` for zero errors.
   - Call `take_screenshot` *(omit `filePath`)* and inspect the rendered image with `read_file`.
3. **Mobile Gate (`390×844`):**
   - Call `emulate` (`viewport: "390x844x2,mobile,touch"`).
   - Re-run the DOM audit script (`scrollWidth <= innerWidth`, tap targets, readable font sizes).
   - Call `take_screenshot` *(omit `filePath`)* and inspect the rendered mobile image with `read_file`.
4. **Critique & Polish Pass:**
   - Review both screenshots against [references/critique-and-polish.md](references/critique-and-polish.md) (P0–P3 + Cognitive Load).
   - Fix every P0/P1 defect found, re-verify the affected view with `take_screenshot` + `read_file`, reset emulation (`emulate` without `viewport`), and close the temporary Chrome tab (`close_page`).

## Self-Revision on Errors (Mandatory)

If any error, Chrome DevTools inspection issue, layout/responsive failure, console error, or visual QA defect happens while using this skill and you diagnose or fix it, **immediately revise this `SKILL.md`** (or the affected `references/*.md` file) with the root cause and verified fix before finishing the task, and report the update to the user.

## Rules

- Never claim a UI looks good without inspecting the rendered desktop and mobile screenshots via `read_file`.
- Never invent broken external image URLs (`unsplash` random links that 404); verify `naturalWidth > 0` in Chrome or generate real assets with `/gemini-image`.
- Report honestly what the browser gate checked and what the Polish pass fixed.
