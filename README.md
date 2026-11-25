# agy-skills — Google Antigravity Medya Skilleri

**Google AI Pro** aboneliğiniz üzerinden **ek API ücreti ödemeden**, doğrudan kendi Chrome tarayıcınız (`chrome-devtools` MCP) aracılığıyla görsel, müzik ve video üretmenizi sağlayan 3 adet **Antigravity** skill paketi:

| Skill | Platform & Model | Maliyet (Google AI Pro) | Öne Çıkan Özellikler |
|---|---|---|---|
| **`/gemini-image`** | Google Flow (`Nano Banana Pro`) + yedek Gemini Chat | **0 kredi** | Ön brifing, 2K indirme, fotoğraf düzenleme, Instagram/YouTube boyutlandırma, yeşil ekranla şeffaf PNG logo |
| **`/gemini-music`** | Google Flow Music (`Lyria 3.5`) | ~5 kredi / şarkı | Ön brifing, Türkçe/İngilizce söz yazımı & onayı, enstrümantal, MP3/WAV/M4A & stem ayırma |
| **`/gemini-video`** | Gemini Pro (`Veo`, `Neon Orta`) | 5 saatlik hareketli kota | Ön brifing, 10 sn 720p sesli klip, 2×2 kare kontrolü, image-to-video (Flow → Veo), `ffmpeg` klip birleştirme & müzik miksleme |

---

## Gereksinimler

1. **Google Antigravity** (IDE veya CLI)
2. **Google AI Pro** aboneliği (kendi Chrome tarayıcınızda oturumu açık olmalı)
3. **`chrome-devtools` MCP eklentisi** (Antigravity Plugins üzerinden kurulu ve aktif)
4. **`ffmpeg` ve `ffprobe`** (video kare kontrolü, boyutlandırma, şeffaf PNG ve klip birleştirme için)
   - Windows: `winget install Gyan.FFmpeg`
   - macOS: `brew install ffmpeg`
   - Linux (Ubuntu/Debian): `sudo apt install ffmpeg`

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

`skills/` klasörünün içindeki `gemini-image`, `gemini-music` ve `gemini-video` klasörlerini Antigravity'nin global skill dizinine kopyalayın:

- **Windows:** `C:\Users\<KullanıcıAdı>\.gemini\config\skills\`
- **macOS / Linux:** `~/.gemini/config/skills/`

Kurulumdan sonra Antigravity'de **yeni bir sohbet** açtığınızda skiller otomatik olarak yüklenir.

---

## Chrome Bağlantısı (`chrome-devtools` MCP)

Skiller, oturumu zaten açık olan gerçek Chrome tarayıcınızı kontrol eder (böylece şifre girmeniz gerekmez):

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

- Önce son 5 saatteki **kota kaydını (`usage-log.csv`)** kontrol eder, kamera hareketi/ses/format için kısa sorular sorar ve **üretmeden önce son onayınızı** alır.
- Üretim bitince videoyu indirir, `ffmpeg` ile **2×2 kare kontrolü** yapar ve sonucu teslim eder.
- Birden fazla klip üretip `ffmpeg` ile birleştirebilir veya `/gemini-music` ile arka plan müziği ekleyebilir.

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
    └── gemini-video/
        ├── SKILL.md
        └── usage-log.csv        # Boş kota takip şablonu
```

---

## Lisans

[MIT](LICENSE)
