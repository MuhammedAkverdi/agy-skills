# agy-skills — Google Antigravity Medya & UI Skilleri

**Google AI Pro** aboneliğiniz üzerinden **ek API ücreti ödemeden** kendi Chrome tarayıcınız (`chrome-devtools` MCP) ile görsel, müzik, video, Türkçe dış ses ve uçtan uca Reels üretmenizi, hibrit anti-slop kurallarıyla profesyonel arayüzler tasarlamanızı sağlayan 6 adet **Antigravity** skill paketi:

| Skill | Platform / Yaklaşım | Maliyet (Google AI Pro) | Öne Çıkan Özellikler |
|---|---|---|---|
| **`/gemini-image`** | Google Flow (`Nano Banana Pro`) + yedek Gemini Chat | **0 kredi** | Ön brifing, 2K indirme, fotoğraf düzenleme, Instagram/YouTube boyutlandırma, yeşil ekranla şeffaf PNG logo |
| **`/gemini-music`** | Google Flow Music (`Lyria 3.5`) | ~5 kredi / şarkı | Ön brifing, Türkçe/İngilizce söz yazımı & onayı, enstrümantal, MP3/WAV/M4A & stem ayırma |
| **`/gemini-video`** | Gemini Pro (`Veo`, `Neon Orta`) | 5 saatlik kullanım sınırı | Canlı limit kontrolü, konuya özel ön brifing, 10 sn 720p sesli klip, 2×2 kare kontrolü, image-to-video (Flow → Veo), Flow Video `x1` yedeği, `ffmpeg` klip birleştirme & müzik miksleme |
| **`/gemini-reels`** | Yukarıdaki skillerin yönetmeni + `ffmpeg` | Görseller 0 kredi, Veo kotası, ~5 kredi müzik, ElevenLabs karakteri | Senaryo + Style Lock, 9:16 görseller, her sahne gerçek video, kadın/erkek anlatıcı örnekleri, müziği sese göre kısan miks, kelime kelime altyazı, ortalı başlık, 16 sn taslak onayı, kapak + Instagram açıklaması |
| **`/elevenlabs-tts`** | ElevenLabs REST API (`/with-timestamps`) | Ücretsiz plan: 10.000 karakter/ay | Türkçe dış ses, `-Speed` ile yavaş anlatım, karakter karakter zaman damgası (altyazı için), ses seçimi kuralları |
| **`/ui-design`** | Hibrit (`taste-skill` + `frontend-design` + `impeccable`) | Ücretsiz (yerel + Chrome MCP) | Yüzey modu & iş türü kuralları, 2 aşamalı Design Thesis (Anti-Slop Swap Test), `1440×900` & `390×844` Chrome görsel kapısı, `critique` / `polish` / `audit` |

---

## Gereksinimler

1. **Google Antigravity** (IDE veya CLI)
2. **Google AI Pro** aboneliği (medya skilleri için kendi Chrome tarayıcınızda oturumu açık olmalı)
3. **`chrome-devtools` MCP eklentisi** (Antigravity Plugins üzerinden kurulu ve aktif)
4. **`ffmpeg` ve `ffprobe`** (video kare kontrolü, boyutlandırma, şeffaf PNG ve klip birleştirme için)
   - Windows: `winget install Gyan.FFmpeg`
   - macOS: `brew install ffmpeg`
   - Linux (Ubuntu/Debian): `sudo apt install ffmpeg`
5. **ElevenLabs API anahtarı** (`/elevenlabs-tts` ve `/gemini-reels` dış sesi için; ücretsiz plan yeterli). Kendi PowerShell'inizde bir kez çalıştırın, yazdığınız görünmez ve geçmişe kaydedilmez:
   ```powershell
   $k = Read-Host "ElevenLabs anahtari" -AsSecureString; [Environment]::SetEnvironmentVariable('ELEVENLABS_API_KEY',[Net.NetworkCredential]::new('',$k).Password,'User')
   ```
   Not: Ücretsiz planda ElevenLabs kütüphanesindeki anadili Türkçe anlatıcılar API'den kullanılamaz (`paid_plan_required`); hazır sesler (ör. Matilda) çalışır.

---

## Hızlı Kurulum

### Windows (PowerShell)

```powershell
git clone https://github.com/MuhammedAkverdi/agy-skills.git
cd agy-skills
.\install.ps1
```

### macOS / Linux

```bash
git clone https://github.com/MuhammedAkverdi/agy-skills.git
cd agy-skills
bash install.sh
```

### Manuel Kurulum

Kurulum script'leri aynı isimdeki eski skilleri `skills-backup-<tarih>` klasörüne yedekler, mevcut `usage-log.csv` ve `.env` dosyalarınızı korur. Sadece bazılarını kurmak için: `.\install.ps1 -Only gemini-reels,elevenlabs-tts` veya `bash install.sh gemini-reels elevenlabs-tts`.

Manuel kurulum için `skills/` klasörünün içindeki skill klasörlerini (`gemini-image`, `gemini-music`, `gemini-video`, `gemini-reels`, `elevenlabs-tts`, `ui-design`) alt dosyalarıyla birlikte Antigravity'nin global skill dizinine kopyalayın:

- **Windows:** `C:\Users\<KullanıcıAdı>\.gemini\config\skills\`
- **macOS / Linux:** `~/.gemini/config/skills/`

Kurulumdan sonra Antigravity'de **yeni bir sohbet** açtığınızda skiller otomatik olarak yüklenir.

---

## Chrome Bağlantısı (`chrome-devtools` MCP)

Skiller, oturumu zaten açık olan gerçek Chrome tarayıcınızı kontrol eder (medya üretimi için şifre girmeniz gerekmez; `/ui-design` ise sayfayı `1440×900` ve `390×844` boyutlarında açıp görsel hata denetimi yapar):

1. Antigravity'de **Chrome DevTools** MCP eklentisinin açık olduğundan emin olun.
2. Chrome'da `chrome://inspect/#remote-debugging` sayfasını açıp uzaktan hata ayıklamaya izin verin (Chrome ilk bağlantıda onay ister).
3. Chrome'da [flow.google.com](https://flow.google.com), [flowmusic.app](https://www.flowmusic.app) ve [gemini.google.com](https://gemini.google.com) sitelerinde Google AI Pro hesabınızla oturum açılmış olsun.

---

## Kullanım

Skilleri doğrudan slash komutuyla çağırabilir veya doğal dilde isteğinizi yazabilirsiniz:

### 1. `/gemini-image` — Görsel Üretme & Düzenleme

```text
/gemini-image Boğaz manzaralı gün batımında ince belli bardakta Türk çayı, Instagram gönderisi için
```

- Varsayılan olarak önce **3–4 kısa ön brifing sorusu** sorar (format, stil, ışık, yazı vb.), ardından **Google Flow (Nano Banana Pro, 0 kredi)** üzerinden üretir, görseli indirip kalite kontrolü yapar ve `.prompt.txt` dosyasıyla teslim eder.
- Soru sormadan hızlı üretim için mesajınıza **`hızlıca`** veya **`direkt`** ekleyin:
  ```text
  /gemini-image hızlıca minimal bir kahve dükkanı logosu yap, şeffaf PNG olsun
  ```

### 2. `/gemini-music` — Şarkı & Fon Müziği Üretme

```text
/gemini-music İstanbul sabahını anlatan sıcak akustik Türkçe pop şarkı yap
```

- Önce kısa sorular sorar, sözlü ise **şarkı sözlerini ve ses tarifini onayınıza sunar**, onaydan sonra **Flow Music (Lyria 3.5)** üzerinden üretir, otomatik çalmayı duraklatır ve MP3/WAV olarak indirir.
- Enstrümantal veya hızlı test için:
  ```text
  /gemini-music direkt 85 BPM ney ve akustik gitarlı sakin enstrümantal fon müziği üret
  ```

### 3. `/gemini-video` — Kısa AI Video & Klip Üretme

```text
/gemini-video Sisli Karadeniz kıyısında gün doğumunda yükselen sinematik drone çekimi
```

- Önce Chrome'da 5 saatlik kullanım sınırına göre video aracının açık olup olmadığını **canlı kontrol eder**, konuya özel dinamik ön brifing soruları sorar (en fazla 6) ve **üretmeden önce son onayınızı** alır (yedek olarak Flow Video gerekirse maliyeti ve varsayılan `x1` kilidini bildirir).
- Üretim bitince videoyu indirir, `ffmpeg` ile **2×2 kare kontrolü** yapar ve sonucu teslim eder.
- Birden fazla klip üretip `ffmpeg` ile birleştirebilir veya `/gemini-music` ile arka plan müziği ekleyebilir.

### 4. `/gemini-reels` — Uçtan Uca Reels / Shorts / TikTok

```text
/gemini-reels 60 saniyelik bir çocuk masalı reels'i yap, kadın anlatıcı olsun
```

- Önce süreyi (saniye), anlatıcı sesini ve ses yapısını sorar; senaryoyu ve **storyboard**'u onayınıza sunmadan kota/kredi harcamaz.
- Görselleri Flow'da 9:16 üretir, **her sahneyi gerçek video** olarak Veo'da canlandırır (iki hesap paralel), anlatıcı için 2–3 ses örneği dinletir, Flow Music'te fon müziği yapar.
- `ffmpeg` ile birleştirir: anlatıcı müziğin en az 8 dB üstünde (ölçülerek), müzik konuşurken otomatik kısılır, **altyazı kelime kelime** gelir, başlık ortalı ve animasyonlu. Tamamını yapmadan önce **16 sn'lik taslağı** onaylatır.
- Teslim: `final-reels.mp4`, kapak, storyboard ve Instagram açıklaması + hashtag'ler.

### 5. `/elevenlabs-tts` — Türkçe Dış Ses

```text
/elevenlabs-tts Bu metni sıcak bir kadın sesiyle, yavaş tempoda seslendir
```

- Kota ve ses listesini kontrol eder, metni ve sesi onaylatır, sahne başına `vo-01.mp3` + `alignment.json` (altyazı zamanlaması) üretir. Masallarda `-Speed 0.85–0.9` önerir.

### 6. `/ui-design` — Anti-Slop UI & Frontend Tasarımı

```text
/ui-design Yerel edge API izleme aracı için sade ve keskin teknik landing page tasarla
```

- Varsayılan olarak kısa ön brifing alır, ardından 2 aşamalı **Design Thesis (Swap Test)** ile 2026 AI klişelerini eler (`craft-floor.md`), arayüzü yazar ve Chrome'da `1440×900` + `390×844` görünümlerini ekran görüntüsüyle inceleyip `polish` turundan geçirir.
- Hızlı tek adımda üretim veya mevcut arayüzü iyileştirme komutları:
  ```text
  /ui-design hızlıca SaaS fiyatlandırma sayfası yap
  /ui-design polish src/app/page.tsx
  /ui-design critique http://localhost:3000
  /ui-design audit
  ```

---

## Klasör Yapısı

```text
agy-skills/
├── README.md
├── LICENSE
├── install.ps1                  # Windows kurulum scripti
├── install.sh                   # macOS / Linux kurulum scripti
└── skills/
    ├── gemini-image/
    │   └── SKILL.md
    ├── gemini-music/
    │   └── SKILL.md
    ├── gemini-video/
    │   ├── SKILL.md
    │   └── usage-log.csv        # Video üretim geçmişi şablonu
    ├── gemini-reels/
    │   └── SKILL.md
    ├── elevenlabs-tts/
    │   ├── SKILL.md
    │   └── scripts/
    │       ├── check_quota.ps1  # Kota + ses listesi
    │       └── tts_generate.ps1 # Dış ses + zaman damgası (-Speed destekli)
    └── ui-design/
        ├── SKILL.md
        └── references/
            ├── craft-floor.md
            └── critique-and-polish.md
```

---

## Lisans

[MIT](LICENSE)
