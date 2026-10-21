# Seydi Rehber — Monorepo

Seydişehir (Konya) için şehir rehberi uygulaması. Mobil uygulama **App Store ve Google Play'de canlı**.
Şu anki ana iş: Flutter uygulamasını (`seydirehberim/`) **React Native + Expo**'ya (`seydirehber_expo/`) birebir taşımak.

## Klasörler

| Klasör | Ne | Durum |
|---|---|---|
| `seydirehberim/` | Canlı Flutter uygulaması (v1.0.10+32) | **Sadece referans.** Taşıma bitene kadar silme / yeniden düzenleme yok. |
| `seydirehber_expo/` | Yeni Expo (React Native) uygulaması | Aktif geliştirme. Kurallar: `seydirehber_expo/CLAUDE.md` |
| `seydirehber_web/` | **Güncel web projesi** (Vite + React + Tailwind): tanıtım/politika sayfaları + admin paneli (`src/apps/admin`) + esnaf paneli (`src/apps/esnaf`). Vercel'de yayında. **Kendi git deposu var** (`seydirehber_web/.git` → github.com/pagedownq/seydirehberwebsitesi); monorepo git'i bu klasörü görmez, commit/push o klasörde yapılır | Web panelinde değişiklik gerekirse **burada** yapılır. Admin koleksiyon alanları `src/apps/admin/types.ts` (`COLLECTIONS`), menü `Sidebar.tsx`, yetkiler `AdminApp.tsx` |
| `seydirehber_admin_web/`, `esnaf_web/` | Eski ayrı paneller | Güncel değil (kullanıcı, 2026-10-21); `seydirehber_web` kullanılır, bunlara dokunma |
| `seydirehberim/scripts/vefat_checker/` | Node betiği: belediye vefat sayfasını tarar, `vefat_notif` topic'ine FCM yollar | `.github/workflows/vefat_check.yml` ile çalışır, dokunma |
| `prd.md` | İlk ürün gereksinim belgesi (eski; kod daha güncel) | Referans |

Canlı ekran görüntüleri: `C:\Users\MEHMET\Desktop\seydirehberekranfotolari\` — görsel birebirlik için kaynak.

## Değişmeyecek şeyler (backend ortak)

Expo uygulaması, Flutter uygulamasıyla **aynı backend'i** kullanır. Taşıma sırasında:

- Firebase projesi `seydirehber1` (Auth, Firestore, FCM, Analytics). Koleksiyon adları, alan adları ve tipleri **aynen** korunur — eski sürümü kullanan kullanıcılar aynı verileri okumaya devam ediyor.
- `seydirehberim/firestore.rules` ve `firestore.indexes.json` tek doğru kaynaktır. Kural değişikliği gerekirse ayrıca konuşulur; Expo tarafında yeni sorgu index istiyorsa buraya eklenir.
- Supabase projesi `ycqrgraqmafdtvaxwuml` — sadece Storage (görseller) için.
- Mağaza kimlikleri: Android `com.mgverse.seydirehberim`, iOS bundle `com.mgverse.seydirehberim`, App Store id `6762803524`. Yeni uygulama **güncelleme** olarak yayınlanacak, yeni uygulama olarak değil.

## Gizli dosyalar

`.env`, `google-services.json`, `GoogleService-Info.plist`, `android/key.properties`, `sha_keyleri.txt`, `*-firebase-adminsdk-*.json` git'e girmez. İçeriklerini çıktıya, commit'e veya `EXPO_PUBLIC_*` değişkenlerine koyma. Tek istisna (kullanıcı kararı, 2026-10-20): admin bildirimi için FCM service account değerleri `EXPO_PUBLIC_FCM_*` olarak — bkz. `seydirehber_expo/CLAUDE.md` Güvenlik.

## Dil

Kullanıcı Türkçe konuşuyor; açıklamalar Türkçe. Kod tanımlayıcıları İngilizce, kullanıcıya görünen metinler Türkçe.
