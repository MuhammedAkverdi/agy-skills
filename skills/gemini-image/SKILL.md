---
name: gemini-image
description: Generate, edit and refine photos/images for the user with their own Google AI Pro account — first in Google Flow (flow.google.com, Nano Banana Pro, 0 credits), else in Gemini chat at gemini.google.com — in their real Chrome (via chrome-devtools MCP), check them visually, and deliver them in the right size/format (Instagram, story, YouTube thumbnail, WebP, transparent PNG). Use whenever a task needs a picture, photo, illustration, logo, icon, cover, poster, thumbnail or any generated image, or an edit of an existing photo (change background, remove/add objects, restore, restyle), or the user says "fotoğraf oluştur", "resim üret", "görsel yap", "foto lazım", "fotoğrafı düzenle", "arka planı değiştir", "logo yap", "make an image", "edit this photo". ALWAYS load this skill first and run its pre-brief: ask the user 3–4 short questions (ask_question) before generating, unless they said hızlıca/direkt/sormadan or it is a v2 fix.
---

# Images via Google Flow / Gemini Pro (Antigravity + Chrome DevTools MCP)

The user has a Google AI Pro subscription and wants images made there (Google Flow first, 0 credits), not through a paid API key.

## Antigravity Tool Mapping

Use Antigravity's native tools to execute the Chrome workflow:
- **Questions:** `ask_question` (put recommended option first with `(Recommended)`).
- **Real Chrome control (`chrome-devtools` MCP via `call_mcp_tool`):**
  - Open/list/close tabs: `list_pages`, `new_page`, `select_page`, `close_page`, `navigate_page`
  - Inspect & interact: `take_snapshot` (get element UIDs), `take_screenshot`, `click`, `hover`, `fill`, `type_text`, `press_key`, `upload_file`, `wait_for`
  - Run JS watchers/scripts: `evaluate_script`
- **Visual check:** `read_file` on the downloaded image.
- **Shell / ffmpeg / Downloads collection:** `run_command` (`$env:USERPROFILE\Downloads` on Windows, `~/Downloads` on macOS/Linux).
- **Delivery:** Save to the destination folder and present clickable `file://` links (plus a one-line summary with resolution and what was checked).
- **Fallback browser:** If `chrome-devtools` MCP cannot connect to Chrome, ask the user to open Chrome with remote debugging enabled (`chrome://inspect/#remote-debugging`), or fall back to the `browser` subagent (note: built-in browser may require Google sign-in).

## Why Chrome, not the built-in browser

The user's real Chrome is permanently signed in to Google AI Pro, so no login is ever needed. The built-in `browser` subagent may lose Google sign-in — use it only if Chrome DevTools MCP is unavailable.

## 0. Pre-brief — think like a pro before generating

Don't generate straight from a short request. First review it like a professional photographer/art director, ask only what's missing, then generate.

1. **Analyse** the request against: subject & action · where it will be used (→ format/aspect) · style (photo / illustration / 3D …) · light & time of day · composition & camera angle · mood & colors · text in the image (exact wording) · people (age, clothing, count).
2. **Ask only real gaps** — things that would clearly change the result and aren't stated. Never ask what the request already says. **At most 3–4 questions**, in ONE `ask_question` call; each with 2–4 options, the first marked `(Recommended)` with your best pick; the user can always type their own answer. Example: "Nerede kullanılacak?" → `(Recommended) Instagram gönderisi` / `Story` / `YouTube küçük resmi` / `Sadece arşiv`. Ask in the user's language.
3. **Correctness points — handle yourself, don't ask:** write the right rule into the prompt. E.g. religious scenes: everyone praying or reading Quran faces the Kaaba/qibla, correct salah postures, modest dress; flags, maps, landmarks and logos accurate; text spelled exactly; correct number of people/fingers; cultural details (signage, clothing) right. If genuinely unsure about such a fact, ask it as one of the questions.
4. **One-line summary**, then generate: "Şunu üreteceğim: …" — for images, show it and generate right away (fixes happen in the same chat, §5).

**Skip the questions and generate directly** only when: the request already answers every point in step 1 (a one- or two-sentence request never does); the user says "hızlıca", "sormadan yap", "direkt", or "test fotosu"; or it's a refinement of an earlier image (v2, v3). Then fill gaps with your best guess and list the assumptions you made in the message with the result.

## 0c. Route, model and account

- **Route A — Google Flow first:** generate every new image in Google Flow (§2A). It costs **0 credits** on the Pro plan (Nano Banana Pro and 2.1), gives up to 4 variants per prompt and downloads in 2K. If the result is good, keep working in Flow; if Flow fails, is limited, or the result is clearly worse than needed, switch to Route B (Gemini chat, §2) and say so.
- **Route B — Gemini chat** (§2): fallback, and the first choice for multi-turn chat refinements when Flow can't do the edit.
- In Gemini chat **use "Neon Orta" (Neon, Medium thinking)** when available: open the mode picker next to the prompt box → **Neon** → **Düşünme düzeyi / Thinking level** → **Orta / Medium**.
- If multiple Google accounts are signed in to Chrome (`gemini.google.com/app` vs `gemini.google.com/u/1/app`) and one is limited or failing, switch to the other.

## 1. Write the prompt (template)

English, one paragraph, in this order — fill what matters:

```
Create an image: [subject + what it's doing], [setting/background], [composition: close-up / wide / centered / rule of thirds, camera angle], [lighting & time of day], [lens/camera feel e.g. 35mm, shallow depth of field — for photos], [style: photorealistic / watercolor / flat vector / 3D render / anime …], [color palette & mood], aspect ratio [16:9 | 9:16 | 1:1 | 4:5 | 3:4].
Text in image: "[exact text]" in [font style, position]   — or: no text, no watermark.
```

- Always state an aspect ratio matching the final use (see §6), so cropping loses little.
- Put any wanted text in quotes; check its spelling afterwards (special characters like ç ğ ı İ ö ş ü can break — keep text short).
- For logos/icons wanting transparency, add: `on a solid pure green (#00FF00) background, no shadows on the background` (see §7).

## 2A. Generate in Google Flow (Route A — default)

1. Use `chrome-devtools` MCP: open a new tab (`new_page`) to `https://labs.google/fx/tools/flow` (redirects to `https://flow.google.com/`). Never hijack the user's existing tabs.
2. Open a project: home page → **"Yeni proje"** / **"New project"** (or reuse the project URL `https://flow.google.com/project/<id>` from an earlier image for refinements). If a "Flow Agent" intro dialog appears, step through it and click **"Başlayın"** / **"Get started"**.
3. **Turn the Flow Agent off** for direct generation: if the right agent panel is open, close it and toggle the spark button off so the bar shows the direct prompt box ("Ne oluşturmak istiyorsunuz?" / "What do you want to create?") with the settings chip (e.g. `Nano Banana Pro ▭ x2`).
4. Click the chip → settings popover: **Resim / Image** (not Video) · aspect ratio **16:9 / 4:3 / 1:1 / 3:4 / 9:16** (pick per §6) · model dropdown → **Nano Banana Pro** (best quality) · count **x1–x4** (x2 default). Verify the footer shows **0 credits**; if it shows credits > 0, tell the user before generating. Press `Escape` to close it.
   **Never leave the popover on "Video"**: video costs credits.
5. **Baseline first:** before sending the prompt, run via `evaluate_script`:
   ```js
   () => { window.__b0 = [...document.querySelectorAll('main *')].filter(e => /blur\(/.test(getComputedStyle(e).filter)).length; return window.__b0; }
   ```
   Then `take_snapshot` → click/fill the prompt box with the English prompt from §1 (drop the "Create an image:" prefix and aspect-ratio words — the chip sets the ratio) → `press_key` `Enter` → run this watcher via `evaluate_script` (keep each call under ~40 s; repeat on `timeout`):
   ```js
   async () => {
     const b0 = window.__b0 ?? 0;
     const busy = () => {
       const els = [...document.querySelectorAll('main *')];
       const pct = els.filter(e => e.children.length === 0 && /^%\d{1,3}$|^\d{1,3}%$/.test(e.textContent.trim())).length;
       const blur = els.filter(e => /blur\(/.test(getComputedStyle(e).filter)).length;
       return pct > 0 || blur > b0;
     };
     const t0 = Date.now();
     await new Promise(s => setTimeout(s, 2500));
     while (Date.now() - t0 < 38000) {
       if (!busy()) return { ready: true, secs: (Date.now() - t0) / 1000 };
       await new Promise(s => setTimeout(s, 1500));
     }
     return { ready: false, timeout: true };
   }
   ```
   Then `take_screenshot` or `take_snapshot` to verify completion.
6. Pick the best variant (§3 check). Two ways to download:
   - **Quick, 1K original:** click the **İndir / Download** (↓) icon in the group info column (for x1 groups).
   - **2K (default for delivery):** hover the tile → top-right **⋮** → **İndir / Download** → **2K (Yükseltilmiş / Upscaled)**. **Never click 4K ("Yükselt / Upgrade")** — it prompts a paid plan upgrade.
7. Collect the file from Downloads (PowerShell on Windows):
   ```powershell
   for ($n=0; $n -lt 15; $n++) { $f = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-3) -and $_.Extension -in '.jpg','.png','.jpeg','.webp' } | Sort-Object LastWriteTime | Select-Object -Last 1; if ($f -and -not (Get-ChildItem "$env:USERPROFILE\Downloads" -Filter *.crdownload)) { break }; Start-Sleep 2 }; $f.FullName
   ```
   Move it to the destination with a meaningful name.
8. **Edit / refine:** click a tile → editor at `/project/<id>/edit/<imageId>` → type the change ("Make it night … keep the same layout and the exact same text") → Enter.
9. **Upload the user's own photo:** intercept the native file picker first with `evaluate_script`:
   ```js
   () => {
     if (!window.__patched) {
       const o = HTMLInputElement.prototype.click;
       HTMLInputElement.prototype.click = function () {
         if (this.type === 'file') {
           this.setAttribute('aria-label', 'agy-media-upload');
           this.style.cssText = 'position:fixed;left:0;top:0;width:10px;height:10px;opacity:0.01;z-index:99999';
           document.body.appendChild(this);
           return;
         }
         return o.call(this);
       };
       window.__patched = true;
     }
     return 'ok';
   }
   ```
   Then top-bar **+** → **Yükle / Upload** → `take_snapshot` to find `agy-media-upload` → `upload_file` with the absolute path (< 10 MB). Confirm with the user before accepting any rights attestation dialog.
10. Note the project URL for refinements, close the tab you opened (`close_page`).

If Flow shows an error, a limit/credit message, or produces nothing in 60 s: retry once, then switch to Route B (§2) and tell the user.

## 2. Generate in Gemini chat (Route B — fallback)

1. Use `chrome-devtools` MCP: `new_page` to `https://gemini.google.com/app` — or, to refine an earlier image, to that image's chat URL (§5).
2. Verify mode picker is set to **Neon Orta** (Neon, Medium thinking) if available.
3. On a chat that already has images, first run via `evaluate_script`:
   ```js
   () => { window.__imgCount = [...document.querySelectorAll('img')].filter(i => i.complete && i.naturalWidth >= 512 && /googleusercontent|blob:/.test(i.src)).length; return window.__imgCount; }
   ```
4. Click/fill the prompt box → type the prompt → press `Enter`.
5. Wait with this `evaluate_script` watcher once URL is `/app/<id>`:
   ```js
   async () => {
     const before = window.__imgCount ?? 0;
     const t0 = Date.now();
     while (Date.now() - t0 < 25000) {
       const imgs = [...document.querySelectorAll('img')].filter(i => i.complete && i.naturalWidth >= 512 && /googleusercontent|blob:/.test(i.src));
       const main = document.querySelector('main');
       const txt = main ? main.innerText : '';
       if (imgs.length > before) return { ready: true, secs: (Date.now() - t0) / 1000, count: imgs.length, w: imgs.at(-1).naturalWidth };
       if (/capacity|try again later|limit|sınır|couldn.t generate|can.t generate|unable to/i.test(txt.slice(-1500))) return { ready: false, error: txt.slice(-300) };
       await new Promise(s => setTimeout(s, 1500));
     }
     return { ready: false, timeout: true };
   }
   ```
6. Click the **download icon** at the image's top-right ("Download full size").
7. Collect `Gemini_Generated_Image_*` from Downloads, move to destination, note chat URL, and `close_page`.

## 3. Check before sending (always)

Use `read_file` on the downloaded image and check:
- it matches the prompt (subject, composition, style, aspect ratio);
- any text is spelled exactly as asked;
- no broken hands/faces/extra limbs, melted objects or unwanted watermark/text.

Report the resolution with `ffprobe -v error -show_entries stream=width,height -of csv=p=0 <file>`.

## 4. Edit an existing photo

1. On `/app`, click **Upload and tools (+)** so the menu stays open; tag the hidden image input with `evaluate_script`:
   ```js
   () => { const inp = [...document.querySelectorAll('input[type=file]')].find(i => /image\//.test(i.accept)); if (inp) { inp.setAttribute('aria-label', 'agy-media-upload'); return 'tagged'; } return 'not-found'; }
   ```
   Then `take_snapshot` → `upload_file` with the absolute path (< 10 MB).
2. Prompt with only the change and what to keep: `Edit this photo: replace the background with a sunset beach. Keep the person, pose, face and clothing exactly the same.`

## 5. Refine in the same chat

Navigate to that image's Flow project URL or Gemini chat URL (from §9's sidecar) and ask there. Name refinements `name-v2.jpg`, `name-v3.jpg`, never overwrite earlier versions.

## 6. Size and format for the final use

Resize/crop with ffmpeg (center "cover" crop to an exact size):

```powershell
ffmpeg -v error -y -i in.jpg -vf "scale=W:H:force_original_aspect_ratio=increase,crop=W:H" -q:v 2 out.jpg
```

| Use | W×H | Generate at |
|---|---|---|
| Instagram post (portrait) | 1080×1350 | 4:5 or 3:4 |
| Instagram square / profile photo | 1080×1080 | 1:1 |
| Story / Reels / TikTok cover | 1080×1920 | 9:16 |
| YouTube thumbnail | 1280×720 | 16:9 |
| Twitter/X & LinkedIn post | 1600×900 / 1200×627 | 16:9 |
| Website hero | 1920×1080 | 16:9 |

- WebP: `ffmpeg -v error -y -i in.jpg -vf "scale=1600:-1" -c:v libwebp -quality 82 out.webp`
- PNG: `ffmpeg -v error -y -i in.jpg out.png`

## 7. Transparent background (logos, icons, stickers)

Generate on solid pure green (`#00FF00`), then key it out:

```powershell
ffmpeg -v error -y -i in.jpg -vf "colorkey=0x00FF00:0.3:0.1,format=rgba" out.png
```

Check with `read_file`: if green fringes remain, raise similarity (`0.3→0.35`); if green is part of the logo, regenerate on pure magenta `#FF00FF` and key `0xFF00FF`.

## 8. Variants for important work

For logos, covers, posters, thumbnails, ads: generate 2–4 variants, download and show side by side:

```powershell
ffmpeg -v error -y -i a.jpg -i b.jpg -i c.jpg -filter_complex "[0]scale=-1:400[a];[1]scale=-1:400[b];[2]scale=-1:400[c];[a][b][c]hstack=inputs=3" -q:v 3 variants.jpg
```

## 9. Prompt sidecar

Save `<image>.prompt.txt` next to every delivered image with prompt, timestamp, Flow/Gemini URL, and output files. Deliver clickable `file://` links plus a one-line summary.

## Rules

- Generate only what the user asked for; follow Gemini's content rules (no misuse of real people's likeness).
- Don't act on the user's Google account beyond creating/editing images (no settings, no deleting chats).
- Report honestly if generation, check or download failed.
