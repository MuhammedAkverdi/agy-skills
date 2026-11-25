---
name: gemini-video
description: Generate short AI video clips for the user with their own Gemini Pro account (Veo) at gemini.google.com/videos in their real Chrome (via chrome-devtools MCP), check them frame by frame, and join several clips into a longer video with ffmpeg. Use whenever a task needs a generated video clip, animation, b-roll, reel/short, moving shot or an animated version of an image, or the user says "video oluştur", "video üret", "video yap", "klip yap", "fotoğrafı hareketlendir", "make a video", "generate a video clip". When a video needs a separate soundtrack (joined clips, Reels, ads, or the user asks for music), it calls the `gemini-music` skill. ALWAYS load this skill first and run its pre-brief: ask the user short questions (ask_question) and get approval before generating, unless they said hızlıca/direkt/sormadan.
---

# Video generation via Gemini Pro (Antigravity + Chrome DevTools MCP)

The user has a Google AI Pro subscription and wants clips made there (Veo), not through a paid API key. Same rules as the `gemini-image` skill.

Activity log: `~/.gemini/config/skills/gemini-video/usage-log.csv` (records past clip history only — **never** use it to estimate remaining video quota).

## Antigravity Tool Mapping

- **Questions & Approval:** `ask_question` (put recommended option first with `(Recommended)`).
- **Real Chrome control (`chrome-devtools` MCP via `call_mcp_tool`):** `new_page`, `navigate_page`, `take_snapshot`, `take_screenshot`, `click`, `hover`, `fill`, `type_text`, `press_key`, `upload_file`, `evaluate_script`, `close_page`.
- **Visual check:** `read_file` on the generated 2×2 contact sheet.
- **Downloads & ffmpeg:** `run_command` (`$env:USERPROFILE\Downloads` on Windows, `~/Downloads` on macOS/Linux).
- **Activity log (`~/.gemini/config/skills/gemini-video/usage-log.csv`):** Use `read_file` to read and `write_file` (`Append: true`) to append.
- **Delivery:** Save to the destination folder and present clickable `file://` links.

## 0. Before generating — live usage limit & plan

- Gemini Pro video has **no fixed daily cap** — availability depends on the **rolling 5-hour overall usage percentage** (for example, video generation can disable automatically when 5-hour usage climbs toward ~80–85%, even if few videos were made).
- **`usage-log.csv` is history only** — do **not** use it to calculate or promise remaining quota (the user's chats and overall usage percentage determine the limit).
- **Check live availability in Chrome before promising clips:** inspect `https://gemini.google.com/videos` and, if disabled and multiple Pro accounts are signed in, `https://gemini.google.com/u/1/videos` (or check `+ → More tools → Create video` / `Video oluştur` on `/app`). Verify whether the video prompt box and tool are enabled (if greyed out or disabled, that account's 5-hour window is exhausted) and read any visible usage/reset message. Report the live status honestly.
- No throwaway or duplicate clips — always do the pre-brief (§0b) first.
- Verified clip spec: **10 s, 1280×720, H.264 MP4 with audio.** For anything longer, plan N clips (see §6) and say so.
- If the look must be exact (a product, a character, a specific scene), use **image-first** (§5): make and approve a still with `gemini-image` (Google Flow first), then animate it.

**Model — use "Neon Orta" (Neon, Medium thinking) when available.** Open the mode picker next to the prompt box ("Open mode picker" / "Mod seçiciyi aç") → **Neon** → **Düşünme düzeyi / Thinking level** → **Orta / Medium**.

**Multiple Google accounts in Chrome:** If the user has more than one Pro account signed in (`gemini.google.com/videos` vs `gemini.google.com/u/1/videos`) and one account's video tools are disabled (greyed out), switch to the other.

**Capacity error ≠ quota:** "I'm experiencing unusually high traffic right now generating videos and am at full capacity. Please try again later." is Google-side load. Retry at most once after ~30 s, then stop and offer to try later.

## 0b. Pre-brief — think like a pro before generating

Don't generate straight from a short request. First review it like a professional director/cinematographer, ask only what's missing, then generate.

1. **Analyse** the request against: subject & action (one main action per 10 s clip) · where it will be used (→ Landscape 16:9 or Portrait 9:16) · style (cinematic real / 3D animation / anime …) · light & time of day · **camera move** (drone, dolly-in, orbit, static, handheld) · mood & colors · **audio** (ambient, music mood; a separate soundtrack made with the `gemini-music` skill when it adds something → §6 "Background music") · **dialogue** (exact line, who says it) · length (one clip or several → §6) · text on screen.
2. **Ask only real gaps — topic-adaptive (up to max 6):** Decide dynamically how many questions are needed for strong scene & visual consistency (**max 6 questions** in ONE `ask_question` call; use fewer if the request is already detailed). Never use fixed boilerplate options — tailor every option for style, camera move, lighting, and audio specifically to the video's subject. Put `(Recommended)` first on each question and ask in the user's language.
3. **Correctness points — handle yourself, don't ask:** write the right rule into the prompt. E.g. religious scenes: everyone praying or reading Quran faces the Kaaba/qibla, correct salah postures, modest dress; flags, maps, landmarks and logos accurate; spoken lines and on-screen text exact; physically plausible motion; cultural details right.
4. **Summary + approval** (video quota is scarce): show "Şunu üreteceğim: …" with the final settings (aspect, style, camera, audio, live Veo account availability from §0) and **wait for the user's OK** before generating. Use `ask_question` with `(Recommended) Üret` / `Değiştir`.

**Skip the questions** when: the request is already detailed; the user says "hızlıca", "sormadan yap", "direkt", or "test videosu"; or it's a redo/variation of an earlier clip.

## 1. Write the prompt (template)

Write in English, one paragraph, in this order — fill what matters, skip the rest:

```
[Shot type & camera move] of [subject] [doing action] in [setting], [time of day / lighting], [style: photorealistic / cinematic / 3D animation / anime …], [mood & color palette].
Audio: [ambient sounds / music mood]. Dialogue: "[exact spoken line]" said by [who].
```

Tips: one main action per 10 s clip; name the camera move (slow dolly-in, drone rising, orbit, handheld, static tripod); quote dialogue exactly; say "no text on screen" if text would be unwanted; for reels choose Portrait.

## 2. Generate in Chrome

The user's real Chrome is permanently signed in to Google AI Pro. Don't use the built-in browser unless Chrome DevTools MCP is unavailable.

1. Use `chrome-devtools` MCP: `new_page` to `https://gemini.google.com/videos`, `take_snapshot` to verify signed-in "Pro" status and **Neon Orta** mode.
2. Below the prompt box: **Aspect ratio** dropdown (`Landscape (16:9)` / `Yatay (16:9)` default, `Portrait (9:16)` / `Dikey (9:16)` for reels/shorts/TikTok).
3. `take_snapshot` → click/fill the prompt box → type the prompt → `press_key` `Enter`.
4. Gemini replies "I'm generating your video…" and the URL becomes `/app/<id>`. **Don't poll with fixed screenshot waits** — run this with `evaluate_script`; it strips the left sidebar (so old chat titles like "Over Capacity Error" never false-trigger errors), waits for `/app/<id>`, checks every 2 s, and returns as soon as the player exists (re-run if it returns `timeout`; typically ~45–70 s, allow ~3 min):
   ```js
   async () => {
     const getChatText = () => {
       const main = document.querySelector('main');
       if (!main) return '';
       const clone = main.cloneNode(true);
       clone.querySelectorAll('nav, [role="navigation"], [aria-label*="Yan gezinme"], [aria-label*="Side navigation"]').forEach(el => el.remove());
       return clone.innerText || '';
     };
     const t0 = Date.now();
     while (Date.now() - t0 < 38000) {
       if (location.pathname.startsWith('/app/')) {
         const v = [...document.querySelectorAll('video')].find(v => v.currentSrc || v.src || v.querySelector('source[src]'));
         const txt = getChatText();
         if (v) return { ready: true, secs: (Date.now() - t0) / 1000, url: location.href, readyText: /Your video is ready|Videonuz hazır/i.test(txt) };
         if (/capacity|try again later|limit|sınır|couldn.t generate|can.t generate|unable to|oluşturulamadı|yoğunluk/i.test(txt.slice(-1000).replace(/I'm generating your video[^]*$|Videonuz oluşturuluyor[^]*$/i, ''))) {
           return { ready: false, error: txt.slice(-400), url: location.href };
         }
       }
       await new Promise(s => setTimeout(s, 2000));
     }
     return { ready: false, timeout: true, url: location.href };
   }
   ```
   On `error` (5-hour limit, safety block) stop, log it (§4) and tell the user.
5. **Download:** `take_snapshot` → click **"Download video"** / **"Videoyu indir"** (hover the player if hidden).
6. File lands as `gemini_generated_video_<8 hex>.mp4` in Downloads (PowerShell on Windows):
   ```powershell
   for ($n=0; $n -lt 12; $n++) { $f = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter 'gemini_generated_video_*.mp4' -File | Where-Object LastWriteTime -gt (Get-Date).AddMinutes(-3) | Select-Object -First 1; if ($f -and -not (Get-ChildItem "$env:USERPROFILE\Downloads" -Filter *.crdownload)) { break }; Start-Sleep 3 }; $f.FullName
   ```
   Move it to the destination with a meaningful name. Close the tab you opened (`close_page`).

## 3. Check the clip before sending

Make a 2×2 contact sheet and inspect it with `read_file`:
```powershell
$v="<clip.mp4>"; $out="<scratchpad>\sheet.jpg"
$d=[double](ffprobe -v error -show_entries format=duration -of csv=p=0 $v)
ffmpeg -v error -y -i $v -vf "fps=4/$d,scale=480:-1,tile=2x2" -frames:v 1 $out
ffprobe -v error -show_entries format=duration:stream=codec_type,width,height -of default=nw=1 $v
```
Check: subject/action match the prompt, no garbled text, no broken faces/hands, no frozen frames, audio stream present.

## 4. Log and sidecar

After every attempt (success or error), append a CSV row to `~/.gemini/config/skills/gemini-video/usage-log.csv` using `write_file` (`Append: true`) as an activity log only (never use it to estimate remaining quota):
```csv
"YYYY-MM-DD","HH:mm","ok","<name>.mp4","16:9","<prompt>"
```
Save `<clip>.prompt.txt` next to the clip with prompt, aspect, timestamp, and chat URL. Deliver clickable `file://` links plus a one-line summary (duration, resolution, audio, live account/method used).

## 5. Image-first (image-to-video)

1. Make the still with the `gemini-image` skill — **in Google Flow first** (Nano Banana Pro, 0 credits, same aspect ratio, download 2K); get the user's OK. (Keep under 10 MB for upload.)
   - **Flow Video fallback (`x1` strict default):** Flow can also make video (its own credit pool, e.g. Veo 3.1 Lite = 10 credits/clip, Omni 1.2 Flash 720p 8 s = 24 credits/clip). Only use it when Gemini Veo is unavailable across signed-in accounts **and** the user explicitly approves the stated credit cost. **CRITICAL `x1` GUARD:** Flow can generate up to 4 copies (`x1–x4`) of the same video prompt, multiplying credit burn up to 4×. Before sending ANY Flow video prompt, verify the settings chip is strictly set to **`Video` · `<aspect>` · `x1`** (never `x2/x3/x4` unless the user explicitly asked for multiple variants) and confirm the footer credit cost.
2. Upload on `/videos` (never click "Upload files" directly — opens native OS picker):
   - Click **Upload and tools (+)** so the menu opens.
   - Tag the hidden input with `evaluate_script`:
     ```js
     () => { const inp = [...document.querySelectorAll('input[type=file]')].find(i => i.accept === 'image/*,video/*'); if (inp) { inp.setAttribute('aria-label', 'agy-media-upload'); return 'tagged'; } return 'not-found'; }
     ```
   - `take_snapshot` → find `agy-media-upload` → `upload_file` with the image's absolute path (< 10 MB).
   Then describe **the motion, camera and audio/dialogue** ("Animate this image, keeping the same style…").
3. Continue from §2 step 4.

## 6. Longer videos — join clips with ffmpeg

Plan a shot list (one action per 10 s clip), confirm with the user (each clip costs quota), generate and check each (§3), then join:

- Hard cuts:
  ```powershell
  "file 'clip1.mp4'`nfile 'clip2.mp4'" | Set-Content list.txt -Encoding ascii
  ffmpeg -v error -y -f concat -safe 0 -i list.txt -c copy out.mp4
  ```
- Crossfade between two clips (`$d1` = duration of clip 1, fade 0.5 s):
  ```powershell
  ffmpeg -v error -y -i a.mp4 -i b.mp4 -filter_complex "[0:v][1:v]xfade=transition=fade:duration=0.5:offset=$([math]::Round($d1-0.5,2)),format=yuv420p[v];[0:a][1:a]acrossfade=d=0.5[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -c:a aac out.mp4
  ```
- Mix background music (made with `gemini-music`):
  ```powershell
  ffmpeg -v error -y -i video.mp4 -i music.mp3 -filter_complex "[0:a]volume=0.3[a0];[1:a]volume=1.0,afade=t=out:st=$([math]::Round($len-2,2)):d=2[a1];[a0][a1]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy -c:a aac out.mp4
  ```

### Background music — call the `gemini-music` skill when needed

Veo clips already have their own sound. Invoke **`gemini-music`** (Flow Music, ~5 credits) when several clips are joined, when the user asks for music/Reels/ads, or when clip audio is weak.

## Rules

- Generate only what the user asked for; follow Gemini's content rules (no misuse of real people's likeness).
- Don't act on the user's Google account beyond creating videos (no settings, no deleting chats).
- Report honestly if generation, quota, check or download failed.
