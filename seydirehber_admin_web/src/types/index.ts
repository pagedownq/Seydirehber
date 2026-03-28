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
      { key: 'konum', label: 'Konum (Adres veya Harita Linki)' },
    ],
  },
  noterler: {
    title: 'Noter Yönetimi',
    bucket: 'noter',
    fields: [
      { key: 'ad', label: 'Noter Adı', required: true },
      { key: 'gunler', label: 'Açık Günler' },
      { key: 'telefon', label: 'Telefon', isPhone: true },
      { key: 'konum', label: 'Konum (Adres veya Harita Linki)' },
    ],
  },
  pazarlar: {
    title: 'Pazar Yönetimi',
    bucket: 'pazar',
    fields: [
      { key: 'ad', label: 'Pazar Adı', required: true },
      { key: 'gunler', label: 'Açık Günler' },
      { key: 'konum', label: 'Konum (Adres veya Harita Linki)' },
    ],
  },
  otobus_saatleri: {
    title: 'Otobüs Saatleri Yönetimi',
    bucket: null,
    fields: [
      { key: 'guzergah', label: 'Güzergah', required: true },
      { key: 'saatler', label: 'Sefer Saatleri (Seçmeli)', multiline: true },
      { key: 'duraklar', label: 'Duraklar', multiline: true },
    ],
  },
  gezilecek_yerler: {
    title: 'Gezilecek Yerler',
    bucket: 'gezilcek_yerler',
    fields: [
      { key: 'ad', label: 'Yer Adı', required: true },
      { key: 'hakkinda', label: 'Hakkında', multiline: true },
      { key: 'tarihce', label: 'Tarihçe', multiline: true },
      { key: 'konum', label: 'Konum (Adres veya Harita Linki)' },
    ],
  },
  firmalar: {
    title: 'Firma Yönetimi',
    bucket: 'firmalar',
    fields: [
      { key: 'ad', label: 'Firma Adı', required: true },
      { key: 'yetkili_kisi', label: 'Yetkili Kişi' },
      { key: 'hakkinda', label: 'Hakkında', multiline: true },
      { key: 'iletisim', label: 'İletişim (Telefon)', isPhone: true },
      { key: 'konum', label: 'Konum (Adres veya Harita Linki)' },
      { key: 'website', label: 'Web Sitesi' },
      { key: 'instagram', label: 'Instagram (Kullanıcı adı veya Link)' },
      { key: 'expiry_date', label: 'Bitiş Tarihi (Sona Erme)', isDate: true },
    ],
  },
  yardim_destek: {
    title: 'Yardım ve Destek',
    bucket: null,
    fields: [
      { key: 'ad_soyad', label: 'Ad Soyad', required: true },
      { key: 'email', label: 'E-posta' },
      { key: 'kategori', label: 'Kategori' },
      { key: 'mesaj', label: 'Mesaj', multiline: true, required: true },
      { key: 'durum', label: 'Durum (Bekliyor/Çözüldü)' },
      { key: 'tarih', label: 'Tarih', isDate: true },
    ]
  }
};
