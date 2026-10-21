import type { LiveDoc } from '@/features/firestore/live-query';

// Flutter admin_manage_screen.dart _getFields / _sortDocs karşılığı.
export type FieldConfig = {
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
  readOnly?: boolean;
  defaultValue?: boolean | string;
};

const f = (key: string, label: string, options: Omit<FieldConfig, 'key' | 'label'> = {}): FieldConfig => ({
  key,
  label,
  ...options,
});

const KONUM = 'Harita Konumu (Link, Koordinat veya DMS)';

export function getFields(collection: string): FieldConfig[] {
  switch (collection) {
    case 'banners':
      return [
        f('ad', 'Banner Adı', { required: true }),
        f('url', 'Dış Bağlantı (Opsiyonel)'),
        f('company_id', 'Firma Yönlendirme (Opsiyonel)', { isCompanyPicker: true }),
        f('order', 'Sıra (0, 1, 2...)', { isNumber: true }),
        f('aktif', 'Aktif mi?', { isBoolean: true, defaultValue: true }),
      ];
    case 'etkinlikler':
      return [
        f('ad', 'Etkinlik Adı', { required: true }),
        f('hakkinda', 'Hakkında', { multiline: true }),
        f('baslangic_tarihi_str', 'Başlangıç Tarihi', { isDate: true }),
        f('bitis_tarihi_str', 'Bitiş Tarihi', { isDate: true }),
        f('saat', 'Saat', { isTime: true }),
        f('adres', 'Görünecek Adres (Örn: Aşağı Hisar...)'),
        f('konum', KONUM),
      ];
    case 'noterler':
      return [
        f('ad', 'Noter Adı', { required: true }),
        f('gunler', 'Açık Günler'),
        f('telefon', 'Telefon'),
        f('adres', 'Görünecek Adres'),
        f('konum', KONUM),
      ];
    case 'pazarlar':
      return [
        f('ad', 'Pazar Adı', { required: true }),
        f('gunler', 'Açık Günler'),
        f('adres', 'Görünecek Adres'),
        f('konum', KONUM),
      ];
    case 'otobus_saatleri':
      return [
        f('guzergah', 'Güzergah', { required: true }),
        f('saatler_hergun', 'Her Gün Sefer Saatleri (Ortak)', { isTimeList: true }),
        f('saatler_haftaici', 'Hafta İçi (Pzt-Cum)', { isTimeList: true }),
        f('saatler_cumartesi', 'Cumartesi', { isTimeList: true }),
        f('saatler_pazar', 'Pazar', { isTimeList: true }),
        f('duraklar', 'Duraklar (Opsiyonel)', { multiline: true }),
        f('order', 'Sıra', { isNumber: true }),
      ];
    case 'gezilecek_yerler':
      return [
        f('ad', 'Yer Adı', { required: true }),
        f('hakkinda', 'Hakkında', { multiline: true }),
        f('tarihce', 'Tarihçe', { multiline: true }),
        f('adres', 'Görünecek Adres'),
        f('konum', KONUM),
        f('order', 'Sıra (Görünüm Sırası)', { isNumber: true }),
      ];
    case 'firmalar':
      return [
        f('ad', 'Firma Adı', { required: true }),
        f('kategori', 'Kategori (Örn: Restoran, Kafe, Market)'),
        f('yetkili_kisi', 'Yetkili Kişi'),
        f('hakkinda', 'Hakkında', { multiline: true }),
        f('iletisim', 'İletişim (Telefon)', { isPhone: true }),
        f('adres', 'Görünecek Adres'),
        f('konum', KONUM),
        f('website', 'Web Sitesi'),
        f('instagram', 'Instagram (Kullanıcı adı veya Link)'),
        f('menu_url', 'Dijital Bağlantı (Mağaza, Menü, Katalog vb.)'),
        f('expiry_date', 'Firma Bitiş Tarihi', { isDate: true }),
        f('order', 'Sıra (Görünüm Sırası)', { isNumber: true }),
      ];
    // Expo'ya özgü (Flutter'da yok). Yayın bitişi boşsa ilan eklendikten 30 gün sonra gizlenir.
    case 'is_ilanlari':
      return [
        f('baslik', 'İlan Başlığı (Örn: Garson Aranıyor)', { required: true }),
        f('firma_adi', 'İşveren / Firma Adı', { required: true }),
        f('company_id', 'Uygulamadaki Firma (Opsiyonel)', { isCompanyPicker: true }),
        f('calisma_sekli', 'Çalışma Şekli (Tam Zamanlı, Yarı Zamanlı, Dönemsel...)'),
        f('aciklama', 'İş Tanımı / Aranan Nitelikler', { multiline: true }),
        f('calisma_saatleri', 'Çalışma Saatleri (Opsiyonel)'),
        f('ucret', 'Ücret (Opsiyonel)'),
        f('telefon', 'İletişim Telefonu', { isPhone: true, required: true }),
        f('whatsapp', 'WhatsApp ile ulaşılabilir mi?', { isBoolean: true, defaultValue: true }),
        f('adres', 'Görünecek Adres'),
        f('konum', KONUM),
        f('bitis_tarihi', 'Yayın Bitiş Tarihi (Boşsa 30 gün)', { isDate: true }),
        f('aktif', 'Yayında mı?', { isBoolean: true, defaultValue: true }),
      ];
    case 'esnaf_users':
      return [
        f('username', 'Kullanıcı Adı', { required: true }),
        f('password', 'Şifre', { required: true }),
        f('companyId', 'Bağlı Olduğu Firma', { isCompanyPicker: true, required: true }),
        f('companyName', 'Firma Adı', { required: true }),
      ];
    case 'coupons':
      return [
        f('title', 'Kupon Başlığı (Örn: %20 İndirim)', { required: true }),
        f('description', 'Kupon Detayı', { multiline: true }),
        f('companyId', 'Firma Seç', { isCompanyPicker: true, required: true }),
        f('companyName', 'Firma Adı (Otomatik dolar)', { readOnly: true }),
        f('discountPercentage', 'İndirim Yüzdesi (Örn: 20)', { isNumber: true }),
        f('expiry_date', 'Bitiş Tarihi (Opsiyonel)', { isDate: true }),
        f('total_limit', 'Toplam Kupon Sayısı (Opsiyonel)', { isNumber: true }),
        f('isInformational', 'Bilgi Kuponu Mu? (QR/Kodsuz)', { isBoolean: true, defaultValue: false }),
        f('isActive', 'Aktif Mi?', { isBoolean: true, defaultValue: true }),
      ];
    case 'surveys':
      return [
        f('title', 'Anket Başlığı', { required: true }),
        f('url', 'Anket Linki (Google Forms vb.)', { required: true }),
        f('description', 'Açıklama / Bilgi Metni', { multiline: true }),
        f('isActive', 'Aktif Mi?', { isBoolean: true, defaultValue: false }),
      ];
    case 'admins':
      return [
        f('email', 'Admin Email', { required: true }),
        f('ad_soyad', 'Ad Soyad', { required: true }),
        f('isActive', 'Aktif Mi?', { isBoolean: true, defaultValue: true }),
        ...(
          [
            ['canManageBanners', 'Banner Yönetimi'],
            ['canManageEvents', 'Etkinlik Yönetimi'],
            ['canManageNotaries', 'Noter Yönetimi'],
            ['canManageMarkets', 'Pazar Yönetimi'],
            ['canManageBuses', 'Ulaşım Yönetimi'],
            ['canManagePlaces', 'Mekan Yönetimi'],
            ['canManageCompanies', 'Firma Yönetimi'],
            ['canManageSupport', 'Destek Yönetimi'],
            ['canManageReviews', 'Yorum Yönetimi'],
            ['canManageReports', 'Şikayet Yönetimi'],
            ['canManageNotifications', 'Bildirim Yönetimi'],
            ['canManageEsnaf', 'Esnaf Yönetimi'],
            ['canManageCoupons', 'Kupon Yönetimi'],
            ['canManageAdmins', 'Admin Yönetimi'],
            ['canManageSurveys', 'Anket Yönetimi'],
            // Flutter formunda yoktu (yetki vardı ama verilemiyordu); kullanıcı isteğiyle eklendi.
            ['canManageForum', 'Forum Moderasyonu'],
            ['canManageJobs', 'İş İlanı Yönetimi'],
          ] as const
        ).map(([key, label]) => f(key, label, { isBoolean: true, defaultValue: false })),
      ];
    default:
      return [f('ad', 'Ad', { required: true })];
  }
}

/** Sürükle-bırak ile sıralanabilen koleksiyonlar (order alanı). */
export const isReorderable = (collection: string) =>
  ['firmalar', 'banners', 'gezilecek_yerler', 'otobus_saatleri'].includes(collection);

const orderOf = (data: Record<string, unknown>) => {
  const value = Number(String(data.order ?? ''));
  return data.order != null && String(data.order) !== '' && Number.isFinite(value) ? value : 999999;
};

/** Flutter _sortDocs (Dart String.compareTo gibi kod noktası sırası). */
export function sortDocs(collection: string, docs: LiveDoc[]): LiveDoc[] {
  const sorted = [...docs];
  if (collection === 'firmalar' || collection === 'gezilecek_yerler' || collection === 'otobus_saatleri') {
    sorted.sort((a, b) => {
      const diff = orderOf(a.data) - orderOf(b.data);
      if (diff !== 0) return diff;
      const aName = String(a.data.ad ?? a.data.guzergah ?? '').toLowerCase();
      const bName = String(b.data.ad ?? b.data.guzergah ?? '').toLowerCase();
      return aName < bName ? -1 : aName > bName ? 1 : 0;
    });
  } else if (collection === 'banners') {
    sorted.sort((a, b) => orderOf(a.data) - orderOf(b.data));
  }
  return sorted;
}

/** Liste başlığı: ilk dolu ad alanı. */
export function displayName(data: Record<string, unknown>) {
  for (const key of ['ad', 'title', 'baslik', 'ad_soyad', 'companyName', 'userName', 'name', 'guzergah']) {
    if (typeof data[key] === 'string') return data[key] as string;
  }
  return 'İsimsiz';
}
