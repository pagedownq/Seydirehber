# Seydi Rehber — "ŞEHİR MODU" (oyun seviyesi tanıtım videosu)

## Ana fikir

Seydişehir'de günlük hayat bir video oyunu bölümü gibi anlatılır. İzleyici "Oyuncu 1"dir; her gündelik dert
(gece nöbetçi eczane bulmak, otobüse yetişmek, pazarın gününü bilmek…) ekrana bir **GÖREV** olarak düşer.
Seydi Rehber oyunun **güç-yükseltmesi (power-up)**'dir: ikon ekrana düştüğü anda görev çözülür, XP dolar,
combo artar, sonunda "SEVİYE ATLADIN — SEYDİŞEHİR UZMANI" başarımı açılır ve "OYUNA DEVAM ET? → İNDİR"
ile kapanır.

Tek cümlelik mesaj: **"Seydişehir'de her görev tek dokunuş: Seydi Rehber."**

## Görsel dünya

- **Zemin:** gece arcade'i — çok koyu lacivert/mor (#0A0820 → #1A1240), üstünde ince CRT tarama çizgileri ve
  hafif vinyet. Piksel ızgara desenleri dekor olarak kullanılır (ekran görüntüsü / uygulama arayüzü YOK).
- **Tipografi:** Oyun kelimeleri (PRESS START, LV, XP, COMBO, +500, 1UP, HIGH SCORE) **Press Start 2P** piksel
  fontu — sadece ASCII karakterli kelimeler, çünkü font Türkçe harfleri (ş, ğ, ı, İ) taşımıyor. Türkçe
  cümleler **Poppins ExtraBold** (uygulamanın fontu).
- **Renkler:** neon yeşil #4CAF50 (marka, XP ve başarı), altın #FFC107 (coin, skor), neon pembe #FF4FA3 ve
  camgöbeği #29E6FF (vurgular). Görev kartları uygulamadaki hizmet renkleriyle (eczane kırmızı #E53935,
  otobüs teal #00897B, pazar turuncu #FF8F00…).
- **İkonlar:** uygulamanın kendi MaterialIcons glifleri (local-pharmacy, directions-bus, storefront, map,
  newspaper, forum, work, event, wb-sunny, local-offer) — beyaz, piksel çerçeveli "item kutusu" içinde.
- **Power-up:** gerçek uygulama ikonu (assets/icon.png) yukarıdan dönerek düşer, parıltı halkası ve
  "POWER UP!" yazısıyla.
- **HUD (kalıcı katman, 8,5–37,5 sn):** üstte sol "LV 1", ortada XP çubuğu, sağda coin sayacı. Bütün
  görevler boyunca aynı yerde durur, değerler sahnelerle birlikte artar — tek dünya hissi.

## Ses

Müzik yok (Instagram'da eklenir). 8-bit SFX: menü bip'i, PRESS START onayı, coin, power-up, görev tamam
jingle'ı, combo tıkları, level-up fanfarı, kapanışta vuruş + zil.

## Format

Instagram Reels / TikTok, dikey 1080×1920, **46 sn**, Türkçe, 60 fps render. Önemli içerik title-safe
(%10 kenar boşluğu) içinde.

## Sahne planı (zamanlar global, saniye)

| # | Sahne | Zaman | Süre | İçerik ve hareket |
|---|---|---|---|---|
| 1 | **BOOT** | 0,0–4,0 | 4,0 | Siyah CRT, ortadan yatay çizgi açılır (TV açılışı). "SEYDI REHBER presents" (0,5). "PRESS START" yanıp söner (1,2–3,0, 3 kez). 3,2'de basılır: beyaz flaş + ekran sarsıntısı + bip. |
| 2 | **BAŞLIK + GÖREV TAHTASI** | 4,0–8,5 | 4,5 | Piksel karolar ekrana yağar, "SEYDİŞEHİR" + piksel alt yazı "SEHIR MODU" logo olarak çarpar (4,1–5,2). 5,6'da logo yukarı küçülür, "GÖREV LİSTESİ" paneli açılır: 6 kilitli görev satırı sırayla belirir (her biri 0,12 sn arayla), kilit ikonları sallanır. 7,8'de "OYUNCU 1: SEN — HAZIR MISIN?" |
| 3 | **GÖREV 1 — NÖBETÇİ ECZANE** | 8,5–16,0 | 7,5 | Görev kartı çarpar: "GÖREV 1", "Gece 02:00. Nöbetçi eczaneyi bul." zorluk ★★★ (8,5–10,3, okuma süresi ≥1,8 sn). Gece şehri: piksel ızgara sokaklar, karanlık, "?" işaretleri yanıp söner, oyuncu imleci dolanır (10,3–11,8). 11,8'de POWER-UP: uygulama ikonu düşer, halka patlar. 12,3'te sokaklar aydınlanır, kırmızı eczane pini zıplar "BULUNDU!" (12,5). 13,6 "GÖREV TAMAM ✓" + "+500 XP" uçar, coinler HUD'a akar, XP çubuğu %35'e dolar (13,6–16,0). |
| 4 | **GÖREV 2 — OTOBÜSE YETİŞ** | 16,0–22,5 | 6,5 | Kart: "GÖREV 2", "Sıradaki otobüs kaçta?" (16,0–17,6). Koşu şeridi: teal otobüs sağdan sola akar, imleç peşinden koşar, "ACELE ET!" titrer (17,6–19,2). POWER-UP (19,2): saat panosu döner "SAAT SAAT, HAT HAT", otobüs durur, imleç biner (19,6–20,8). "GÖREV TAMAM ✓ +400 XP", "COMBO x2" (20,8–22,5). XP %60. |
| 5 | **BONUS TURU** | 22,5–32,5 | 10,0 | "BONUS TURU!" piksel yazı + geri sayım 3-2-1 (22,5–23,7). 8 mini görev kartı arka arkaya ekranın ortasına çarpar, her biri ~1,1 sn: Halk Pazarları, Hava Durumu, Seydi Harita, Etkinlikler, Haberler, Forum, İş İlanları, Kuponlar. Her kartta ikon + ad + "✓ +100", COMBO sayacı x3 → x10 büyür, coin sesi, XP %60 → %100. |
| 6 | **SEVİYE ATLADIN** | 32,5–37,5 | 5,0 | XP çubuğu taşar, beyaz flaş, "LEVEL UP!" piksel dev yazı (32,6). "LV 1 → LV 99" sayacı döner. Başarım rozeti açılır: altın çerçeve, "BAŞARIM AÇILDI — Seydişehir Uzmanı", alt satır "Şehri cebine sığdırdın." (33,8–37,5), konfeti pikselleri. |
| 7 | **SKOR + DEVAM?** | 37,5–41,0 | 3,5 | "HIGH SCORE" tablosu: 1. SEN 9.999.999 — görevler 10/10 (37,5–39,0). "OYUNA DEVAM ET?" ve 9 → 7 geri sayım, "EVET" butonu yanıp söner (39,0–41,0). |
| 8 | **KAPANIŞ (CTA)** | 41,0–46,0 | 5,0 | "EVET" seçilir, yeşil zemin aşağıdan dolar. Uygulama ikonu düşüp yaylanır, "Seydi Rehber", "Seydişehir'in rehberi cebinde.", App Store · Google Play rozetleri, "Ücretsiz indir". Son 2 sn yavaş itme. |

## Okunabilirlik ve tempo kuralları

- Türkçe cümle ekranda en az ~1,5 sn (görev başlıkları 1,6–1,8 sn), tek kelime vuruşlar 0,4 sn yeterli.
- Her sahnede en az bir sürekli hareket (ızgara kayması, nefes alan ikon, yavaş zoom) — kare hiç donmaz.
- Vuruşlar SFX ile aynı karede: çarpma = impact/coin, kart girişi = bip, power-up = yükselen ses.
- Kesmeler sert (oyun hissi); sahne içi geçişler flaş, sarsıntı ve piksel silme (wipe).
- HUD yalnızca görevlerde görünür (8,5–37,5); boot, başlık ve CTA temiz kalır.

## Teknik

- Proje: `videos/seydi-rehber-oyun/`, sahne başına bir alt kompozisyon (`compositions/g-*.html`), HUD ayrı
  alt kompozisyon ve ayrı izde, SFX ses izlerinde.
- Sayaçlar (XP, coin, skor) seek-safe GSAP tween ile; rastgelelik yok (konfeti konumları sabit tohumdan).
- Uydurma bilgi yok: gerçek eczane adı, otobüs saati, pazar günü yazılmaz.
