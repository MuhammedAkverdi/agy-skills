---
name: gemini-reels
description: Orchestrate end-to-end vertical Instagram Reels, YouTube Shorts, and TikTok video creation using the user's Google AI Pro accounts — planning a scenario and Style Lock first, generating 9:16 keyframes in Google Flow (`gemini-image`, 0 credits), animating scenes via Gemini Veo (`gemini-video`), Flow Video (`x1` strict default), or Hybrid 2K motion, narrating with the free local `local-tts` voices by default (`elevenlabs-tts` optional), composing a custom soundtrack in Flow Music (`gemini-music`, ~5 credits), and assembling the final 1080x1920 MP4, cover image, and caption/hashtag draft with ffmpeg. Use whenever the user asks to create a Reel/Short/vertical video, or says "reels oluştur", "reels yap", "reels videosu", "shorts yap", "tiktok videosu", "dikey video hazırla", "make a reel", "create a reels video", or invokes `/gemini-reels`.
---

# Instagram Reels / Shorts Pipeline (`gemini-reels` Orchestrator)

This skill is the **director / orchestrator** for vertical `9:16` (`1080×1920`) short-form videos. It coordinates the user's existing skills in real Chrome (`chrome-devtools` MCP) and local REST APIs — never paid Gemini/Veo API keys:
- **Keyframes & Cover (`0 credits`):** `$env:USERPROFILE\.gemini\config\skills\gemini-image\SKILL.md` (Google Flow, Nano Banana Pro, 9:16, 2K download)
- **Scene Motion / Video (`0 credits`):** `$env:USERPROFILE\.gemini\config\skills\gemini-video\SKILL.md` (Gemini Pro Veo I2V in Portrait `9:16`, **Neon Orta**, or Flow Video strictly `x1` if approved)
- **Voiceover & Alignment — default `local-tts` (free, CPU, no key):** `$env:USERPROFILE\.gemini\config\skills\local-tts\SKILL.md` (yazgı-tts-1 / Supertonic 3 + faster-whisper word timings; voices `yazgi-male-01`, `yazgi-female-02`, `supertonic-M2` only)
- **Voiceover — optional `elevenlabs-tts`** (when the user wants ElevenLabs; ~300–450 chars / 10,000 free/mo): `$env:USERPROFILE\.gemini\config\skills\elevenlabs-tts\SKILL.md`. Both write `vo-XX.mp3` + `.alignment.json` in the same format, so assembly is identical.
- **Soundtrack (`~5 credits`):** `$env:USERPROFILE\.gemini\config\skills\gemini-music\SKILL.md` (Flow Music, Lyria 3.5)
- **Assembly & Packaging:** `ffmpeg` / `ffprobe` via `run_command`, visual QA via `read_file`.

Read the relevant sibling `SKILL.md` before executing its steps so all DOM selectors, scripts, watchers, and safety rules stay exact.

## Project Workspace Layout (Active Workspace Mandatory)

- **Default location:** Always create the project folder `<active-workspace>\reels-<slug>\` inside the user's currently open **active workspace** (so `upload_file` and project deliverables stay cleanly inside the workspace).
- **No active workspace check:** If NO active workspace is open at Stage 0, **warn the user before starting production**: *"Image-to-Video ve dosya teslimi için bir çalışma klasörü (workspace) açık olmalı; lütfen bir klasör açıp devam edin."*
- **`chrome-devtools` `upload_file` fallback:** If `chrome-devtools-mcp` lacks `--workspace` in `mcp_config.json` and rejects a workspace path with `Access denied ... is not within any of the configured workspace roots`, immediately copy the upload images into `$env:TEMP\agy-upload\`, upload from there, and delete `$env:TEMP\agy-upload\` once submitted.

```text
<active-workspace>\reels-<slug>\
├── senaryo.md               # Scenario, Style Lock, scene table, live limit check, IG caption & hashtags
├── 01-frames\               # 9:16 2K Flow keyframes (scene-01.jpg ...), prompt sidecars, storyboard.jpg
├── 02-clips\                # Raw Veo / Flow x1 / Hybrid motion clips + trimmed/normalized 1080x1920 clips
├── 03-audio\                # Voiceovers (vo-01.mp3 + .alignment.json, local-tts or ElevenLabs) + Flow Music (soundtrack.mp3)
├── cover-1080x1920.jpg      # Clean 1080x1920 Reels cover image
└── final-reels.mp4          # Final 1080x1920, 30 fps, H.264 + AAC Reels video
```

---

## Stage 0 — Workspace Check, Live Quota Check & Topic-Adaptive Pre-brief

### 0a. Check Active Workspace + Live Availability (Do NOT rely on `usage-log.csv`)
1. Confirm an active workspace exists (warn and stop if none).
2. **Gemini Pro Veo:** Check **live availability in Chrome** (`https://gemini.google.com/videos` Account 0 and `https://gemini.google.com/u/1/videos` Account 1) — verify **Pro** badge, **Neon Orta**, and that the prompt box + `Create video / Video oluştur` tool are enabled. Never use `usage-log.csv` to promise remaining quota.
3. **Narration engine (when voiceover is planned):** `local-tts` — check `%USERPROFILE%\.local-tts\venv\Scripts\python.exe` exists, else offer its one-time setup (`local-tts` Step 0, ~1.5 GB). ElevenLabs only if the user chooses it: check `ELEVENLABS_API_KEY` + remaining characters via `elevenlabs-tts\scripts\check_quota.ps1` (never print the key).

### 0b. Dynamic, Topic-Adaptive Pre-brief (`ask_question`)
Never dump fixed boilerplate choices. Think like a Reels director and craft **only the questions needed for strong visual and narrative consistency** on *this specific topic* (**up to max 6 creative questions** in ONE `ask_question` call; use fewer when the prompt is already rich), **plus an explicit duration-in-seconds question** whenever the user hasn't already specified a target length:

- **Target duration in seconds (always ask if unspecified — in addition to the topic questions):** e.g. *"Reels videosu kaç saniye olsun? (İstediğin tam saniyeyi yazabilirsin)"* → `(Recommended) 30 sn (4–5 sahne)` / `15–20 sn (2–3 sahne)` / `60 sn (1 dk, 8–10 sahne)` / `90 sn (1.5 dk, 12–14 sahne)`.
- **Topic-tailored options:** Every option for visual style, audio/music direction, pacing, perspective, and on-screen text MUST match the user's subject.
- **Recommended first:** Put `(Recommended)` on your strongest pick for each question. Ask in Turkish (unless the user wrote in English).
- **Audio structure default:** Recommend **`Anlatıcı (Dış Ses) + Veo ortam sesi + Flow Music`** whenever storytelling/narration fits — it eliminates Turkish lip-sync glitches, keeps one consistent narrator voice and gives exact subtitle timestamps. Offer Veo native dialogue or music-only as alternatives.
- **Narrator voice:** free local voices first — "Yerel ses, sıcak erkek anlatıcı (yazgı male-01)" / "Yerel ses, sakin olgun kadın (yazgı female-02)" / "ElevenLabs (anahtar gerekir; genç kadın sesi, daha duygulu)"; recommend by genre. Voice samples are played after the scenario (User review rule 2).
- **Every scene real video (default):** Hybrid still+zoompan is used **only if the user picks it** here or in the Cost Plan (User review rule 4).

Skip questions only when the user says `"hızlıca"`, `"direkt"`, or `"sormadan"`. Even then, state your assumptions and get credit/quota approval before spending paid credits or scarce video quota.

---

## Stage 1 — Scenario, Style Lock & Director QA (Approval Gate #1)

Design a tight vertical **Hook (0–3 s) → Development → Climax / Final CTA** script scaled directly to the **user's requested duration in seconds** (`~6–7 s` per trimmed scene: e.g. `20 s` ≈ 3 scenes, `30 s` ≈ 4–5 scenes, `60 s` ≈ 8–10 scenes, `90 s` ≈ 12–14 scenes).

- **Long-Reels (`>= 45 s`) Resource Planning:** For 60 s / 90 s Reels, explicitly check Veo 5-hour quota (split across Account 0 + Account 1) and total ElevenLabs Turkish character count in the Cost Plan. If live Veo capacity cannot cover all scenes, propose a balanced plan upfront (e.g., **Veo for dynamic Hook/character action + Hybrid 2K `zoompan` for static/atmospheric scenes**, or **approved Flow Video `x1`**).

### Director & Script Quality Rules (Mandatory Self-Check)
1. **Logical Continuity & Bridges:** Never jump abruptly between locations or story states (e.g., forest encounter → wolf already disguised in bed) without a visual bridge or a 1-sentence narrator bridge explaining how we got there.
2. **No Frame-1 Spoilers:** In any climax or rescue scene, NEVER reveal the twist/rescuer already standing inside the opening keyframe (`scene-0X.jpg`). Start *before* the reveal (e.g., locked door / looming threat) so the motion actually delivers the surprise.
3. **1 Core Action & Concise Lines per Scene:** Keep each scene to **1 primary visual action** and **1–2 short spoken/narrated lines** (~5–7 s). Never cram 3+ dialogue turns into one 10 s clip.
4. **Tight Reels Pacing (`trim`):** Veo outputs `~10 s` clips, but don't leave dead air — plan to trim each clip to its strongest **`5–7.5 s`** (matched to `vo_dur + 0.6–0.8 s` when using ElevenLabs).
5. **Lip-Sync Alignment Rule:** When using ElevenLabs **Narrator / Dış Ses**, explicitly instruct Veo: `"No spoken dialogue, characters do not move their lips to speak, natural ambient sound effects only"` (expressive acting, facial expressions, and physical motion without talking mouths).

### Style Lock, Scene Table & Cost Plan
1. **Define a `Style Lock` (Visual DNA):** One concise English block copied verbatim into **every** scene prompt so lighting, color grading, lens feel, era, and recurring subjects match across cuts.
2. **Build the Scene Table** (`Sahne | Süre (Trim) | Üretim Yöntemi | Görsel & Aksiyon | Kamera | Anlatıcı / Ses | Ekranda Yazı`).
3. **Save `senaryo.md`** in the project folder with the full script, Style Lock, and scene prompts.
4. **Show Cost & Quota Summary + Request Approval:**
   - **Keyframes (`gemini-image` / Flow):** `0 credits`
   - **Video (`gemini-video` / Veo):** live account status + exact number of Veo clips planned
   - **Voiceover (`elevenlabs-tts`):** exact Turkish character count vs. `remaining` quota (e.g. `~350 / 10,000 kr`)
   - **Flow Video (only if Veo is unavailable and user approves):** exact credit cost at **`x1` only**
   - **Music (`gemini-music` / Flow Music):** `~5 credits` (or `0` if keeping raw clip audio)
   - Ask via `ask_question`: `(Recommended) Senaryoyu onayla, görsellere geç` / `Senaryoyu düzenle`.

---

## Stage 2 — 9:16 Keyframes & Visual Consistency (`gemini-image`, Approval Gate #2)

1. Open **one single Google Flow project** (`https://labs.google/fx/tools/flow` → `Yeni proje`) with Flow Agent **OFF**, **Resim**, **9:16**, **Nano Banana Pro**, **`x2`** (`0 kredi`).
2. Generate Scene 1's opening keyframe first using `Style Lock + Scene 1 prompt`.
3. For Scenes 2..N, enforce consistency across scenes:
   - Always include the exact same **Style Lock**.
   - When the same location, object, or character reappears, attach the approved Scene 1 frame (or character sheet) via Flow's **`İsteme ekle`** or **`Karakterler`** feature so the model preserves the exact look.
4. Download the best variant of each scene in **2K** (`01-frames\scene-01.jpg`, `scene-02.jpg`, ...) and inspect every image with `read_file` (check 9:16 framing, no broken hands/faces, no unwanted text/watermarks).
5. Build a side-by-side storyboard strip:
   ```powershell
   ffmpeg -v error -y -i scene-01.jpg -i scene-02.jpg -i scene-03.jpg -filter_complex "[0]scale=-1:600[a];[1]scale=-1:600[b];[2]scale=-1:600[c];[a][b][c]hstack=inputs=3" -q:v 2 storyboard.jpg
   ```
   (Adjust inputs count to match scenes.) Inspect `storyboard.jpg` with `read_file` and present it to the user for **Approval Gate #2** before spending any video quota/credits.

---

## Stage 3 — Fast Parallel Video Generation & Audio-First Voiceover

### 3a. Voiceover First (`local-tts` by default, or `elevenlabs-tts`)
First generate **2–3 one-line voice samples** and let the user pick (`ask_question`); use speed 0.85–0.9 for tales. Then generate per-scene Turkish narration **before** final clip trimming (`03-audio\vo-01.mp3`, `vo-02.mp3`, ... + `*.alignment.json`) in ONE batch run: `local_tts.py --voice <picked> --speed 0.9 --batch jobs.json` (check every line's `words_matched`; re-make any clip with a `warning`), or with ElevenLabs via `elevenlabs-tts\scripts\tts_generate.ps1 -Speed 0.88`. Use each clip's `duration_s` (`vo_dur + 0.6–0.8 s`, typically `5–7.5 s`) as the exact trim target so pacing stays crisp.

### 3b. Staggered Parallel Veo Generation (Priority 1: Gemini Pro Veo, `9:16`, Neon Orta)
- Follow `gemini-video` §2, §5, and §6 (**Image-first + Fast DOM setup**):
  - Check file size of each approved `01-frames\scene-XX.jpg` (`< 10 MB`).
  - Collapse the left sidebar first on `/videos` so `take_snapshot` stays small; verify **Neon Orta** and **Portrait (`9:16`) / Dikey (`9:16`)**; use the verified `<uploader>` unhiding snippet for `agy-media-upload` (`$env:TEMP\agy-upload\` fallback if `upload_file` returns `Access denied`).
  - **Parallel speed-up:** Run Account 0 (`gemini.google.com/videos`) and Account 1 (`gemini.google.com/u/1/videos`) **in parallel** (e.g., submit Scene 1 on Account 0 and Scene 3 on Account 1 together, and prep the next tabs while waiting). **Serialize Download + `Move-Item`** so `gemini_generated_video_*.mp4` files never collide in Downloads.
  - When pairing with ElevenLabs voiceover, prompt Veo: `"Animate this image smoothly, keeping the exact same subject, environment, lighting, and visual style. No spoken dialogue, characters do not move their lips to speak, natural ambient sound effects only, no background music, no text on screen."`
- Check every downloaded clip with a `2×2` contact sheet via `read_file` (`gemini-video` §3).

### Priority 2: Google Flow Video (ONLY if Veo quota is out AND user approves credit cost)
- **CRITICAL `x1` CREDIT GUARD:** Google Flow can generate up to 4 copies (`x1–x4`) of the same video prompt, which multiplies credit burn up to 4×.
  - Before submitting ANY video prompt in Google Flow, open the settings chip and **verify it says `Video` · `9:16` · `x1`** (NEVER `x2`, `x3`, or `x4` unless the user explicitly asks for variants).
  - Verify the exact footer credit cost (e.g. `10 kredi` for Veo 3.1 Lite, `24 kredi` for Omni 1.2 Flash) matches what the user approved.
  - Attach the approved 9:16 keyframe as the start frame (`İsteme ekle` / frame input) to preserve scene consistency.

### Hybrid Quota Mode (2K Still + `ffmpeg` Motion) — Consistency Rules
**Not a default.** The user rejected "photo-only" scenes in v1. Use Hybrid only when the user explicitly chooses it — otherwise wait for the 5-hour window, use the second account, or ask for Flow Video credits (state the cost).
When Veo quota cannot cover all scenes and the user chooses Hybrid mode (instead of spending Flow Video credits or waiting for the 5-hour window):

1. **Assign scenes by motion type:**
   - **Real Video (Veo / Flow `x1`) ONLY for dynamic scenes:** Hook (Scene 1 whenever possible), walking/talking people, facial expressions, hand interactions, flowing water/fire/smoke, moving vehicles.
   - **Hybrid 2K + Motion ONLY for naturally atmospheric/static scenes:** wide establishing vistas, architecture/interior reveals, crisp product/object close-ups, final CTA/outro frame.
2. **Preserve visual match:** Because Hybrid frames come from the **exact same 2K Flow project & Style Lock** as the Veo I2V starting frames, color, lighting, lens, and architecture match seamlessly.
3. **Avoid jarring static cuts:** Use subtle, continuous 2K supersampled `ffmpeg` camera motion (`zoompan` slow push-in or gentle drift) and bridge transitions with a short `0.3–0.4 s` `xfade` so the clip feels alive:

```powershell
# Example: 4-second 1080x1920 @ 30fps slow zoom-in from a 2K 9:16 frame + silent stereo track
$in = "01-frames\scene-03.jpg"
$out = "02-clips\clip-03-hybrid.mp4"
$fps = 30; $secs = 4; $frames = $fps * $secs
ffmpeg -v error -y -loop 1 -i $in -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 `
  -filter_complex "[0:v]scale=2160:3840:force_original_aspect_ratio=increase,crop=2160:3840,zoompan=z='min(zoom+0.0008,1.10)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=1080x1920:fps=${fps},format=yuv420p[v]" `
  -map "[v]" -map 1:a -t $secs -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -ar 48000 -ac 2 $out
```

*(Note: Never apply artificial `zoompan` to scenes that require character walking or complex physical action — flag that honestly in Stage 1 instead.)*

---

## Stage 4 — Custom Soundtrack (`gemini-music`, ~5 credits)

Unless the user explicitly prefers raw clip audio only:
1. Launch Flow Music (`https://www.flowmusic.app/session`) **in parallel** while the last Veo clip is generating to save wait time.
2. Follow `gemini-music` (**Toggle compose panel** first, **Lyria 3.5**, **Instrumental** ON when there is voiceover/dialogue). Set **BPM** to match cut pacing (e.g., 90–105 BPM cinematic, 115–128 BPM energetic) and **Length** (`m:ss` format — note Flow Music enforces `Min 1:00`, which `ffmpeg` `amix=duration=first` + fade-out handles cleanly). Remember Flow Music's React input rule (`type_text`, or `fill` + click + `Space` + `Backspace` so **Generate** enables).
3. Pause auto-play right after generation, download **MP3** (or WAV if heavy mixing), close the Flow Music tab, move to `03-audio\soundtrack.mp3`, verify duration via `ffprobe`, and write `soundtrack.mp3.prompt.txt`.

---

## Stage 5 — Assembly, Safe-Zone Captions, Cover & Caption Draft (`ffmpeg`)

### 5a. Trim & Normalize Every Clip to Uniform Spec
Trim each clip to its tight scripted duration (`-t <dur>`, matched to `vo_dur + 0.6–0.8 s` when using ElevenLabs, skipping dead air) and normalize to `1080×1920, 30 fps, yuv420p, SAR 1:1, 48 kHz stereo AAC`:

```powershell
ffmpeg -v error -y -i $raw -t $trimDur -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,setsar=1,format=yuv420p" `
  -c:v libx264 -crf 18 -preset medium -c:a aac -ar 48000 -ac 2 $norm
```
*(If a clip has no audio stream, add `-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 -shortest`.)*

### 5b. Join Clips & Mix Voiceover + Ambient + Soundtrack
- Join normalized clips with rhythm-matched hard cuts (`concat` demuxer) or `0.35 s` `xfade` + `acrossfade` into `02-clips\joined.mp4`.
- **3-track mix (ElevenLabs Voiceover + Veo Ambient + Flow Music) — loudness-based, NOT plain volume factors** (v1 with volume 1.0/0.35/0.22 + one final loudnorm buried the voice):
  ```text
  [vo delayed clips] amix=normalize=0,apad,atrim=0:LEN, loudnorm=I=-16:TP=-2:LRA=7, asplit=2 [vo][key];
  [clip audio] loudnorm=I=-33:TP=-6 [amb];
  [music] atrim=0:LEN, loudnorm=I=-27:TP=-6, afade=t=in:d=1, afade=t=out:st=LEN-2.5:d=2.5 [mus0];
  [mus0][key] sidechaincompress=threshold=0.02:ratio=10:attack=15:release=450 [mus];
  [vo][amb][mus] amix=inputs=3:normalize=0:duration=first, alimiter=limit=0.89 [a]
  ```
  **Verify:** `volumedetect` on a narration segment vs. a gap — narration must be ≥ 8 dB louder (v2 measured −16 dB vs −28 dB).
- **2-track mix (Music-led or Veo dialogue only):** Keep Veo dialogue at `volume=1.0` + music at `volume=0.22–0.28` (or Veo ambient at `0.25` + music at `1.0` if no speech).

### 5c. Safe-Zone Turkish Title & Subtitles (`.ass` Preferred)
- **Safe Zone (`1080×1920`):** Keep all text inside `x: 90..920` (avoid right-side icons `> 920 px`), `y: 260..1460` (avoid top header `< 250 px` and bottom caption bar `> 1480 px`).
- **Use `.ass` subtitles** (`PlayResX: 1080`, `PlayResY: 1920`, `WrapStyle: 2` + explicit `\N` line breaks, `Segoe UI` Bold ~62 px, **equal** `MarginL = MarginR` (100/100) + `MarginV: 430` for subtitles, `MarginL = MarginR` (60/60) + `MarginV: 330` + Alignment `8` for the hook title, UTF-8 without BOM). Asymmetric margins made the title and subtitles look crooked in v1.
- **Word-by-word subtitles (mandatory with narration):** build word timings from `*.alignment.json` (characters between spaces). Group words **per sentence**; split a sentence > 52 chars once at a balanced point (prefer a comma) so no cue is a lonely last word. For each word write one event from that word's start (−0.06 s) to the next word's start, containing the whole cue where not-yet-spoken words are wrapped in `{\alpha&HFF&}…{\alpha&H00&}` (layout stays fixed, words pop in as spoken). End each cue 0.08 s before the next cue starts.
- **Title:** one centred line, ~94 px, warm gold with outline/shadow, `{\fad(450,500)\fscx82\fscy82\t(0,700,\fscx100\fscy100)}` scale-in; extract the title frame and `read_file` it.
- **PowerShell traps (they broke v2 subtitles):** `[math]::Max(0, $x)` uses the Int32 overload and rounds to whole seconds → always `[math]::Max(0.0, $x)` and format ASS time from integer centiseconds; variable names are case-insensitive (`$c` overwrites `$C`); scripts with Turkish text must be saved UTF-8 **with BOM** for PowerShell 5.1. **Verify the .ass** before rendering: no event shorter than 0.05 s, no overlaps, print each cue's full text.
- ffmpeg on this PC has no fontconfig: `drawtext` needs `fontfile=`, libass needs `fontsdir=.` with `segoeuib.ttf` copied next to `subtitles.ass`.
- **Windows `libass` Unicode path note:** If the path contains non-ASCII characters (e.g. a user folder name with `İ`), temporarily copy `subtitles.ass` into the working directory (`Push-Location`), run `ass=subtitles.ass`, then remove the temporary copy.

### 5d. Automatic Cover & Instagram Caption/Hashtag Draft
Always generate both deliverables alongside `final-reels.mp4`:
1. **Reels Cover (`cover-1080x1920.jpg`):** Scale/crop the strongest approved 2K `01-frames\` keyframe to `1080×1920` (`ffmpeg -q:v 2`). Verify with `read_file`.
2. **Instagram Caption & Hashtags:** Append a ready-to-paste Turkish **Instagram Açıklama & Hashtag Taslağı** section to `senaryo.md`.

---

## Stage 6 — Final QA, Delivery & Modular v2 Refinements

1. **Verify `final-reels.mp4`:**
   - Run `ffprobe` to confirm `1080×1920`, `30 fps`, duration, video stream (`h264`), and audio stream (`aac`).
   - Generate a `3×2` or `2×2` timeline contact sheet using `-fps_mode vfr` (FFmpeg 9+, never `-vsync vfr`) and inspect it with `read_file` alongside `cover-1080x1920.jpg` (confirm safe-zone text wrapping, crisp `ç ğ ı İ ö ş ü`, visual continuity, and zero corrupted frames).
2. **Deliver** clickable `file:///` links (forward slashes) to `final-reels.mp4`, `cover-1080x1920.jpg`, `01-frames/storyboard.jpg`, and `senaryo.md` with a concise summary (duration, resolution, production method per scene, total credits/characters spent, and QA checks). Remind the user to listen to the final audio to verify Turkish pronunciation and pacing.
3. **Modular v2 Edits:** Regenerate only the changed asset (`final-reels-v2.mp4`, never overwrite `final-reels.mp4`).

---

## User review of v1 (2026-11-26) — rules that must not be broken again

The first "Fındık ve Kayıp Ay" (60 s children's tale) was rejected; v2 with these fixes was approved ("çok güzel olmuş"):
1. **Voice buried under music** → loudness-based mix with sidechain ducking, measured check (Stage 5b).
2. **Male narrator on a children's tale** → fitting storyteller, samples first. Since 2026-11-26 the free `local-tts` voices are the default; only `yazgi-male-01`, `yazgi-female-02` and `supertonic-M2` passed a blind listening test — never offer other yazgı/Supertonic voices (ElevenLabs free plan = premade voices only).
3. **Narrator too fast** → speed 0.85–0.9 (`local_tts.py --speed` / `tts_generate.ps1 -Speed`); scene length = delay + VO + ~1.1 s, VO must finish inside its own clip.
4. **"Photo-only" scenes** → every scene real video unless the user picks Hybrid.
5. **Static subtitles** → word-by-word reveal from alignment (Stage 5c).
6. **Crooked, ugly title** → centred single line, equal margins, animated, frame checked.
7. **Self-review** → before rendering the whole film, render a **15–16 s draft** (`-t 16`) and get the user's OK; check voice-vs-gap levels, subtitle timing, title frame, every scene moving.

Other practical lessons from that run:
- Gemini `/videos` resets to **Neon Düşük + Yatay** on every page load — set Neon → Düşünme düzeyi → Orta and Dikey (9:16) again before each send (a small `evaluate_script` that clicks the picker, "Düşünme düzeyi", "Orta", the aspect button and "Dikey" works).
- Both accounts can return the **capacity error** at the same time (Google-side, not quota). Fallback: Flow Video with the user's OK — Video · **Kareler** · 9:16 · **Veo 3.1 - Lite** · **x1** (10 credits), **Başlat** = start-frame picker with a search box; download via tile ⋮ → İndir → **720p Orijinal boyut**.
- Chrome blocks repeated downloads from one site after the first — ask the user to allow "multiple downloads" for flow.google.com (address-bar icon); never change Chrome settings yourself.
- Collect each downloaded file by name/time before triggering the next download, so files don't get mixed up.
- Files over ~30 MB are awkward to share; also deliver a CRF 26 copy.

## Rules

- Never start Stage 1/2 production without an active workspace open (warn first if missing).
- Always plan the scenario (`Stage 1`) with Director QA checks and get approval before generating keyframes; always show `storyboard.jpg` (`Stage 2`) before spending Veo quota, narration (local or ElevenLabs characters), or Flow Video credits.
- Never trust `usage-log.csv` alone for remaining Gemini video quota — check live availability in Chrome.
- Never generate Flow Video at `x2`, `x3`, or `x4` by default — strictly **`x1`** and only after explicit user approval of the credit cost.
- Never print/log `ELEVENLABS_API_KEY`; never use paid Gemini/Veo API keys; close every Chrome tab opened during generation (`close_page`).
