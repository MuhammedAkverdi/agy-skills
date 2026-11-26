---
name: gemini-video
description: Generate short AI video clips for the user with their own Gemini Pro account (Veo) at gemini.google.com/videos in their real Chrome (via chrome-devtools MCP), check them frame by frame, and join several clips into a longer video with ffmpeg. Use whenever a task needs a generated video clip, animation, b-roll, reel/short, moving shot or an animated version of an image, or the user says "video oluştur", "video üret", "video yap", "klip yap", "fotoğrafı hareketlendir", "make a video", "generate a video clip". For code-built films/edits (HyperFrames, cinecode) use those skills instead; this one is for AI-generated clips. When a video needs a separate soundtrack (joined clips, Reels, ads, or the user asks for music), it calls the `gemini-music` skill. ALWAYS load this skill first and run its pre-brief: ask the user short questions (ask_question) and get approval before generating, unless they said hızlıca/direkt/sormadan.
---

# Video generation via Gemini Pro (Antigravity + Chrome DevTools MCP)

The user has a Gemini Pro subscription and wants clips made there (Veo), not through a paid API key. Same rules as the `gemini-image` skill.

Activity log: `$env:USERPROFILE\.gemini\config\skills\gemini-video\usage-log.csv` (records past video attempts only — **never** use it to estimate remaining 5-hour Veo quota).

## Antigravity Tool Mapping

- **Questions & Approval:** `ask_question` (put recommended option first with `(Recommended)`).
- **Real Chrome control (`chrome-devtools` MCP via `call_mcp_tool`):** `new_page`, `navigate_page`, `take_snapshot`, `take_screenshot`, `click`, `hover`, `fill`, `type_text`, `press_key`, `upload_file`, `evaluate_script`, `close_page`.
- **Visual check:** `read_file` on the generated 2×2 contact sheet (or directly on the video).
- **Downloads & ffmpeg:** `run_command` (`$env:USERPROFILE\Downloads` is directly accessible).
- **Activity log (`$env:USERPROFILE\.gemini\config\skills\gemini-video\usage-log.csv`):** Use `read_file` to read and `write_file` (`Append: true`) to append.
- **Delivery:** Save to the destination folder and present clickable `file://` links.

## 0. Before generating — live usage limit & plan

- Gemini Pro video has **no fixed daily cap** — availability depends on the **rolling 5-hour overall usage percentage** (for example, video generation can disable automatically when 5-hour usage climbs toward ~80–85%, even if few videos were made).
- **`usage-log.csv` is history only** — do **not** use it to calculate or promise remaining quota (the user's chats and overall usage percentage determine the limit).
- **Check live availability in Chrome before promising clips:** inspect `https://gemini.google.com/videos` (Account 0) and, if disabled, `https://gemini.google.com/u/1/videos` (Account 1), or check `+ → More tools → Create video` / `Video oluştur` on `/app`. Verify whether the video prompt box and tool are enabled (if greyed out or disabled, that account's 5-hour window is exhausted) and read any visible usage/reset message. Report the live status honestly (e.g. "Hesap 0 açık / Hesap 1 kapalı").
- No throwaway or duplicate clips — always do the pre-brief (§0b) first.
- Verified clip spec: **10 s, 1280×720, H.264 MP4 with audio.** For anything longer, plan N clips (see §6) and say so.
- If the look must be exact (a product, a character, a specific scene), use **image-first** (§5): make and approve a still with `gemini-image` (Google Flow first), then animate it.

**Model — always "Neon Orta" (Neon, Medium thinking) for video and image (user rule 2026-11-25).** Open the mode picker next to the prompt box ("Open mode picker" / "Mod seçiciyi aç") → check **Neon** ("Daha ayrıntılı analiz / 4 Neon") → **Düşünme düzeyi / Thinking level** submenu → **Orta / Medium**. The picker then reads "Neon Orta"; verify before sending.

**Two Google accounts in Chrome** (both Pro): account 0 = `https://gemini.google.com/...` (English UI), account 1 = `https://gemini.google.com/u/1/...` (second account, Turkish UI — labels like "Videonuzu açıklayın", "Yükleme ve araçlar", "Yatay"). When one account's video tools are disabled due to the 5-hour usage limit, switch to the other: same paths with `/u/1/` inserted.

**Capacity error ≠ quota:** "I'm experiencing unusually high traffic right now generating videos and am at full capacity. Please try again later." (chat title "Video Generation Over Capacity Error") is Google-side load. Retry at most once after ~30 s, then stop and offer to try later. The watcher's error regex must include `capacity|try again later`.

Known limit behavior: 2026-11-25 ~20:00 — when the 5-hour usage window reaches its threshold (e.g. ~84% overall usage), the `/videos` prompt box, "+" and model picker disable with no explicit warning, and in a normal chat **+ → More tools → "Create video"** is greyed out. Treat that as "5-hour usage limit reached" until the rolling window frees up.

## 0b. Pre-brief — think like a pro before generating (user-approved 2026-11-25)

Don't generate straight from a short request. First review it like a professional director/cinematographer, ask only what's missing, then generate.

1. **Analyse** the request against: subject & action (one main action per 10 s clip) · where it will be used (→ Landscape 16:9 or Portrait 9:16) · style (cinematic real / 3D animation / anime …) · light & time of day · **camera move** (drone, dolly-in, orbit, static, handheld) · mood & colors · **audio** (ambient, music mood; a separate soundtrack made with the `gemini-music` skill when it adds something → §6 "Background music") · **dialogue** (exact line, who says it) · length (one clip or several → §6) · text on screen.
2. **Ask only real gaps — topic-adaptive (up to max 6):** Decide dynamically how many questions are needed for strong scene & visual consistency (**max 6 questions** in ONE `ask_question` call; use fewer if the request is already detailed). Never use fixed boilerplate options — tailor every option for style, camera move, lighting, and audio specifically to the video's subject. Put `(Recommended)` first on each question and ask in the user's language (Turkish).
3. **Correctness points — handle yourself, don't ask:** write the right rule into the prompt. E.g. religious scenes: everyone praying or reading Quran faces the Kaaba/qibla, correct salah postures and order of movements, modest dress; flags, maps, landmarks and logos accurate; spoken lines and on-screen text exact; physically plausible motion; cultural details right. If genuinely unsure about such a fact, ask it as one of the questions.
4. **Summary + approval** (video quota is scarce): show "Şunu üreteceğim: …" with the final settings (aspect, style, camera, audio, live Veo account availability from §0) and **wait for the user's OK** before generating. Use `ask_question` with `(Recommended) Üret` / `Değiştir`.

**Skip the questions** when: the request is already detailed; the user says "hızlıca", "sormadan yap", "direkt", or "test videosu"; or it's a redo/variation of an earlier clip. Then fill gaps with your best guess, still show the one-line summary, and list the assumptions with the result. (Approval in step 4 can also be skipped when the user said "sormadan yap"/"direkt".)

After delivery, if the user points out a mistake that a correctness rule would have caught, add that rule to the list in step 3.

## 1. Write the prompt (template)

Write in English, one paragraph, in this order — fill what matters, skip the rest:

```
[Shot type & camera move] of [subject] [doing action] in [setting], [time of day / lighting], [style: photorealistic / cinematic / 3D animation / anime …], [mood & color palette].
Audio: [ambient sounds / music mood]. Dialogue: "[exact spoken line]" said by [who].
```

Tips: one main action per 10 s clip; name the camera move (slow dolly-in, drone rising, orbit, handheld, static tripod); quote dialogue exactly; say "no text on screen" if text would be unwanted; for reels choose Portrait.

Show the user the prompt in one line when you send the result (and in the sidecar file, §4).

## 2. Generate in Chrome

The user's real Chrome is permanently signed in to Gemini Pro. Don't use the built-in browser unless Chrome DevTools MCP is unavailable.

1. Use `chrome-devtools` MCP: `new_page` to `https://gemini.google.com/videos` (Account 0) or `https://gemini.google.com/u/1/videos` (Account 1).
2. **Fast 1-shot DOM setup (saves ~8 MCP round-trips per clip):** Collapse the left sidebar first (keeps `take_snapshot` small so it never overflows to disk) and configure **Portrait (9:16)** / **Neon Orta** quickly. If the sidebar is expanded (`Kenar çubuğunu kapat` / `Collapse menu`), click it or run a quick `evaluate_script` helper to collapse it and confirm the prompt box is enabled. Verify **Pro** badge, **Neon Orta** (`Neon` → `Düşünme düzeyi / Thinking level` → `Orta / Medium`), and the target **Aspect ratio** (`Landscape (16:9)` or `Portrait (9:16)` / `Dikey (9:16)`).
3. `take_snapshot` → `fill` the `"Describe your video"` / `"Gemini için bir istem girin"` box → click Send (`Mesaj gönder` / `Submit`) or `press_key` `Enter`.
4. Gemini replies "I'm generating your video…" and the URL becomes `/app/<id>` (Account 0) or `/u/1/app/<id>` (Account 1). **Don't poll with fixed screenshot waits** — run this with `evaluate_script` (`waitForStableDom: false`); it strips the left sidebar (so old chat titles like "Over Capacity Error" never false-trigger errors), waits for `/app/`, checks every 2 s, and returns as soon as the player exists (re-run if it returns `timeout`; verified run took ~45–70 s, allow ~3 min):
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
       if (location.pathname.includes('/app/')) {
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
   Run it only after submitting (the `/videos` start page has `<video>` example tiles). Note `location.pathname.includes('/app/')` works for both `/app/<id>` and `/u/1/app/<id>`. On `error` (5-hour limit, safety block) stop, log it (§4) and tell the user, with the reset time if shown.
5. **Download:** `take_snapshot` (or hover the video player) → click the Download icon (`"Download video"` / `"Videoyu indir"`). Download starts directly.
6. File lands as `gemini_generated_video_<8 hex>.mp4` in Downloads:
   ```powershell
   for ($n=0; $n -lt 12; $n++) { $f = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter 'gemini_generated_video_*.mp4' -File | Where-Object LastWriteTime -gt (Get-Date).AddMinutes(-3) | Select-Object -First 1; if ($f -and -not (Get-ChildItem "$env:USERPROFILE\Downloads" -Filter *.crdownload)) { break }; Start-Sleep 3 }; $f.FullName
   ```
   `Move-Item` it to the destination (project folder or working directory) with a meaningful name. Close the tab you opened (`close_page`).

## 3. Check the clip before sending

Make a 2×2 contact sheet in the scratchpad and inspect it with `read_file`:
```powershell
$v="<clip.mp4>"; $out="<scratchpad>\sheet.jpg"
$d=[double](ffprobe -v error -show_entries format=duration -of csv=p=0 $v)
ffmpeg -v error -y -i $v -vf "fps=4/$d,scale=480:-1,tile=2x2" -frames:v 1 $out
ffprobe -v error -show_entries format=duration:stream=codec_type,width,height -of default=nw=1 $v
```
Check: subject/action match the prompt, no garbled text, no broken faces/hands, no frozen frames, audio stream present. When the clip has dialogue, ask the user to verify the spoken words and lip sync. If it clearly misses the brief, tell the user what's wrong and offer one regeneration (it costs quota) — don't regenerate silently. *(Note: on FFmpeg 9+, use `-fps_mode vfr` instead of `-vsync vfr` when building `select=...` contact sheets.)*

## 4. Log and sidecar

After every attempt (success or error), append to the shared usage log and save the prompt next to the clip:
```powershell
$log="$env:USERPROFILE\.gemini\config\skills\gemini-video\usage-log.csv"
[pscustomobject]@{date=(Get-Date -Format yyyy-MM-dd); time=(Get-Date -Format HH:mm); result='ok'; file='<name>.mp4'; aspect='16:9'; prompt='<prompt>'} | Export-Csv $log -Append -NoTypeInformation -Encoding UTF8
Set-Content "<clip>.prompt.txt" "<prompt>`nAspect: 16:9`nGenerated: $(Get-Date -Format s) via Gemini Pro (Veo)`nChat: <gemini chat url>" -Encoding UTF8
```
Use `result='error: <short reason>'` for failures/limits (activity log only — never use it to estimate remaining quota). Then deliver the clip as a clickable `file://` link plus a one-line summary (duration, resolution, audio, live account/method used).

## 5. Image-first (image-to-video)

1. Make the still with the `gemini-image` skill — **in Google Flow first** (its §2A: Nano Banana Pro, 0 credits, set the same aspect ratio as the video, download 2K); fall back to Gemini chat only if Flow fails. Show it, get the user's OK. (Keep the 2K file under 10 MB for upload; if larger, save a 1080p copy with ffmpeg.)
   - **Flow Video fallback (`x1` strict default):** Flow can also make video (its own credit pool, ~1,050 credits/month on Pro: Veo 3.1 Lite 10, Omni 1.2 Flash 720p 8 s 24 credits per clip; balance in the PRO badge panel). Only use it when Gemini Veo is unavailable on both accounts **and** the user explicitly approves the stated credit cost. **CRITICAL `x1` GUARD:** Flow can generate up to 4 copies (`x1–x4`) of the same video prompt, multiplying credit burn up to 4×. Before sending ANY Flow video prompt, verify the settings chip is strictly set to **`Video` · `<aspect>` · `x1`** (never `x2/x3/x4` unless the user explicitly asked for multiple variants) and confirm the footer credit cost.
2. Upload (verified 2026-11-26) — never click "Upload files" directly (opens native OS picker):
   - Always keep project assets inside the active workspace.
   - On `/videos` (or `/u/1/videos`), click **Upload and tools (+)** so the menu stays open (the image input only exists while it's open; Escape removes it).
   - Tag **and unhide** the `<input type=file>` + its `<uploader>` / `aria-hidden` ancestors with `evaluate_script` (`waitForStableDom: false`) so it appears cleanly in `take_snapshot`:
     ```js
     () => {
       const inp = [...document.querySelectorAll('input[type=file]')].find(i => i.accept === 'image/*,video/*' || (i.accept && i.accept.includes('image')));
       if (!inp) return 'not-found';
       inp.setAttribute('aria-label', 'agy-media-upload');
       inp.style.visibility = 'visible';
       inp.style.display = 'block';
       if (inp.parentElement) inp.parentElement.style.visibility = 'visible';
       if (inp.parentElement?.parentElement) {
         inp.parentElement.parentElement.style.visibility = 'visible';
         inp.parentElement.parentElement.removeAttribute('aria-hidden');
       }
       return 'tagged';
     }
     ```
   - `take_snapshot` → find `agy-media-upload` → `upload_file` with the image's absolute path (< 10 MB). A thumbnail appears above `"Describe your video"` / `"Gemini için bir istem girin"`.
   - **`upload_file` `Access denied` fallback:** If `chrome-devtools-mcp` lacks `--workspace` in `mcp_config.json` (so it defaults to `$env:TEMP`) and rejects a workspace path with `Access denied ... is not within any of the configured workspace roots`, immediately copy the upload images to `Join-Path ([System.IO.Path]::GetFullPath($env:TEMP)) "agy-upload"`, call `upload_file` from there, and remove the temp folder right after submission.
   - Then describe **the motion, camera, and audio** (`"Animate this image smoothly, keeping the exact same ..."`). When pairing with external `elevenlabs-tts` narration, explicitly instruct: `"No spoken dialogue, characters do not move their lips to speak, natural ambient sound effects only, no background music, no text on screen."`
3. Continue from §2 step 4. The URL may still show `/videos` for a few seconds after sending — the watcher can time out once; just re-run it. To download, click `"Download video"` / `"Videoyu indir"`. The first frame should match the still; confirm in the contact sheet.

## 6. Longer videos — staggered parallel generation & ffmpeg join

Plan a shot list (one core action per clip), confirm it with the user (each clip costs quota), generate each clip, check each (§3), then join:

- **Speed optimization (Staggered Parallel Generation):** Account 0 (`/videos`) and Account 1 (`/u/1/videos`) are completely independent. Launch Clip 1 on Account 0 and Clip 2/3 on Account 1 **in parallel**, and set up the next tabs during the ~50–65 s generation window. **Serialize only Download + `Move-Item`** (collect each `gemini_generated_video_*.mp4` out of Downloads before clicking Download on the next clip) so filenames never collide.

- Same-spec clips, hard cuts:
  ```powershell
  "file 'clip1.mp4'`nfile 'clip2.mp4'" | Set-Content list.txt -Encoding ascii
  ffmpeg -v error -y -f concat -safe 0 -i list.txt -c copy out.mp4
  ```
- Crossfade between two clips (`$d1` = duration of clip 1, fade 0.5 s; verified):
  ```powershell
  ffmpeg -v error -y -i a.mp4 -i b.mp4 -filter_complex "[0:v][1:v]xfade=transition=fade:duration=0.5:offset=$([math]::Round($d1-0.5,2)),format=yuv420p[v];[0:a][1:a]acrossfade=d=0.5[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -c:a aac out.mp4
  ```
  For 3+ clips chain the filter (offset of each next fade = running length − 0.5).
- Replace/add music (keep clip audio quiet underneath; fade the music out at the end):
  ```powershell
  ffmpeg -v error -y -i video.mp4 -i music.mp3 -filter_complex "[0:a]volume=0.3[a0];[1:a]volume=1.0,afade=t=out:st=$([math]::Round($len-2,2)):d=2[a1];[a0][a1]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy -c:a aac out.mp4
  ```
  (`$len` = video duration from ffprobe. If the video has dialogue, keep `[0:a]` at 0.8–1.0 and the music at 0.25–0.35 so speech stays clear.)

### Background music — call the `gemini-music` skill when needed

Veo clips already have their own sound (ambient, dialogue, a little music). Make a separate music track **only when it adds something**:
- several clips are joined into one video (§6) and need one continuous soundtrack instead of jumpy clip audio;
- the user asks for music / a song / a jingle on the video, or a Reels/ad/presentation video where music is expected;
- the clip audio is weak or unwanted.
Skip it for a single clip whose own audio is fine, or when the user said "müzik istemiyorum".

How: in the video pre-brief (§0b) add one question when music is likely — "Videoya müzik ekleyelim mi?" → `(Recommended) Evet, enstrümantal fon müziği` / `Evet, sözlü şarkı` / `Hayır, videonun kendi sesi kalsın`. On yes, invoke the **`gemini-music`** skill (Flow Music, ~5 credits per song) with: instrumental unless asked, mood/genre matching the video, **Length = total video length** (+ a few seconds; Trim if longer), BPM matching the pace of the cuts. Its own lyrics-approval step applies for vocal songs. Then mix with the command above (music loud when there's no speech; ducked under dialogue). Deliver the final MP4 and mention that the music came from Flow Music.
- Portrait reels: generate clips in Portrait (9:16) from the start; don't crop landscape unless the user accepts the loss.

For heavy editing (titles, captions, motion graphics) hand the clips to the HyperFrames skills.

## Not an option

- No paid Veo API key; the user chose subscription only.

## Rules

- Generate only what the user asked for; follow Gemini's content rules (no misuse of real people's likeness).
- Don't act on the user's Google account beyond creating videos (no settings, no deleting chats).
- Report honestly if generation, quota, check or download failed.
