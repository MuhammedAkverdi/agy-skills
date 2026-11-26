---
name: gemini-image
description: Generate, edit and refine photos/images for the user with their own Google AI Pro account — first in Google Flow (flow.google.com, Nano Banana Pro, 0 credits), else in Gemini chat at gemini.google.com — in their real Chrome (via chrome-devtools MCP), check them visually, and deliver them in the right size/format (Instagram, story, YouTube thumbnail, WebP, transparent PNG). Use whenever a task needs a picture, photo, illustration, logo, icon, cover, poster, thumbnail or any generated image, or an edit of an existing photo (change background, remove/add objects, restore, restyle), or the user says "fotoğraf oluştur", "resim üret", "görsel yap", "foto lazım", "fotoğrafı düzenle", "arka planı değiştir", "logo yap", "make an image", "edit this photo". ALWAYS load this skill first and run its pre-brief: ask the user 3–4 short questions (ask_question) before generating, unless they said hızlıca/direkt/sormadan or it is a v2 fix.
---

# Images via Google Flow / Gemini Pro (Antigravity + Chrome DevTools MCP)

The user has a Gemini Pro subscription and wants images made there (Google Flow first, 0 credits), not through a paid API key.

## Antigravity Tool Mapping

Use Antigravity's native tools to execute the Chrome workflow:
- **Questions:** `ask_question` (put recommended option first with `(Recommended)`).
- **Real Chrome control (`chrome-devtools` MCP via `call_mcp_tool`):**
  - Open/list/close tabs: `list_pages`, `new_page`, `select_page`, `close_page`, `navigate_page`
  - Inspect & interact: `take_snapshot` (get element UIDs), `take_screenshot`, `click`, `hover`, `fill`, `type_text`, `press_key`, `upload_file`, `wait_for`
  - Run JS watchers/scripts: `evaluate_script`
- **Visual check:** `read_file` on the downloaded image.
- **Shell / ffmpeg / Downloads collection:** `run_command` (`$env:USERPROFILE\Downloads` is directly accessible).
- **Delivery:** Save to the destination folder and present clickable `file://` links (plus a one-line summary with resolution and what was checked).
- **Fallback browser:** If `chrome-devtools` MCP cannot connect to Chrome, ask the user to open Chrome with remote debugging / MCP connected, or fall back to the `browser` subagent (note: built-in browser may require Google sign-in).

## Why Chrome, not the built-in browser

The user's real Chrome is permanently signed in to Gemini Pro, so no login is ever needed. The built-in `browser` subagent may lose Google sign-in — use it only if Chrome DevTools MCP is unavailable.

## 0. Pre-brief — think like a pro before generating (user-approved 2026-11-25)

Don't generate straight from a short request. First review it like a professional photographer/art director, ask only what's missing, then generate.

1. **Analyse** the request against: subject & action · where it will be used (→ format/aspect) · style (photo / illustration / 3D …) · light & time of day · composition & camera angle · mood & colors · text in the image (exact wording) · people (age, clothing, count).
2. **Ask only real gaps** — things that would clearly change the result and aren't stated. Never ask what the request already says. **At most 3–4 questions**, in ONE `ask_question` call; each with 2–4 options, the first marked `(Recommended)` with your best pick; the user can always type their own answer. Example: "Nerede kullanılacak?" → `(Recommended) Instagram gönderisi` / `Story` / `YouTube küçük resmi` / `Sadece arşiv`. Ask in the user's language (Turkish).
3. **Correctness points — handle yourself, don't ask:** write the right rule into the prompt. E.g. religious scenes: everyone praying or reading Quran faces the Kaaba/qibla, correct salah postures, modest dress; flags, maps, landmarks and logos accurate; text spelled exactly; correct number of people/fingers; cultural details (Turkish signage, clothing) right. If genuinely unsure about such a fact, ask it as one of the questions.
4. **One-line summary**, then generate: "Şunu üreteceğim: …" — for images, show it and generate right away (fixes happen in the same chat, §5).

**Skip the questions and generate directly** only when: the request already answers every point in step 1 (a one- or two-sentence request never does); the user says "hızlıca", "sormadan yap", "direkt", or "test fotosu"; or it's a refinement of an earlier image (v2, v3). Then fill gaps with your best guess and list the assumptions you made in the message with the result.

After delivery, if the user points out a mistake that a correctness rule would have caught, add that rule to the list in step 3.

## 0c. Route, model and account

- **Route A — Google Flow first (user rule 2026-11-25):** generate every new image in Google Flow (§2A). It costs **0 credits** on the Pro plan (Nano Banana Pro and 2.1), gives up to 4 variants per prompt and downloads in 2K. Full test 2026-11-25: Turkish text ("ÇAY SAATİ", "Her gün 17:00") spelled right in 4/4 variants; edit-in-place kept layout and text; green-screen logo → transparent PNG via §7 worked. If the result is good, keep working in Flow; if Flow fails, is limited, or the result is clearly worse than needed, switch to Route B (Gemini chat, §2) and say so.
- **Route B — Gemini chat** (§2): fallback, and the first choice for multi-turn chat refinements when Flow can't do the edit.
- In Gemini chat **always use "Neon Orta" (Neon, Medium thinking)** — user rule 2026-11-25. Before sending: open the mode picker next to the prompt box → **Neon** → **Düşünme düzeyi / Thinking level** → **Orta / Medium**; the picker then reads "Neon Orta".
- Chrome has two Pro accounts: `gemini.google.com/app` (account 0, English UI) and `gemini.google.com/u/1/app` (account 1, Turkish UI). If one is limited or failing, use the other.

## 1. Write the prompt (template)

English, one paragraph, in this order — fill what matters:

```
Create an image: [subject + what it's doing], [setting/background], [composition: close-up / wide / centered / rule of thirds, camera angle], [lighting & time of day], [lens/camera feel e.g. 35mm, shallow depth of field — for photos], [style: photorealistic / watercolor / flat vector / 3D render / anime …], [color palette & mood], aspect ratio [16:9 | 9:16 | 1:1 | 4:5 | 3:4].
Text in image: "[exact text]" in [font style, position]   — or: no text, no watermark.
```

- Always state an aspect ratio matching the final use (see §6), so cropping loses little.
- Put any wanted text in quotes; check its spelling afterwards (Turkish characters ç ğ ı İ ö ş ü often break — keep text short).
- For logos/icons wanting transparency, add: `on a solid pure green (#00FF00) background, no shadows on the background` (see §7).

## 2A. Generate in Google Flow (Route A — default)

Verified live 2026-11-25 (account shows "PRO", Turkish UI; first-visit welcome + privacy-policy screens already accepted).

1. Use `chrome-devtools` MCP: open a new tab (`new_page`) to `https://labs.google/fx/tools/flow` (redirects to `https://flow.google.com/`). Never hijack the user's existing tabs.
2. Open a project: home page → **"Yeni proje"** (or reuse the project URL `https://flow.google.com/project/<id>` from an earlier image for refinements). If a "Flow Agent" intro dialog appears: click the → arrow until **"Başlayın"**, then click it.
3. **Turn the Flow Agent off** for direct generation: if the bottom bar says "Hedefinizi tarif edin" and the right agent panel is open, close the panel ("Kapat") and click the spark toggle next to the → button (tooltip "Flow ajanını etkinleştir" = off). The bar then reads "Ne oluşturmak istiyorsunuz?" with a chip like `Nano Banana Pro ▭ x2`.
4. Click the chip → settings popover: **Resim** (not Video) · aspect ratio **16:9 / 4:3 / 1:1 / 3:4 / 9:16** (pick per §6) · model dropdown → **Nano Banana Pro** (best quality; "Nano Banana 2.1" has Düşük/Orta/Yüksek thinking, "2 Lite" is fastest) · count **x1–x4** (x2 default). The footer must read "Üretme işlemi için **0 kredi** kullanılır"; if it shows credits > 0, tell the user before generating. Press `Escape` to close it.
   Settings persist per project (model, ratio, count, agent off) — still check the chip text before sending. **Never leave the popover on "Video"**: video costs credits (below).
5. **Baseline first (fix 2026-11-26):** before sending the prompt, run via `evaluate_script`:
   ```js
   () => { window.__b0 = [...document.querySelectorAll('main *')].filter(e => /blur\(/.test(getComputedStyle(e).filter)).length; return window.__b0; }
   ```
   Then `take_snapshot` → click/fill the prompt box ("Ne oluşturmak istiyorsunuz?") with the English prompt from §1 (drop the "Create an image:" prefix and aspect-ratio words — the chip sets the ratio) → `press_key` `Enter` → run this watcher via `evaluate_script` (keep each call under ~40 s; repeat on `timeout`):
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
   Then `take_screenshot` (sharp tiles mean done). Measured: Nano Banana Pro x2 ~25 s, Pro x4 (9:16) ~20–30 s, 2.1 edit ~15 s. Counting `<img>` tags does NOT work (blurred previews are already real images).
6. Pick the best variant (§3 check on the screenshot). Two ways to download:
   - **Quick, 1K original:** the grid is grouped by prompt; the **İndir** (↓) icon in the right-hand info column of that group downloads immediately (1024×1024 for 1:1, ~370 KB). For x1 groups only — with several variants use the tile menu.
   - **2K (default for delivery):** hover the tile → top-right **⋮ (Diğer seçenekler)** → **İndir** → **2K (Yükseltilmiş)**. Toast "Resminiz yükseltiliyor…", download starts by itself in ~5 s. 1K = original. **4K shows "Yükselt" = plan upgrade — never click it** (it leads to buying a higher plan).
7. Collect the file — Chrome saves `<Title_words>_<hex>_2K.jpg` (e.g. `Ginger_cat_sitting_on_windowsill_37d55576_2K.jpg`, 2752×1536 for 16:9):
   ```powershell
   for ($n=0; $n -lt 15; $n++) { $f = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-3) -and $_.Extension -in '.jpg','.png','.jpeg','.webp' } | Sort-Object LastWriteTime | Select-Object -Last 1; if ($f -and -not (Get-ChildItem "$env:USERPROFILE\Downloads" -Filter *.crdownload)) { break }; Start-Sleep 2 }; $f.FullName
   ```
   `Move-Item` it to the destination with a meaningful name.
8. **Edit / refine (verified):** click a tile → editor at `/project/<id>/edit/<imageId>` with the box **"Neyi değiştirmek istiyorsunuz?"**. Type the change ("Make it night … keep the same layout and the exact same text") → Enter → ~15–25 s. History of versions is on the right ("Geçmişi gizle" toggles it); top bar has ♡, share, delete, **↓ download (1K/2K)**, **Bitti** (back to grid); left has a crop tool. If the edit box shows a small attached thumbnail you didn't intend, remove it with its ✕ first. Tile ⋮ also has "İsteme ekle" (use as reference in a new prompt), "İstemi yinele" (re-run), "Animasyon ekle" (video — costs credits).
9. **Upload the user's own photo (verified end to end 2026-11-25):** intercept the native file picker first with `evaluate_script`:
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
   Then top-bar **+ (Medya menüsü ekle)** → **Yükle** → `take_snapshot` to find the `agy-media-upload` file input → `upload_file` with the absolute path (png/jpg/webp/gif/heic, < 10 MB). Flow then shows **"Bu resmin kullanım hakları"** (confirm you have the rights) with **İptal / Kabul ediyorum** — confirm with the user in chat before clicking "Kabul ediyorum" unless they already approved it in this session. The photo uploads (~10 s) under **Yüklemeler** in the sidebar; click it → editor (step 8) → type the change → ~20 s.
10. Other Flow features & Multi-Reference consistency (verified 2026-11-26): **Karakterler** (consistent faces), **Sahneler**, **Kitaplık** collections.
    - **Multi-ref workflow:** Generate a dedicated Character/Prop/Location Reference Bible first, then attach matching Bible refs via main-grid `⋮ -> İsteme ekle` or `+ -> Öğe arayın` (`thumbId`). Note that `CDK-VIRTUAL-SCROLL-VIEWPORT` in the `+` picker uses signed `storage.googleapis.com` URLs, while main grid tiles (`main img[alt="Kullanıcının resmini gösteren kutu"]`) use `flow.google.com/asb/...`.
    - **Style Lock bleed guard:** Keep wardrobe, hair, and props OUT of shared `Style Lock` strings (specify camera/lens/lighting/color/film stock only), otherwise unrelated prop/location shots inherit the character's jacket or face.
    - **35mm film-gate corners:** Prompts mentioning "35mm film" or vintage film frames can produce tiny dark rounded corners; apply a ~3.5% overscan scale+crop in assembly when clean full-bleed frames are needed.
11. Note the project URL for refinements, close the tab you opened (`close_page`).

**Credits (account panel: click the PRO badge):** images = **0 credits** with every Nano Banana model, x1–x4. Video in Flow costs credits: Omni 1.2 Flash 720p 8 s = 24, Veo 3.1 Lite = 10 per clip; the Pro plan has ~1,050 credits per month. Never start a video here without the user's OK and the cost stated.

If Flow shows an error, a limit/credit message, or produces nothing in 60 s: retry once, then switch to Route B (§2) and tell the user.

## 2. Generate in Gemini chat (Route B — fallback)

1. Use `chrome-devtools` MCP: `new_page` to `https://gemini.google.com/app` — or, to refine an earlier image, to that image's chat URL (§5). Take a screenshot to verify signed-in "Pro" status.
2. Verify mode picker is set to **Neon Orta** (Neon, Medium thinking).
3. On a chat that already has images, first run via `evaluate_script`:
   ```js
   () => { window.__imgCount = [...document.querySelectorAll('img')].filter(i => i.complete && i.naturalWidth >= 512 && /googleusercontent|blob:/.test(i.src)).length; return window.__imgCount; }
   ```
4. Click/fill the "Ask Gemini" box → type the prompt → press `Enter`.
5. Wait with this `evaluate_script` watcher once URL is `/app/<id>` (images take < 20 s):
   ```js
   async () => {
     const before = window.__imgCount ?? 0;
     const t0 = Date.now();
     while (Date.now() - t0 < 25000) {
       const imgs = [...document.querySelectorAll('img')].filter(i => i.complete && i.naturalWidth >= 512 && /googleusercontent|blob:/.test(i.src));
       const txt = document.body.innerText;
       if (imgs.length > before) return { ready: true, secs: (Date.now() - t0) / 1000, count: imgs.length, w: imgs.at(-1).naturalWidth };
       if (/capacity|try again later|limit|sınır|couldn.t generate|can.t generate|unable to/i.test(txt.slice(-1500))) return { ready: false, error: txt.slice(-300) };
       await new Promise(s => setTimeout(s, 1500));
     }
     return { ready: false, timeout: true };
   }
   ```
6. Click the **download icon** at the image's top-right ("Download full size"), wait for the "Image downloaded" toast.
7. Collect the file — Chrome saves `Gemini_Generated_Image_<id>.jpg`:
   ```powershell
   for ($n=0; $n -lt 10; $n++) { $f = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter 'Gemini_Generated_Image_*' -File | Where-Object LastWriteTime -gt (Get-Date).AddMinutes(-3) | Sort-Object LastWriteTime | Select-Object -Last 1; if ($f -and -not (Get-ChildItem "$env:USERPROFILE\Downloads" -Filter *.crdownload)) { break }; Start-Sleep 2 }; $f.FullName
   ```
   `Move-Item` it to the destination with a meaningful name. Note the chat URL for §5 and §9, then `close_page`.

## 3. Check before sending (always)

Use `read_file` on the downloaded image and check:
- it matches the prompt (subject, composition, style, aspect ratio);
- any text is spelled exactly as asked;
- no broken hands/faces/extra limbs, melted objects or unwanted watermark/text.

If it clearly misses, refine in the same chat (§5) once and say so; if still wrong, show it and tell the user what's off. Report the resolution with `ffprobe -v error -show_entries stream=width,height -of csv=p=0 <file>`.

## 4. Edit an existing photo

Gemini edits uploaded photos: change/replace background, remove or add objects, restore/colorize old photos, change style, adjust lighting/season.

1. On a new chat (`/app`) — never click "Upload files" directly (opens native OS picker). Click **Upload and tools (+)** so the menu stays open; tag the hidden image input with `evaluate_script`:
   ```js
   () => { const inp = [...document.querySelectorAll('input[type=file]')].find(i => /image\//.test(i.accept)); if (inp) { inp.setAttribute('aria-label', 'agy-media-upload'); return 'tagged'; } return 'not-found'; }
   ```
   Then `take_snapshot` → `upload_file` with the absolute path (< 10 MB). A thumbnail appears in the prompt box.
2. Prompt with only the change and what to keep: `Edit this photo: replace the background with a sunset beach. Keep the person, pose, face and clothing exactly the same.`
3. Continue with §2 steps 5–7 and §3; compare against the original.

## 5. Refine in the same chat

For changes to an image already made ("warmer", "move the fox left", "remove the text", "same style, now at night"), navigate to that image's Flow project URL or Gemini chat URL (from §9's sidecar or this conversation) and ask there. Name refinements `name-v2.jpg`, `name-v3.jpg`, never overwrite earlier versions.

## 6. Size and format for the final use

Gemini output: 16:9 ≈ 2752×1536 (other ratios differ). Resize/crop with ffmpeg (verified). Center "cover" crop to an exact size:

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

- WebP for the web: `ffmpeg -v error -y -i in.jpg -vf "scale=1600:-1" -c:v libwebp -quality 82 out.webp`
- PNG: `ffmpeg -v error -y -i in.jpg out.png`
- Smaller JPEG: raise `-q:v` (2 = best … 5 = smaller).
If the crop would cut the subject, regenerate at the right ratio instead (say why). Keep the full-size original next to resized copies.

## 7. Transparent background (logos, icons, stickers)

Gemini can't output real transparency. Generate on solid pure green (§1), then key it out (verified):

```powershell
ffmpeg -v error -y -i in.jpg -vf "colorkey=0x00FF00:0.3:0.1,format=rgba" out.png
```

Check the result (`read_file`): if green fringes remain, raise similarity (0.3→0.35); if parts of the subject vanish (green in the logo), regenerate on pure magenta `#FF00FF` and key `0xFF00FF`. Optionally trim: add `,crop=...` after checking bounds.

## 8. Variants for important work

For logos, covers, posters, thumbnails, ads: generate 2–3 different interpretations (or Flow x2–x4), download all, show them side by side and let the user choose:

```powershell
ffmpeg -v error -y -i a.jpg -i b.jpg -i c.jpg -filter_complex "[0]scale=-1:400[a];[1]scale=-1:400[b];[2]scale=-1:400[c];[a][b][c]hstack=inputs=3" -q:v 3 variants.jpg
```

Then refine only the chosen one (§5). For quick one-off images, one generation is enough.

## 9. Prompt sidecar

Save next to every delivered image:

```powershell
Set-Content "<image>.prompt.txt" "<prompt>`nGenerated: $(Get-Date -Format s) via Gemini Pro`nChat: <gemini or flow url>`nOutputs: <files incl. resized copies>" -Encoding UTF8
```

Deliver the file paths as clickable `file://` links plus a one-line summary (resolution, what was checked).

## Fallback: Antigravity `image-generator` subagent

If Chrome / Flow / Gemini chat are completely unavailable and the user wants an immediate result, offer to use the built-in `image-generator` subagent (note: it does not use Google Flow's Nano Banana Pro 2K pipeline).

## Self-Revision on Errors (Mandatory)

If any error, Flow/Gemini UI/DOM change, broken watcher/selector, download/upload failure, or visual consistency trap happens while using this skill and you diagnose or fix it, **immediately revise this `SKILL.md`** (recording the root cause and verified fix) before completing the task, and report the skill update to the user.

## Rules

- Generate only what the user asked for; follow Gemini's content rules (no misuse of real people's likeness).
- Don't act on the user's Google account beyond creating/editing images (no settings, no deleting chats).
- Report honestly if generation, check or download failed.
