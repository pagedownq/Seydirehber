# Seydi Rehber — Expo uygulaması

`../seydirehberim/` içindeki canlı Flutter uygulamasının React Native + Expo karşılığı.
Hedef: **aynı görünüm, aynı davranış, aynı veri**. Yeni özellik eklemek değil, birebir taşımak. Flutter kodu her ekran için referanstır; bir ekranı yazmadan önce karşılık gelen `.dart` dosyasını oku.

## Teknoloji

- Expo SDK (create-expo-app@latest ile gelen sürüm), TypeScript strict, **Expo Router** (`src/app`).
- Paketleri her zaman `npx expo install <pkg>` ile kur. SDK'ya özgü bir API kullanmadan önce `package.json`'daki `expo` sürümünü kontrol et ve o sürümün dokümanına bak (`docs.expo.dev/versions/vXX.0.0/...`).
- Firebase native SDK kullandığı için uygulama **Expo Go'da çalışmaz** → development build (`expo-dev-client`, `eas build --profile development`).
- `ios/` ve `android/` klasörleri commit edilmez (CNG / prebuild). Native ayarlar `app.config.ts` + config plugin ile yapılır.
- **Native paketlerin hepsi baştan kuruldu** (dev build bir kez alınsın diye). Yeni native paket eklemek yeni dev build demek; JS-only paketler serbest.
- EAS arşivi monorepo kökünden alınır; kökteki `.easignore` sadece `seydirehber_expo/`'yu gönderir ve .gitignore'ların yerine geçer (gizli dosya kuralları orada da olmalı).
- Dev build profilleri: `development` (Android APK, internal), `development-testflight` (iOS, TestFlight). TestFlight build'i iOS buildNumber'ı tüketir; bir sonraki iOS build'den önce `BUILD_NUMBER` artırılmalı.

## Klasör yapısı

```
seydirehber_expo/
├── assets/                 # Flutter assets/ birebir kopya (görseller, animations/*.json)
├── src/
│   ├── app/                # SADECE route dosyaları
│   │   ├── _layout.tsx     # provider'lar, font yükleme, onboarding yönlendirmesi
│   │   ├── onboarding.tsx
│   │   ├── (tabs)/         # Ana Sayfa (index), Haberler (news), Ayarlar (settings)
│   │   ├── events/  places/  companies/  coupons/  forum/   # [id].tsx detaylar
│   │   ├── pharmacy.tsx noterler.tsx pazarlar.tsx otobus.tsx weather.tsx vefat.tsx
│   │   ├── search.tsx favorites.tsx support.tsx policies.tsx notifications.tsx seydi-map.tsx
│   │   └── admin/
│   ├── screens/            # ekran gövdeleri (route dosyası sadece bunu render eder)
│   ├── components/         # paylaşılan UI (Flutter lib/core/widgets karşılığı)
│   ├── features/           # özellik bazlı veri katmanı: hooks + types (auth, forum, reviews, news, vefat...)
│   ├── services/           # firebase.ts, supabase.ts, notifications.ts, storage.ts, analytics.ts, haptics.ts
│   ├── utils/              # profanity-filter.ts, map.ts, date.ts ...
│   └── theme.ts            # renkler, tipografi, radius, gölge — tek kaynak
├── app.config.ts
└── eas.json
```

Dosya adları kebab-case. `StyleSheet.create` dosyanın en altında. Import alias `@/` → `src/`.

### Route eşlemesi (go_router → Expo Router)

Flutter `lib/core/router/app_router.dart` içindeki tüm path'ler **aynı kalır** — bildirim payload'ları (`data.screen`) ve günlük bildirim şablonları bu path'leri kullanıyor (`/pharmacy`, `/pazarlar`, `/coupons`, `/events`, `/places`, `/companies/popular`, `/companies/latest`, `/news`, `/settings`...). `/`, `/news`, `/settings` sekme geçişi, diğerleri stack push'tur.

## Tasarım (bkz. `lib/core/constants/app_colors.dart`, `app_theme.dart`)

- Font: **Poppins** (`@expo-google-fonts/poppins`, 400/500/600/700). Flutter'daki `assets/fonts/Nickainley.otf` aslında bir GitHub 404 HTML sayfası ve hiç kullanılmıyor; taşınmadı.
- Renkler: primary `#4CAF50`, primaryLight `#81C784`, primaryDark `#388E3C`, primarySurface `#E8F5E9`, background `#F5F9F6`, textPrimary `#1B1B1B`, textSecondary `#6B6B6B`, textLight `#9E9E9E`, border `#E0E0E0`, error `#E53935`. Gradyanlar: primary `#66BB6A→#43A047`, weather `#2196F3→#00BCD4` (`expo-linear-gradient`).
- Kart radius 16, buton/input radius 12. Sadece açık tema.
- Renk/font/ölçü hardcode edilmez; hepsi `src/theme.ts`'den gelir.
- Ekran görüntüleriyle karşılaştır: `C:\Users\MEHMET\Desktop\seydirehberekranfotolari\`.

## Flutter paketi → Expo karşılığı

| Flutter | Expo / RN |
|---|---|
| firebase_core/auth/firestore/messaging/analytics | `@react-native-firebase/{app,auth,firestore,messaging,analytics}` **26.4.0'a sabit** (v27 Firebase Android 35 → Kotlin 2.4 istiyor, Expo SDK 58 Kotlin 2.2; Expo Kotlin 2.4'e geçmeden yükseltme). iOS SPM → `expo-build-properties` `useFrameworks: "dynamic"` |
| supabase_flutter (sadece storage) | `@supabase/supabase-js` |
| flutter_riverpod | Firestore akışları: `src/features/firestore/live-query.ts` (`createLiveQuery` / `deriveLiveQuery`: sorgu başına tek paylaşılan `onSnapshot`, Riverpod gibi canlı kalır; alan okuma yardımcıları `src/utils/firestore-values.ts`). HTTP (RSS, vefat) için `@tanstack/react-query`; yerel durum için `zustand` |
| CustomPaint (dekoratif desenler) | `src/components/pattern-canvas.tsx` (View tabanlı; react-native-svg native modül olduğu için eklenmedi) |
| go_router | `expo-router` |
| cached_network_image | `expo-image` |
| shimmer | Reanimated ile skeleton bileşeni |
| google_fonts | `@expo-google-fonts/poppins` + `expo-font` |
| webview_flutter | `react-native-webview` |
| url_launcher | `expo-linking` / `Linking` (tel:, mailto:, harita), `expo-web-browser` |
| share_plus | RN `Share` |
| shared_preferences | `@react-native-async-storage/async-storage` (bkz. veri göçü) |
| in_app_review | `expo-store-review` |
| http + html + xml2json | `fetch` + `fast-xml-parser` (RSS), `node-html-parser` (vefat tablosu) |
| flutter_map + marker_cluster | `@maplibre/maplibre-react-native` (raster kaynak: Esri açık gri + etiket / Esri uydu / OSM; Flutter'daki CARTO light_all 2026-10 itibarıyla API anahtarı istiyor, değiştirildi). API anahtarı gerekmez; react-native-maps Android'de Google Maps anahtarı istediği için seçilmedi |
| geolocator / location / geocoding | `expo-location` |
| google_sign_in | `@react-native-google-signin/google-signin` |
| sign_in_with_apple + crypto | `expo-apple-authentication` + `expo-crypto` (nonce) |
| image_picker | `expo-image-picker` |
| font_awesome_flutter / Material Icons | `@expo/vector-icons` |
| package_info_plus | `expo-application` |
| flutter_local_notifications + timezone | `expo-notifications` (haftalık tetikleyici) |
| permission_handler | her modülün kendi izin API'si |
| lottie | `lottie-react-native` |
| flutter_staggered_grid_view | `@shopify/flash-list` (masonry) |
| HapticFeedback | `expo-haptics` (ayardaki `haptics_enabled` anahtarına bağlı) |
| intl (tr_TR) | `Intl` / `date-fns` + `tr` locale |
| in_app_update | Android: `sp-react-native-in-app-updates` (opsiyonel, sona bırakılabilir) |
| flutter_dotenv + googleapis_auth | **Kaldırılır** — bkz. güvenlik |

## Firestore koleksiyonları (şema değişmez)

İçerik (herkes okur, admin yazar): `banners`, `etkinlikler`, `noterler`, `pazarlar`, `otobus_saatleri`, `gezilecek_yerler`, `firmalar` (kullanıcı sadece `goruntulenme` artırabilir), `surveys`, `duyurular`, `coupons` (kullanıcı sadece `used_count`), `esnaf_users`.
Kullanıcı: `reviews` (targetId, targetType, userId, userName, userImageUrl, rating, comment, createdAt, isEdited), `sikayetler`, `yardim_destek`, `generated_codes`, `forum_posts`, `forum_replies` (snake_case alanlar), `traffic_reports`, `user_tokens` (doc id = FCM token), `user_presence` (doc id = uid), `admins` (doc id = e-posta).

Dikkat edilecek davranışlar (Flutter'dan birebir alınmalı):
- Sıralama çoğu listede istemci tarafında: `order` alanı (yoksa 999999) sonra `ad` / `guzergah`.
- Etkinlikler `baslangic_tarihi_str`'ye göre sıralanır; süresi geçenler gizlenir (admin ise silinir + Supabase görseli silinir) — `home_providers.dart`.
- Firma görüntülenme: cihaz başına bir kez (`is_viewed_<id>` anahtarı) `FieldValue.increment(1)`.
- Yorumlar eklenince/silinince hedef dokümandaki ortalama/sayı (`yorum_sayisi`) güncellenir — `review_service.dart`.
- Küfür filtresi: `lib/core/utils/profanity_filter.dart` aynen taşınır.
- Admin kontrolü: sabit liste (`mehmetirem305@gmail.com`, `bilgimgverse@gmail.com`, `seydirehber@gmail.com`) + `admins/{email}` (isActive + `canManage*` izinleri).
- Firestore offline persistence açık (RNFirebase'de varsayılan açık).

Supabase Storage bucket'ları: `banner`, `etkinlikler`, `noter`, `pazar`, `gezilcek_yerler` (yazım hatası gerçek bucket adı, düzeltme), `firmalar`.

Dış veri: RSS `https://seydisehirhaber.com/rss.xml`, vefat `https://www.seydisehir.bel.tr/vefatedenler` (HTML tablo), eczane WebView `https://enyakineczane.com.tr/iframe/?city=42&district=1617&zoom=1`, hava durumu WebView (wo-cloud URL'si `weather_screen.dart`'ta).

## Bildirimler

- FCM topic'leri: `all` (genel, varsayılan açık), `vefat_notif` (varsayılan açık). Ayarlardaki anahtarlar abone olur/çıkar.
- Token `user_tokens/{token}` dokümanına yazılır (`token, userId, platform, isEnabled, lastUpdated, lastSeen`); eski token silinir — `notification_service.dart`.
- Ön planda gelen mesaj yerel bildirim olarak gösterilir; `data.screen` tıklanınca o route'a gider (uygulama kapalıyken açıldıysa da).
- Android kanal id `seydirehberim_notifications`, küçük ikon `ic_stat_s` (Flutter `android/app/src/main/res/drawable*`'dan alınır).
- Haftalık yerel bildirimler (Europe/Istanbul): Pzt 09:30, Per 10:00, Cum 18:00, Paz 13:00 — şablonlar `daily_notification_service.dart`. `expo-notifications` haftalık tetikleyicide `weekday` **1 = Pazar**; Dart'ta 1 = Pazartesi. Karıştırma.

## Güvenlik (taşımada düzeltilecek)

- Flutter uygulaması `.env`'i asset olarak paketliyor ve içinde **Firebase service account private key** var (admin bildirim ekranları FCM v1'e istemciden yolluyor).
  **Kullanıcı kararı (Adım 15, 2026-10-20):** riskler anlatıldıktan sonra kullanıcı "anahtar uygulamada olsun" dedi — Expo da Flutter gibi istemciden gönderir. Değerler `.env`'de `EXPO_PUBLIC_FCM_PROJECT_ID`, `EXPO_PUBLIC_FCM_CLIENT_EMAIL`, `EXPO_PUBLIC_FCM_PRIVATE_KEY` (Flutter `.env` ile aynı; build'e gömülür, EAS env'e de eklenmeli). Gönderim kodu tek yerde: `src/features/admin/fcm-sender.ts` — ileride sunucuya taşınacaksa sadece orası değişir. Anahtar zaten sızmış sayılmalı (web panelinde de `VITE_FIREBASE_PRIVATE_KEY` olarak tarayıcı paketine giriyor); rotasyonu kullanıcıya hatırlat.
- `.env` içinde: `EXPO_PUBLIC_SUPABASE_URL`, `EXPO_PUBLIC_SUPABASE_ANON_KEY`, `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` (google-services.json'daki client_type 3; Android Google girişi için). Preview/production build'den önce EAS env'e de eklenmeli.
- Flutter'daki EmailJS hoş geldin e-postası (`auth-actions.ts`) istemcide EmailJS private access token'ı taşıyor — canlı sürümde de böyle; ileride sunucuya taşınmalı. Supabase anon key ve Firebase istemci config'i public olabilir; yine de `app.config.ts` / `EXPO_PUBLIC_*` üzerinden okunur, kaynak koda dağıtılmaz.
- `google-services.json` / `GoogleService-Info.plist` gitignore'da; EAS'e file env variable olarak verilir.

## Mevcut kullanıcı verisinin göçü (canlı uygulama!)

Mağazadan güncelleme alan kullanıcı Flutter'dan Expo'ya geçecek:
- **Firebase Auth oturumu:** iki taraf da native Firebase SDK kullanıyor, aynı bundle id ile oturumun korunması beklenir — gerçek cihazda doğrulanmalı.
- **shared_preferences** verisi AsyncStorage'dan okunamaz; yerel native modül `modules/flutter-prefs` (`getFlutterPrefs()`) okur (Android liste/double önekleri Kotlin'de çözülür). Flutter Android'de `FlutterSharedPreferences` dosyasında, iOS'ta `NSUserDefaults`'ta `flutter.` önekiyle tutar. İlk açılışta bir kerelik göç gerekir. Taşınacak anahtarlar: `onboarding_completed`, `favorites_list`, `blocked_user_details_json`, `blocked_user_uids`, `search_history`, `forum_rules_accepted`, `notifications_enabled`, `vefat_notifications_enabled`, `daily_notif_enabled`, `haptics_enabled`, `installationDate`, `last_registered_fcm_token`, `is_viewed_*`, `survey_completed_*`. (`*_cache` ve `weekly_notif_scheduled_v2` taşınmaz.) Göç: `src/services/legacy-prefs-migration.ts`, AsyncStorage erişimi: `src/services/storage.ts` (değerler JSON).

## Yayın

- `app.config.ts`: name "Seydi Rehber", Android package / iOS bundle `com.mgverse.seydirehberim`, version > `1.0.10`, Android versionCode > `32`, iOS buildNumber mevcut App Store build'inden büyük.
- Android aynı upload key ile imzalanmalı (`seydirehberim/android/key.properties` → EAS credentials). Yanlış anahtarla Play güncellemeyi reddeder.
- Mağaza linkleri: `lib/core/constants/app_constants.dart`.

## Çalışma şekli

- Taşıma `## Taşıma planı`ndaki sırayla, adım adım yapılır; her adım sonunda kullanıcı onaylar. Bir sonraki adıma kendiliğinden geçme.
- Bir ekranı taşırken: ilgili `.dart` dosyalarını oku → ekran görüntüsüyle karşılaştır → aynı metinler (Türkçe), aynı boş durum mesajları, aynı hata mesajları.
- Flutter'daki hata/eksik davranışı fark edersen sessizce "düzeltme"; not al ve kullanıcıya söyle.
- Tamamlanan adımı aşağıdaki listede `[x]` yap.

## Taşıma planı

- [x] 1. Proje iskeleti: create-expo-app, TypeScript, Expo Router, `src/` yapısı, theme, fontlar, assets kopyası, `app.config.ts` (bundle id'ler), EAS + dev build
- [x] 2. Firebase (RNFirebase) + Supabase bağlantısı, AsyncStorage, shared_preferences göç modülü
- [x] 3. Ortak bileşenler: kart, shimmer/skeleton, cached image, "Tümünü Gör", paylaş, harita butonu, boş durum, hata görünümü, onay dialog'u
- [x] 4. Auth + Onboarding (Google, Apple, misafir/anonim, isim isteme dialog'u)
- [x] 5. Tab yapısı + Ana Sayfa (hava/paylaş kartları, arama, banner slider, etkinlik/kupon/yer/firma yatay listeleri, Hizmetler grid'i)
- [x] 6. Liste + detay ekranları: etkinlik, gezilecek yer, firma (görüntülenme), favoriler, arama
- [x] 7. Yorumlar / değerlendirme / şikayet
- [x] 8. Hizmetler: eczane, noterler, pazarlar, otobüs saatleri, hava durumu, vefat
- [x] 9. Haberler (RSS) — Flutter'daki haber saatinin 3 saat geri kayması (`parseRfc822Date`) bilerek korundu; kullanıcı karar verecek
- [x] 10. Kuponlar (kod üretme, `generated_codes`)
- [x] 11. Forum (liste, detay, oluştur, düzenle, raporla, kurallar, gönderilerim, engelleme) — Flutter tuhaflıkları aynen korundu: bildirme nedeni kaydedilmiyor, kullanıcı kendi gönderisini silince yanıtlar kalıyor, arama/kategori filtresi global, detayda kategori çipi ham değer gösteriyor
- [x] 12. Seydi Harita + yol durum bildirimleri (`traffic_reports`) — kümeleme JS'te (`features/map/marker-clusters.ts`), işaretçiler RN view. Flutter'da "Anlık Durum Bildirimleri" bölümü yorum satırında (canlıda yok) → `features/reports/` hazır ama Ana Sayfa'ya eklenmedi; `traffic_reports` kuralı da Flutter'da commit edilmemiş, yayında olup olmadığı doğrulanmalı. Kullanıcı konum noktası Flutter'daki gibi ~30 px yukarıda (alignment topCenter) bilerek korundu
- [x] 13. Ayarlar, destek formu, politikalar, anket, uygulamayı değerlendir — bildirim anahtarları şimdilik sadece ayarı kaydediyor (`services/notification-settings.ts`); topic/token/haftalık planlama Adım 14'te aynı fonksiyonlara eklenecek. Anahtarlar Flutter'daki gibi Material 3 görünümlü (`components/material-switch.tsx`)
- [x] 14. Bildirimler (FCM + topic'ler + haftalık yerel bildirimler + deep link) — `services/notifications.ts`. FCM: RNFirebase (Android'de FCM mesajlarını RNFB servisi alır, expo'nunki priority -1; iOS'ta iki kütüphane UNUserNotificationCenter delegate'ini zincirliyor). Ön planda uzak bildirim expo handler'da gizlenip onMessage ile yerel bildirim olarak gösterilir (Flutter gibi). Dokunma: uzak → RNFB, yerel → expo; aynı yol 2 sn içinde bir kez açılır. Haftalık bildirim kimlikleri Flutter'la aynı (9101–9104): iOS'ta Flutter'dan kalan planlı bildirimlerin yerine geçer. Saatler cihaz saatine göre (Flutter Europe/Istanbul sabitliyordu)
- [x] 15. Admin paneli (CRUD + Supabase upload/silme, destek, yorumlar, şikayetler, forum moderasyonu, bildirim gönderimi) — kullanıcı kararıyla bildirim Flutter gibi istemciden (`features/admin/fcm-sender.ts`, jsrsasign ile RS256). Sıralama: `react-native-reorderable-list` (JS). Görseller `expo-image-picker` quality 0.7 (Flutter'daki maxWidth 1000 küçültmesi yok — image-manipulator native modül). Flutter tuhaflıkları korundu (`canManageForum` anahtarı 2026-10-21 kullanıcı isteğiyle eklendi), yeni kayıtta firma kategorisi kaydedilmiyor, firma seçicide arama süzmüyor, destek bildirimi başarısız olsa da "gönderildi" deniyor, `created_at`'i olmayan belgeler listede görünmüyor
- [ ] 16. Analytics, uygulama içi güncelleme, son görsel karşılaştırma, mağaza build'i ve gönderimi — analytics (`useScreenTracking` root layout'ta, ekran adı yol kalıbı `/events/:id`; açılışta `setUserId`) ve Android uygulama içi güncelleme (`services/update.ts`, versionCode karşılaştırması, sekmeler açılınca) yazıldı. Kullanıcı kararı (2026-10-21): mağaza build'i UI düzenlemelerinden sonra.

## Taşıma sonrası eklenen / değişenler (Flutter'da yok)

Kullanıcı isteğiyle birebirlikten ayrılan yerler; kodda yanlarında not var.
- **İş İlanları** (2026-10-21): koleksiyon `is_ilanlari` (baslik, firma_adi, company_id, calisma_sekli, aciklama, calisma_saatleri, ucret, telefon, whatsapp, adres, konum, bitis_tarihi, aktif, created_at). Sadece admin yazar (yetki `canManageJobs`; uygulama admin panelinde ve `seydirehber_web` admin panelinde "İş İlanı Yönetimi"), herkes okur; kural `seydirehberim/firestore.rules`'ta, 2026-10-21'de deploy edildi. Bitiş tarihi boşsa `created_at` + 30 gün sonra listeden düşer (istemcide, `features/jobs/jobs.ts`). Başvuru telefon / WhatsApp (wa.me). Rotalar `/is-ilanlari`, `/is-ilanlari/[id]`; Hizmetler ızgarasında tam genişlik 9. kart.
- Yeniden tasarlanan ekranlar: Otobüs Saatleri, Halk Pazarları (`pazarlar-screen.tsx`). Favoriler kart arası boşluk. Seydi Harita: aynı konumdaki küme tek dokunuşta açılır.

## Transfer sonrası (2026-10-21)

Uygulama eski Apple ekibinden (`8U3576L9TA`) kullanıcının ekibine (`9AQZMN87BD`) transfer edildi. Firebase'deki APNs anahtarı yeni ekibin `ZC933J3U5D` anahtarıyla değiştirildi (dev + prod), iOS uygulamasının Team ID'si güncellendi; test bildirimi (mağazadaki Flutter sürümüyle; 2026-10-21'de Expo dev build'de de çalıştığı doğrulandı) ve Apple ile Giriş (transfer öncesi kullanıcılar aynı hesaba düşüyor) doğrulandı. Expo Push kullanılmıyor — EAS build push key sorarsa atla (APNs anahtar sınırı 2). Firebase Apple sağlayıcısının OAuth kod akışı alanları hâlâ eski ekibin anahtarı (`Y8J4RN6574`); iOS yerel girişte kullanılmıyor, temizlenebilir.
