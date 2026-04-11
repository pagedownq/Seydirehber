# Proje Gereksinim Belgesi (PRD) - Seydi Rehber

## Vizyon ve Hedef
Seydi Rehber, Seydişehir (Konya) ve çevresindeki yerel dinamikleri (nöbetçi eczaneler, pazarlar, otobüs saatleri, etkinlikler ve firmalar) tek bir çatı altında toplayan, Android platformuna özel, modern ve yüksek performanslı bir rehber uygulamasıdır.
 
---
uygulama teması genellikle açık yeşil ve beyaz olcak 
## ADIM 1: Proje Başlangıcı ve Temel Kurulum
* **1.1. Proje Oluşturma:** Terminal üzerinden sadece Android platformunu hedefleyen Flutter projesi başlatılacak.
    * `flutter create --platforms=android --org com.mgverse seydirehberim`
* **1.2. İkon Ayarı:** `assets/` klasörü oluşturulup `SeydiRehber.png` eklenecek ve uygulamanın ana simgesi yapılacak.
* **1.3. Paketlerin Eklenmesi (`pubspec.yaml`):**
    * *Backend:* `firebase_core`, `firebase_auth`, `cloud_firestore`, `supabase_flutter`
    * *State & Routing:* `flutter_riverpod`, `go_router`
    * *UI/UX:* `cached_network_image`, `shimmer`, `smooth_page_indicator`, `google_fonts`
    * *Araçlar:* `webview_flutter`, `url_launcher`, `share_plus`, `shared_preferences`, `in_app_review`, `http`, `xml2json`

## ADIM 2: Firebase ve Supabase Konfigürasyonu
* **2.1. Firebase Bağlantısı:** Proje Firebase'e eklenecek (Sadece Android). SHA-1 ve SHA-256 key'leri üretilip Firebase konsoluna girilecek.
* **2.2. Supabase Bağlantısı:** Supabase projesi oluşturulacak. URL ve Anon Key `main.dart` içerisinde initialize edilecek.
* **2.3. Veritabanı Yapılandırması:** * Supabase'de Storage Bucket'lar açılacak: `banner`, `etkinlikler`, `noter`, `pazar`, `gezilcek_yerler`, `firmalar`.
    * Supabase'de bildirimler için `fcm` tablosu oluşturulacak.

## ADIM 3: Klasör Mimarisi ve Temel Sabitler (Clean Code)
* **3.1. Klasör Ağacı Oluşturma:**
    * `lib/core/` (constants, theme, utils, ortak widget'lar)
    * `lib/features/` (auth, home, events, services, places, companies, settings, admin)
* **3.2. Sabitlerin Tanımlanması:** `app_colors.dart`, `app_assets.dart` ve `app_text_styles.dart` dosyaları `core/constants/` altına yazılacak. Hardcode metin ve renk kullanımı yasaklanacak.

## ADIM 4: Ortak Widget'ların Geliştirilmesi (UI Components)
* **4.1. Tekrar Eden Parçalar:** * Özel "Tümünü Gör" butonu.
    * "Harita Üzerinden Göster" butonu (`url_launcher` entegreli).
    * Sağ üstte yer alacak "Paylaş" butonu (`share_plus` entegreli).
    * Yüklenme durumları için gri parlama efekti (`ShimmerWidget`).
    * Ağ görselleri için hata kontrollü `CachedImageWidget`.

## ADIM 5: Kimlik Doğrulama ve Onboarding (Feature: Auth & Onboarding)
* **5.1. Onboarding Ekranları:** 3 sayfalık kaydırmalı tanıtım ekranı. 2. sayfada gizlilik politikası onayı (checkbox) zorunlu kılınacak.
* **5.2. Giriş Mantığı:**
    * "Google ile Giriş Yap" (Firebase Auth tetiklenir).
    * "Misafir Olarak Devam Et" (Firebase anonim giriş yapılmaz, yerel `User = null` mantığıyla çalışır).
* **5.3. Yönlendirme (GoRouter):** Oturum durumuna göre kullanıcıyı Onboarding'e veya Ana Sayfaya yönlendiren routing mantığı kurulacak.

## ADIM 6: Ana Sayfa Geliştirmesi (Feature: Home)
* **6.1. Appbar & Arama:** Konum ikonu, uygulama adı ve lokal filtreleme yapan aktif Arama Çubuğu (Search Bar) eklenecek.
* **6.2. Hava Durumu Modülü:** En üste, dokunmaya kapalı WebView eklenecek: `src="https://enyakineczane.com.tr/iframe/?city=42&district=1617&zoom=1"`. Yanına "Arkadaşlarınla Paylaş" butonu konulacak.
* **6.3. Slider & Haberler:** Supabase'den çekilen Banner alanı (1200x300) ve Toroslar Gazetesi RSS XML verisini çeken Haberler butonu eklenecek.
* **6.4. Hizmetler Grid (2x2):** Nöbetçi Eczane (Tıklanınca açık webview), Noterler, Halk Pazarları ve Otobüs Saatleri butonları tasarlanacak.
* **6.5. Yatay Listeler:** Etkinlikler, Gezilecek Yerler ve Firmalar için Firestore'dan son 5 veriyi çeken yatay kaydırmalı listeler kodlanacak (Göz ikonu ve sayaç firmalar kartına eklenecek).
* **6.6. Alt Navigasyon (Bottom NavBar):** Ana Sayfa, Haberler, Ayarlar sekmeleri oluşturulacak.

## ADIM 7: Detay ve Listeleme Sayfaları
* **7.1. Etkinlikler:** Kapak fotoğrafı, ad, başlama tarihi zorunlu. Bitiş tarihi ve saat (opsiyonel - null check).
* **7.2. Noterler & Pazarlar:** Fotoğraf, ad, açık olduğu günler, konum bilgisi. Noterde ekstra telefon bilgisi.
* **7.3. Otobüs Saatleri:** Güzergah ve saatler. Duraklar (opsiyonel - null check). Fotoğraf yok.
* **7.4. Gezilecek Yerler:** Fotoğraf, ad, hakkında, konum. Tarihçe (opsiyonel - null check).
* **7.5. Firmalar:** Fotoğraf/Logo, ad, iletişim, konum, hakkında. Web sitesi ve Instagram (opsiyonel - null check). Görüntülenme sayacı `shared_preferences` ile günlük tek artış sağlayacak şekilde kodlanacak.

## ADIM 8: Ayarlar ve Kullanıcı İşlemleri (Feature: Settings)
* **8.1. Profil & Hesap:** Google profil verileri gösterilecek. Çıkış Yap ve Hesabı Sil fonksiyonları bağlanacak.
* **8.2. Form & Değerlendirme:** `yardim_destek` koleksiyonuna veri yazan iletişim formu. `in_app_review` tetikleyicisi.
* **8.3. Admin Kontrolü:** Sadece `mehmetirem305@gmail.com` ile giriş yapıldığında "Yönetim Paneli" butonu aktif edilecek.

## ADIM 9: Yönetim Paneli (Feature: Admin)
* **9.1. CRUD İşlemleri:** Banner, Etkinlik, Noter, Pazar, Otobüs, Gezilecek Yerler ve Firmalar için Ekleme, Silme, Güncelleme sayfaları yapılacak.
* **9.2. Hibrit Yükleme Mantığı:** Admin önce ismi/veriyi girecek, görsel Supabase Storage'a yüklenecek, dönen URL Firestore'daki belgeye kaydedilecek.
* **9.3. Otomatik Silme Kuralı:** Panelden bir veri silindiğinde, kodsal olarak Supabase Storage'daki bağlı olduğu görsel de silinerek çöp veri oluşumu engellenecek.

## ADIM 10: Güvenlik, Test ve Kapanış
* **10.1. Firestore Rules:**
    * Okuma (Read): Herkese açık.
    * Yazma/Silme/Güncelleme: Sadece `mehmetirem305@gmail.com` (Admin).
    * `yardim_destek` Koleksiyonu: Herkes veri oluşturabilir, ancak sadece Admin okuyabilir.
* **10.2. Çevrimdışı Destek:** Firestore Offline Persistence aktif edilecek.
* **10.3. Test:** Görüntülenme sayacının spam koruması ve opsiyonel (null) alanların UI'ı bozup bozmadığı test edilecek.



supabase id:ycqrgraqmafdtvaxwuml

anon public api:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljcXJncmFxbWFmZHR2YXh3dW1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5MTI2MTgsImV4cCI6MjA4OTQ4ODYxOH0.riAGavZ3RZgUHwlxiQDp8PFmVju9qIUamOJBWS8kVWc

