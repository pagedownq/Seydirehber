export interface AdminCard {
  icon: string;
  title: string;
  color: string;
  collection: string;
  bucket: string | null;
}

export interface FieldConfig {
  key: string;
  label: string;
  required?: boolean;
  multiline?: boolean;
  isNumber?: boolean;
  isDate?: boolean;
  isTime?: boolean;
  isPhone?: boolean;
  isCompanyPicker?: boolean;
  isTimeList?: boolean;
  isBoolean?: boolean;
}

export const COLLECTIONS: Record<string, { title: string; bucket: string | null; fields: FieldConfig[] }> = {
  banners: {
    title: 'Banner Yönetimi',
    bucket: 'banner',
    fields: [
      { key: 'ad', label: 'Banner Adı', required: true },
      { key: 'url', label: 'Banner Linki (Opsiyonel)' },
      { key: 'company_id', label: 'Uygulama İçi Firma Linki', isCompanyPicker: true },
      { key: 'order', label: 'Sıra (0, 1, 2...)', isNumber: true },
      { key: 'aktif', label: 'Aktif mi?', isBoolean: true },
    ],
  },
  etkinlikler: {
    title: 'Etkinlik Yönetimi',
    bucket: 'etkinlikler',
    fields: [
      { key: 'ad', label: 'Etkinlik Adı', required: true },
      { key: 'hakkinda', label: 'Hakkında', multiline: true },
      { key: 'baslangic_tarihi_str', label: 'Başlangıç Tarihi', isDate: true, required: true },
      { key: 'bitis_tarihi_str', label: 'Bitiş Tarihi', isDate: true },
      { key: 'saat', label: 'Saat', isTime: true },
      { key: 'adres', label: 'Görünecek Adres (Örn: Örnek Cad. No:5)', required: true },
      { key: 'konum', label: 'Harita Konumu (Link, Koordinat veya DMS)' },
    ],
  },
  noterler: {
    title: 'Noter Yönetimi',
    bucket: 'noter',
    fields: [
      { key: 'ad', label: 'Noter Adı', required: true },
      { key: 'gunler', label: 'Açık Günler' },
      { key: 'telefon', label: 'Telefon', isPhone: true },
      { key: 'adres', label: 'Görünecek Adres (Örn: Side Mah. No:1)', required: true },
      { key: 'konum', label: 'Harita Konumu (Link, Koordinat veya DMS)' },
    ],
  },
  pazarlar: {
    title: 'Pazar Yönetimi',
    bucket: 'pazar',
    fields: [
      { key: 'ad', label: 'Pazar Adı', required: true },
      { key: 'gunler', label: 'Açık Günler' },
      { key: 'adres', label: 'Görünecek Adres (Örn: Sanayi Yanı)', required: true },
      { key: 'konum', label: 'Harita Konumu (Link, Koordinat veya DMS)' },
    ],
  },
  otobus_saatleri: {
    title: 'Otobüs Saatleri Yönetimi',
    bucket: null,
    fields: [
      { key: 'guzergah', label: 'Güzergah', required: true },
      { key: 'saatler', label: 'Sefer Saatleri (Saat Ekle Butonu)', isTimeList: true, required: true },
      { key: 'duraklar', label: 'Duraklar (Opsiyonel)', multiline: true },
    ],
  },
  gezilecek_yerler: {
    title: 'Gezilecek Yerler',
    bucket: 'gezilcek_yerler',
    fields: [
      { key: 'ad', label: 'Yer Adı', required: true },
      { key: 'hakkinda', label: 'Hakkında', multiline: true },
      { key: 'tarihce', label: 'Tarihçe', multiline: true },
      { key: 'adres', label: 'Görünecek Adres', required: true },
      { key: 'konum', label: 'Harita Konumu (Link, Koordinat veya DMS)' },
      { key: 'order', label: 'Sıra (Görünüm Sırası)', isNumber: true },
    ],
  },
  firmalar: {
    title: 'Firma Yönetimi',
    bucket: 'firmalar',
    fields: [
      { key: 'ad', label: 'Firma Adı', required: true },
      { key: 'kategori', label: 'Kategori (Örn: Restoran, Kafe, Market)' },
      { key: 'yetkili_kisi', label: 'Yetkili Kişi' },
      { key: 'hakkinda', label: 'Hakkında', multiline: true },
      { key: 'iletisim', label: 'İletişim (Telefon)', isPhone: true },
      { key: 'adres', label: 'Görünecek Adres', required: true },
      { key: 'konum', label: 'Harita Konumu (Link, Koordinat veya DMS)' },
      { key: 'website', label: 'Web Sitesi' },
      { key: 'instagram', label: 'Instagram (Kullanıcı adı veya Link)' },
      { key: 'menu_url', label: 'Menü Linki (Kafe/Restoranlar için Opsiyonel)' },
      { key: 'expiry_date', label: 'Bitiş Tarihi (Sona Erme)', isDate: true },
      { key: 'order', label: 'Sıra (Görünüm Sırası)', isNumber: true },
    ],
  },
  yardim_destek: {
    title: 'Yardım ve Destek',
    bucket: null,
    fields: [
      { key: 'ad_soyad', label: 'Ad Soyad', required: true },
      { key: 'email', label: 'E-posta' },
      { key: 'telefon', label: 'Telefon', isPhone: true },
      { key: 'kategori', label: 'Kategori' },
      { key: 'mesaj', label: 'Mesaj', multiline: true, required: true },
      { key: 'durum', label: 'Durum (Bekliyor/Çözüldü)' },
      { key: 'tarih', label: 'Tarih', isDate: true },
    ]
  },
  reviews: {
    title: 'Yorum Yönetimi',
    bucket: null,
    fields: [
      { key: 'userName', label: 'Kullanıcı Adı', required: true },
      { key: 'rating', label: 'Puan', isNumber: true, required: true },
      { key: 'comment', label: 'Yorum', multiline: true, required: true },
      { key: 'targetId', label: 'Hedef ID (Firma/Yer)', required: true },
      { key: 'createdAt', label: 'Tarih', isDate: true },
    ]
  },
  esnaf_users: {
    title: 'Esnaf Hesapları',
    bucket: null,
    fields: [
      { key: 'username', label: 'E-posta (Esnaf Girişi İçin)', required: true },
      { key: 'password', label: 'Şifre', required: true },
      { key: 'companyId', label: 'İlişkili Firma', isCompanyPicker: true, required: true },
      { key: 'companyName', label: 'Firma Adı', required: true },
    ]
  },
  coupons: {
    title: 'Kupon Yönetimi',
    bucket: null,
    fields: [
      { key: 'title', label: 'Kupon Adı', required: true },
      { key: 'description', label: 'Kupon Hakkında', multiline: true },
      { key: 'discountPercentage', label: 'İndirim Yüzdesi (Örn: 20)', isNumber: true, required: true },
      { key: 'companyId', label: 'Geçerli Firma', isCompanyPicker: true, required: true },
      { key: 'companyName', label: 'Firma Adı (Gösterim İçin)', required: true },
      { key: 'expiry_date', label: 'Bitiş Tarihi (Opsiyonel)', isDate: true },
      { key: 'total_limit', label: 'Kupon Sayısı (Sınır - Opsiyonel)', isNumber: true },
      { key: 'isActive', label: 'Aktif Mi?', isBoolean: true },
    ]
  },
  admins: {
    title: 'Admin Yönetimi',
    bucket: null,
    fields: [
      { key: 'email', label: 'Admin Email', required: true },
      { key: 'ad_soyad', label: 'Ad Soyad', required: true },
      { key: 'isActive', label: 'Aktif Mi?', isBoolean: true },
      { key: 'canManageBanners', label: 'Banner Yönetimi', isBoolean: true },
      { key: 'canManageEvents', label: 'Etkinlik Yönetimi', isBoolean: true },
      { key: 'canManageNotaries', label: 'Noter Yönetimi', isBoolean: true },
      { key: 'canManageMarkets', label: 'Pazar Yönetimi', isBoolean: true },
      { key: 'canManageBuses', label: 'Ulaşım Yönetimi', isBoolean: true },
      { key: 'canManagePlaces', label: 'Mekan Yönetimi', isBoolean: true },
      { key: 'canManageCompanies', label: 'Firma Yönetimi', isBoolean: true },
      { key: 'canManageSupport', label: 'Destek Yönetimi', isBoolean: true },
      { key: 'canManageReviews', label: 'Yorum Yönetimi', isBoolean: true },
      { key: 'canManageReports', label: 'Şikayet Yönetimi', isBoolean: true },
      { key: 'canManageNotifications', label: 'Bildirim Yönetimi', isBoolean: true },
      { key: 'canManageEsnaf', label: 'Esnaf Yönetimi', isBoolean: true },
      { key: 'canManageCoupons', label: 'Kupon Yönetimi', isBoolean: true },
      { key: 'canManageAdmins', label: 'Admin Yönetimi', isBoolean: true },
    ]
  },
  sikayetler: {
    title: 'Yorum Şikayetleri',
    bucket: null,
    fields: [
      { key: 'userName', label: 'Şikayet Edilen Kullanıcı' },
      { key: 'content', label: 'Yorum İçeriği', multiline: true },
      { key: 'targetType', label: 'Hedef Türü' },
      { key: 'targetId', label: 'Hedef ID' },
      { key: 'status', label: 'Durum (pending/dismissed/reviewed_deleted)' },
      { key: 'timestamp', label: 'Tarih', isDate: true },
    ]
  }
};
