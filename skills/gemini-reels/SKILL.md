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
- **Identity QA (`0 credits`, local ArcFace):** `$env:USERPROFILE\.gemini\config\skills\gemini-reels\scripts\face_qa.py` via `%USERPROFILE%\.face-qa\venv\Scripts\python.exe` (InsightFace `buffalo_l` cosine similarity gate for face keyframes `>= 0.50` and video clips `>= 0.48`)
- **Assembly & Packaging:** `ffmpeg` / `ffprobe` via `run_command`, visual QA via `read_file`.

Read the relevant sibling `SKILL.md` before executing its steps so all DOM selectors, scripts, watchers, and safety rules stay exact.

## Project Workspace Layout (Active Workspace Mandatory)

- **Default location:** Always create the project folder `<active-workspace>\reels-<slug>\` inside the user's currently open **active workspace** (so `upload_file` and project deliverables stay cleanly inside the workspace).
- **No active workspace check:** If NO active workspace is open at Stage 0, **warn the user before starting production**: *"Image-to-Video ve dosya teslimi için bir çalışma klasörü (workspace) açık olmalı; lütfen bir klasör açıp devam edin."*
- **`chrome-devtools` `upload_file` fallback:** If `chrome-devtools-mcp` lacks `--workspace` in `mcp_config.json` and rejects a workspace path with `Access denied ... is not within any of the configured workspace roots`, immediately copy the upload images into `$env:TEMP\agy-upload\`, upload from there, and delete `$env:TEMP\agy-upload\` once submitted.

```text
<active-workspace>\reels-<slug>\
├── senaryo.md               # Scenario, Style Lock, scene table, live limit check, IG caption & hashtags
├── 00-bible\                # Character & Asset Bible (ref-char-sheet.jpg, ref-prop.jpg, ref-location.jpg, bible-sheet.jpg)
├── 01-frames\               # 9:16 2K Flow keyframes (scene-01.jpg ...), prompt sidecars, storyboard.jpg
├── 02-clips\                # Raw Veo / Flow x1 (Omni 1.2 Flash İçerik öğeleri) clips, 2x2 contact sheets
├── 03-audio\                # Voiceovers (vo-01.mp3 + .alignment.json, local-tts or ElevenLabs) + Flow Music (soundtrack.mp3)
├── cover-1080x1920.jpg      # Graded 1080x1920 Reels cover image
├── final-reels.mp4          # Final 1080x1920, 24 fps (or 30 fps kinetic), H.264 + AAC Reels video
└── final-reels-share.mp4    # Lightweight CRF 26 share copy (< 35 MB)
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

### 3-Concept Hook Pitch Gate (Mandatory when topic is open)
Whenever the user leaves the story/topic open ("konusu sana ait", "senaryosu senin", or only gives a duration/tone), **NEVER write `senaryo.md` on the first idea you invent**. First pitch **3 genuinely different 2-line concepts** (spanning distinct genres/angles — e.g., psychological/crime twist, sharp observational comedy/irony, high-stakes human/historical mystery — each naming its **0–2 s Hook**, **Core Conflict**, and **Final Payoff/Twist**) via `ask_question` and let the user pick or steer one BEFORE drafting the script.

### Anti-AI-Slop Storytelling & Script Quality Rules (Mandatory Self-Check)
1. **0–2 s Scroll-Stopping Hook (*In Media Res*):** Never open with slow scenic atmosphere or generic exposition ("Bir varmış...", "Karadeniz'in sisli patikasında..."). Start immediately inside an unexpected discovery, contradiction, bold claim, physical stakes, or unanswered question.
2. **Real Conflict, Escalation & Twist/Payoff:** A reel needs dramatic tension where each scene complicates the problem or flips what the viewer believes, ending with a genuine reversal, punchline, or earned payoff. **Ban linear errand plots** (`find lost item -> walk -> hand it back -> sentimental quote`).
3. **Zero Filler / No Consecutive Walking or B-Roll Shots:** Every scene must reveal new information, escalate tension, or deliver an action beat. **Never pad runtime with 2+ consecutive walking, driving, or scenery shots.**
4. **Ban AI Clichés & Melodramatic Platitudes:** Explicitly ban worn-out AI tropes (*misty pine forest + old analog camera/yellowed 1994 photo + tearful grandmother/elderly widow + Hallmark wisdom ending like "Bazen kaybolan bir eşya değil, yarım kalmış bir hikâyedir"*) unless the user explicitly asks for that trope. Write crisp, grounded, spoken Turkish — no textbook sentimentality or fake poetic filler.
5. **Mandatory 5-Point Script Brutality Audit (run internally before Approval Gate #1):**
   - *Scroll-stop test:* Would a real viewer pause in the first 2 seconds, or swipe away?
   - *Conflict test:* Does something actually go wrong, resist, or surprise between scenes 3 and 9?
   - *Trim-fat test:* If any scene only moves a character from A to B without changing the story state, cut or merge it.
   - *Payoff test:* Does the ending recontextualize or punch up the opening instead of tapering into an empty inspirational platitude?
   - *Speech test:* Read every Turkish line aloud — would a human actually say it on Instagram Reels without sounding cringe or synthetic?
6. **Logical Continuity & No Frame-1 Spoilers:** Never jump abruptly between story states without a bridge, and never reveal a climax surprise in frame 1 (`scene-0X.jpg`) before the motion/reveal plays out.
7. **1 Core Action, Tight Trim & Lip-Sync Alignment:** Keep each scene to **1 primary visual action** and **1–2 crisp lines**. Plan trim length to `vo_dur + 0.6–0.8 s`. When pairing with `local-tts` / `elevenlabs-tts`, instruct the video model: `"No spoken dialogue, characters do not move their lips to speak, natural ambient sound effects only"`.

### Style Lock, Scene Table & Cost Plan
1. **Define a `Style Lock` (Visual DNA) — Contamination Guard:** One concise English block copied verbatim into **every** scene prompt specifying **ONLY camera, lens, lighting, color palette, film stock, and atmospheric tone**. **NEVER include character clothing, hair, age, or props in `Style Lock`** (otherwise unrelated location or object shots inherit the hero's jacket or face).
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

## Stage 2 — Character & Asset Bible + 9:16 Keyframes + Face QA (`gemini-image`, Approval Gate #2)

1. Open **one single Google Flow project** (`https://labs.google/fx/tools/flow` → `Yeni proje`) with Flow Agent **OFF**, **Resim**, **9:16**, **Nano Banana Pro**, **`x2`** (`0 kredi`).
2. **Seedance-Style Character & Asset Bible (`00-bible\`, `0 credits`):** Before generating story scenes, create 2K reference sheets in `00-bible\` for every recurring character (e.g. `ref-char-sheet.jpg` 3-angle portrait/outfit sheet), hero prop (`ref-prop.jpg`), and recurring key location (`ref-location.jpg`). Stack into `00-bible\bible-sheet.jpg`, inspect with `read_file`, and get quick user approval (`ask_question`) before generating keyframes.
3. **POV / Hands-First Framing Strategy:** To prevent AI face-morphing in long Reels, rely on POV, hands-on-props, over-the-shoulder, silhouette, and wide framing for most scenes; show each protagonist's unobstructed face in **only 2–3 critical emotional scenes**.
4. **Reference-Locked Keyframes (`01-frames\`):** Always include the exact `Style Lock`, **and attach the matching `00-bible\` reference(s)** via Flow's **`⋮ -> İsteme ekle`** on main grid tiles or **`+ -> Öğe arayın`** (select by `thumbId`; note `CDK-VIRTUAL-SCROLL-VIEWPORT` uses `storage.googleapis.com` URLs vs main grid `flow.google.com/asb/...`). Never mix unrelated character refs into prop-only shots.
5. **Download & Automated Local ArcFace QA Gate (`face_qa.py`):** Download the best 2K variant (`01-frames\scene-01.jpg` ...). Inspect every frame with `read_file`. For every scene showing a recurring face, run:
   ```powershell
   & "$env:USERPROFILE\.face-qa\venv\Scripts\python.exe" "$env:USERPROFILE\.gemini\config\skills\gemini-reels\scripts\face_qa.py" `
     --ref "00-bible\ref-char-sheet.jpg" --target "01-frames\scene-0X.jpg" --threshold 0.50
   ```
   Regenerate any failing (`pass: false` / `< 0.50`) face frame (zero credit cost in Flow Resim) BEFORE spending any video quota/credits.
6. Build a side-by-side storyboard strip (`storyboard.jpg`):
   ```powershell
   ffmpeg -v error -y -i scene-01.jpg -i scene-02.jpg -i scene-03.jpg -filter_complex "[0]scale=-1:600[a];[1]scale=-1:600[b];[2]scale=-1:600[c];[a][b][c]hstack=inputs=3" -q:v 2 storyboard.jpg
   ```
   (Adjust inputs count to match scenes.) Inspect `storyboard.jpg` with `read_file` and present it (plus ArcFace keyframe scores) to the user for **Approval Gate #2** before spending any video quota/credits.

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

### Priority 2: Google Flow Video (Veo fallback OR Multi-Reference Identity Lock — ONLY after user credit approval)
- **Single-Model Lock (Mandatory):** Never mix different video models within the same Reels film (e.g., half Veo + half Omni), because grain, lens sharpness, and skin rendering shift noticeably across cuts.
- **Multi-Reference Identity Mode (`Omni 1.2 Flash · İçerik öğeleri`, verified 2026-11-26):** When strict Seedance-style character/prop consistency is the top priority (or Veo quota is out), use **Flow Video (`Video · 720p · 9:16 · İçerik öğeleri · x1`)** with `Omni 1.2 Flash`:
  - Verified live pricing: **`8 sn. = 24`**, **`9 sn. = 27`**, **`10 sn. = 30`**, **`11 sn. = 36`** credits per clip (note **Veo 3.1 - Lite · `Kareler` · `x1`** is `10 credits` for single start-frame animation).
  - Attach **both** the scene keyframe (`01-frames\scene-XX.jpg`) **and** the matching primary `00-bible\` reference (`ref-char-sheet.jpg` / `ref-prop.jpg`) inside `İçerik öğeleri` so subject identity remains locked throughout the motion.
- **CRITICAL `x1` CREDIT GUARD:** Google Flow can generate up to 4 copies (`x1–x4`) of the same video prompt, which multiplies credit burn up to 4×.
  - Before submitting ANY video prompt in Google Flow, open the settings chip and **verify it says `Video` · `9:16` · `x1`** (NEVER `x2`, `x3`, or `x4` unless the user explicitly asks for variants).
  - Verify the exact footer credit cost matches what the user approved.
- **Post-Video ArcFace + Visual QA:** Filter Flow to `Videolar`, serialize Download + `Move-Item` one clip at a time (never fire parallel downloads), inspect `2×2` contact sheets via `read_file`, AND run `face_qa.py --ref <bible> --video <clip> --samples 4 --threshold 0.48` on every human-face clip.

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

### 5a. Trim, Overscan Crop, Filmic Grade & Normalize
Trim each clip to its tight scripted duration (`-t <dur>`, matched to `vo_dur + 0.6–0.8 s`, skipping dead air).
- **24 fps realistic default:** Use **`fps=24`** for realistic/documentary/cinematic Reels (`fps=30` only for fast kinetic/commercial edits).
- **3.5% Overscan Crop + Kodak Vision3 Filmic Pass:** `35mm`-prompted Flow frames often have tiny dark rounded film-gate corners, and raw AI clips look overly digital. Apply a 3.5% overscan crop (`scale=1120:1992...,crop=1080:1920`), lifted blacks/soft highlight curve, cool-shadow/warm-highlight `colorbalance`, `eq`, temporal 35mm grain (`noise=alls=7:allf=t+u`), and subtle `vignette=PI/6` uniformly to every clip:

```powershell
$filmVf = "scale=1120:1992:force_original_aspect_ratio=increase:flags=lanczos,crop=1080:1920,fps=24,setsar=1,curves=m='0/0.03 0.25/0.23 0.5/0.50 0.75/0.76 1/0.96',colorbalance=rs=-0.02:gs=0.00:bs=0.03:rm=0.01:gm=0.00:bm=-0.01:rh=0.02:gh=0.01:bh=-0.02,eq=saturation=0.90:contrast=1.04,noise=alls=7:allf=t+u,vignette=PI/6,format=yuv420p"
ffmpeg -v error -y -i $raw -t $trimDur -vf $filmVf -c:v libx264 -crf 18 -preset medium -c:a aac -ar 48000 -ac 2 $norm
```
*(If a clip has no audio stream, add `-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 -shortest`. In PowerShell scripts run on Windows systems with non-ASCII paths such as `[char]0x0130` (`İ`), construct paths via `[char]0x0130` or `$env:USERPROFILE` and stage `ffmpeg`/OpenCV/libass temp files in `$env:TEMP\...` ASCII workdirs; `face_qa.py` already handles Unicode paths via `np.fromfile` + temp video copy.)*

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

### 5d. Automatic Cover, Share Export & Instagram Caption/Hashtag Draft
Always generate both deliverables alongside `final-reels.mp4` + `final-reels-share.mp4` (`-crf 26`, `< 35 MB`):
1. **Reels Cover (`cover-1080x1920.jpg`):** Apply the same 3.5% overscan crop + filmic color grade (without heavy motion noise) to the strongest approved 2K `01-frames\` keyframe at `1080×1920` (`ffmpeg -q:v 2`). Verify with `read_file`.
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
- Files over ~30 MB are awkward to share; also deliver a CRF 26 copy (`final-reels-share.mp4`).

## User review of v2 (2026-11-27) — character lock succeeded, cliché script rejected

After "Sisli Patika" v1 was rejected for character drift and synthetic look, v2 proved the technical architecture works:
- **What worked (`v2` pass):** Seedance-style `00-bible/` multi-reference + POV/hands-first framing + single-model **`Omni 1.2 Flash · İçerik öğeleri · x1`** + **`face_qa.py`** (ArcFace `buffalo_l` scores jumped from `0.24–0.37` in v1 to `0.67–0.82` across all keyframes and final videos) + `24 fps` Kodak Vision3 filmic grade + 3.5% overscan crop cleanly solved character drift and synthetic glossy AI skin/lighting.
- **What failed (`"senaryo berbat kötü olmuş"`):** The story itself (*finding a muddy 1994 camera on a misty Black Sea trail -> walking to a cabin -> returning it to an emotional grandmother -> "Bazen kaybolan bir eşya değil..."*) was pure linear AI-slop with zero real conflict, consecutive walking filler, and a cliché sentimental moral.
- **Mandatory rules added:** Never skip the **3-Concept Hook Pitch Gate** when the topic is open; enforce an **0–2 s hook**, **real conflict + reversal/twist**, **zero consecutive walking/b-roll filler**, **strict ban on AI cliché tropes/platitudes**, and the **5-Point Script Brutality Audit** in Stage 1.

## Self-Revision on Errors (Mandatory)

If any error, UI/DOM change, FFmpeg/ASS/PowerShell bug, Unicode path trap, video/voice QA failure, or script/creative failure occurs while running this skill and you diagnose or fix it, **immediately revise this `SKILL.md`** (and update `scripts/face_qa.py` or the sibling skill when affected) with the root cause and verified fix before finishing the task, and tell the user what rule was updated.

## Rules

- Never start Stage 1/2 production without an active workspace open (warn first if missing).
- Always pitch 3 concepts first when topic is open, pass the Anti-AI-Slop & Brutality Audit (`Stage 1`), and get approval before generating keyframes/Bible; always show `00-bible/bible-sheet.jpg`, `storyboard.jpg`, and ArcFace `face_qa.py` results (`Stage 2`) before spending Veo quota, narration, or Flow Video credits.
- Never trust `usage-log.csv` alone for remaining Gemini video quota — check live availability in Chrome.
- Never generate Flow Video at `x2`, `x3`, or `x4` by default — strictly **`x1`** and only after explicit user approval of the credit cost.
- Never print/log `ELEVENLABS_API_KEY`; never use paid Gemini/Veo API keys; close every Chrome tab opened during generation (`close_page`).
