---
workflow: product-launch-video
flow: automation
storyboard: no
message: "Seydişehir cebinde: nöbetçi eczane ve otobüs saatleri tek dokunuşta"
destination: instagram-reels
aspect: 1080x1920
language: tr
audience: "Seydişehir'de yaşayanlar ve ziyaretçiler"
length: 30s
angle: problem-solution
---

## Intent

Seydi Rehber (App Store + Google Play'de canlı) için dikkat çekici, dikey tanıtım videosu.
Kullanıcı: "kullanıcının dikkatini genelde nöbetçi eczaneler ve otobüs saatleri çok bakılıyor bunlara ağırlık verilerek".
Kurgu: gece eczane arama derdi + durakta otobüs bekleme derdi → uygulama çözer → diğer özellikler kısa montaj → mağaza CTA.

## Assets

- C:/Users/MEHMET/Desktop/seydirehberekranfotolari/ — canlı uygulama ekran görüntüleri (ana sayfa hizmet kartları, otobüs saatleri, gezilecek yerler, forum, haberler). Ayarlar ekranları kişisel bilgi içerir — kullanılmaz.

## Customizations

- Nöbetçi eczane ekranı görüntüsü yok (WebView); uygulamanın kırmızı "Nöbetçi Eczane" kart dilinde stilize kart çizilir, gerçek eczane adı uydurulmaz.
- Marka: yeşil #4CAF50, Poppins, kart renkleri (eczane kırmızı, otobüs teal).

## Notes

- Müzik yok (HeyGen girişi yok, yerel MusicGen kurulu değil); SFX kullanılabilir. Müzik paylaşım platformunda eklenebilir.
- Kişisel e-posta / isim görünen ekranlar kullanılmaz.

## v2 — 2026-10-21: Geri sayım

Kullanıcı: "ekran görüntülerini koymak yerine daha farklı bir yaklaşım olsun, aksiyonlu hızlı bir yaklaşım olsun". Beş yön sunuldu, kullanıcı **2 — Geri Sayım**'ı seçti.

- Konsept: "Seydişehir'de her şey 10 saniyede." Ekranın üstünde kronometre 00:00 → 00:10 tıklar; her tıkta bir hizmet kendi uygulama renginde (service-grid.tsx gradyanları + MaterialIcons) çarpar. Nöbetçi Eczane ve Otobüs Saatleri 2,2 sn (iki satır), diğerleri 0,95 sn. Final: hizmetler halka olur, "BÜTÜN SEYDİŞEHİR CEBİNDE." → yeşil CTA (ikon, App Store · Google Play, Ücretsiz indir).
- Süre 20 sn, 1080×1920, müzik yok; SFX (tik, whoosh, impact, chime — bundled kütüphane).
- Ekran görüntüsü / uygulama arayüzü kullanılmaz. v1 `archive/v1-ekran-goruntulu-index.html`.
- Sahneler: `compositions/sr-hook.html` (0–2,2), `sr-run.html` (2,2–15,5), `sr-cta.html` (15,5–20).
