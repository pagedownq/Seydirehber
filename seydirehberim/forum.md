# 📌 Seydirehber - Forum Modülü Spesifikasyon Dökümanı

Bu döküman, Seydirehber uygulaması içerisine eklenecek olan "Topluluk Destekli Soru-Cevap & Forum" modülünün UI/UX, Frontend ve Backend mantığını içermektedir.

---

## 1. UI / UX ve Yerleşim Değişiklikleri

### Hizmetler Ekranı Güncellemesi
*   **Mevcut Durum:** Hizmetler bölümünde yatay/uzun bir "Haberler" butonu yer almaktadır.
*   **Yeni Tasarım:** "Haberler" butonu genişliği yarıya indirilerek **sağ tarafına** aynı boyutlarda, iOS stilinde (temiz, minimalist, hafif yuvarlatılmış köşeli ve gölgeli) bir **"Forum"** butonu eklenecektir.

### Giriş ve 18+ Yaş / Topluluk Kuralları Onay Ekranı (Gatekeeper)
Kullanıcı Forum butonuna ilk kez tıkladığında (veya session yenilendiğinde) karşısına tam ekran bir bilgilendirme ve onay penceresi gelir. Bu onay verilmeden forum içerikleri listelenmez.

*   **Başlık:** Seydirehber Forum'a Hoş Geldiniz!
*   **İçerik Metni:** 
    > "Bu alanda paylaşılan içeriklerden kullanıcıların kendileri sorumludur. Forumu kullanabilmek için 18 yaşından büyük olmanız ve topluluk kurallarına uymayı kabul etmeniz gerekmektedir. Küfür, hakaret, kişisel verilerin ifşası (KVKK ihlali) ve spam paylaşım yapmak kesinlikle yasaktır ve hesap kısıtlamasına yol açar."
*   **Aksiyon:** `[x] 18 yaşından büyüğüm ve topluluk kurallarını kabul ediyorum.` (Checkbox) -> **[ Foruma Giriş Yap ]** (Buton - Pasiften aktife döner).

---

## 2. Gönderi Paylaşma ve Gizlilik Mantığı (Anonimlik)

Kullanıcı bir soru sorarken veya bir gönderiye yanıt yazarken, Auth (Giriş) bilgilerine bağlı olarak iki farklı yayınlama modundan birini seçer:

1.  **Açık Profil Modu:** Kullanıcının kayıtlı ismi, profil fotoğrafı ve (isteğe bağlı) unvanı gönderide açıkça listelenir.
2.  **Anonim Modu:** Gönderide isim yerine **"Anonim Kullanıcı"** yazar, profil fotoğrafı varsayılan bir avatar olur.

### 👤 Admin Paneli Görünümü (Veri Güvenliği)
*   **Kullanıcı Arayüzü:** Normal kullanıcılar anonim mesajları sadece "Anonim Kullanıcı" olarak görür.
*   **Yönetici/Admin Arayüzü:** Yönetici panelinde veya admin yetkisine sahip bir hesap foruma baktığında, anonim gönderilerin yanında parantez içinde veya özel bir etiketle gerçek kullanıcının bilgileri gösterilir: 
    *   *Örn:* `Anonim Kullanıcı (Mehmet Gülhan - mehmet@email.com)`

---

## 3. Topluluk Destekli Denetim & Raporlama Sistemi

Her sorunun ve yanıtın sağ üst köşesinde bir üç nokta `...` veya `Bayrak (Report)` butonu yer alır.

### A. Raporlama Kategori Seçimi (Bottom Sheet / Pop-up)
Kullanıcı bildir butonuna bastığında aşağıdaki kategorilerden birini seçmek zorundadır:
*   ❌ Hakaret / Argo / Küfür
*   📌 Yanlış / Yanıltıcı Bilgi
*   📢 Reklam / Spam
*   👤 Kişisel Verilerin İfşası (İsim, Telefon paylaşımı vb.)

### B. Otomatik Eşik Değeri (Threshold) Kuralı ve Algoritma
Bir gönderi veya yorum şikayet edildiğinde sistem arka planda şu mantıkla çalışır:

*   **Rapor Sayısı < 3:** İçerik yayında kalmaya devam eder, admin panelindeki inceleme kuyruğuna "Düşük Öncelikli" olarak eklenir.
*   **Rapor Sayısı ≥ 3:** İçerik sistem tarafından **otomatik olarak gizlenir** (Veritabanından silinmez, `is_hidden: true` durumuna alınır).
*   **Kullanıcı Arayüzü Değişimi:** Gizlenen içeriğin yerinde hem soruyu soran hem de diğer tüm kullanıcılar için şu statik metin gösterilir:
    > ⚠️ *"Bu içerik topluluk kuralları ihlali şikayetleri nedeniyle geçici olarak incelemeye alınmıştır."*
*   **Admin Aksiyonu:** Admin içeriği inceler; eğer ihlal yoksa "Onayla" diyerek içeriği tekrar görünür yapar (`is_hidden: false`). Eğer ihlal varsa kalıcı olarak siler ve yazan kullanıcıya otomatik ceza puanı uygular.

---

## 4. Örnek Veritabanı Şeması (Database Schema - Supabase/Firebase için)

### `forum_posts` (Gönderiler/Sorular Tablosu)
```json
{
  "id": "uuid",
  "user_id": "uuid (Foreign Key to Auth)",
  "title": "string",
  "content": "text",
  "is_anonymous": "boolean (default: false)",
  "report_count": "integer (default: 0)",
  "is_hidden": "boolean (default: false)",
  "created_at": "timestamp"
}


 anaysafadaki hizmetler bölümündeki haberler ve forum butonları yanyana ve  bu haberler butonunn içindeki metin tam gözükmüyor  forum butonundan dolayıu fontu büyük sanırım onun  onu düzelt + olarak  foruma ilk defa girerken foruma giriş yap dialog yerinde yukarıdan alta sürükleyince o dialogu kapatma olmuyor  onu ayarla 
 W/Firestore(21673): (25.1.4) [Firestore]: Listen for Query(target=Query(forum_posts where is_hidden==false order by -created_at, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
 hatası var bide W/Firestore(21673): (25.1.4) [Firestore]: Listen for Query(target=Query(forum_posts where is_hidden==false order by -created_at, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=FAILED_PRECONDITION, description=The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/seydirehber1/firestore/indexes?create_composite=ClBwcm9qZWN0cy9zZXlkaXJlaGJlcjEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2ZvcnVtX3Bvc3RzL2luZGV4ZXMvXxABGg0KCWlzX2hpZGRlbhABGg4KCmNyZWF0ZWRfYXQQAhoMCghfX25hbWVfXxAC, cause=null}
 var bunları çöz 
