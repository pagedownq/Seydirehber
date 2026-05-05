const axios = require('axios');
const cheerio = require('cheerio');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK'yı başlat
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  console.error('FIREBASE_SERVICE_ACCOUNT environment variable is missing.');
  process.exit(1);
}

const LATEST_VEFAT_FILE = path.join(__dirname, 'latest_vefat.json');

// Tarih ayrıştırma yardımcı fonksiyonu (DD.MM.YYYY veya D Ay YYYY formatı için)
function parseDate(dateStr) {
  try {
    const cleanedDate = dateStr.trim().toLowerCase();
    
    // Eğer nokta ile ayrılmışsa (05.05.2026)
    if (cleanedDate.includes('.')) {
      const parts = cleanedDate.split('.');
      if (parts.length === 3) {
        return new Date(parts[2], parts[1] - 1, parts[0]);
      }
    }

    // Eğer boşluk ile ayrılmışsa (5 mayıs 2026)
    const parts = cleanedDate.split(' ');
    if (parts.length === 3) {
      const day = parseInt(parts[0]);
      const year = parseInt(parts[2]);
      const monthStr = parts[1];
      
      const months = {
        'ocak': 0, 'şubat': 1, 'mart': 2, 'nisan': 3, 'mayıs': 4, 'haziran': 5,
        'temmuz': 6, 'ağustos': 7, 'eylül': 8, 'ekim': 9, 'kasım': 10, 'aralık': 11
      };
      
      // Ay isminin anahtarlardan birini içerip içermediğine bak
      let month = 0;
      for (const [key, value] of Object.entries(months)) {
        if (monthStr.includes(key)) {
          month = value;
          break;
        }
      }
      
      return new Date(year, month, day);
    }
  } catch (e) {}
  return null;
}

async function checkVefat() {
  try {
    console.log('Belediye sitesi kontrol ediliyor...');
    const response = await axios.get('https://www.seydisehir.bel.tr/vefatedenler', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    });

    const $ = cheerio.load(response.data);
    const rows = $('table.table tbody tr');
    
    if (!rows.length) {
      console.log('Vefat listesi bulunamadı.');
      return;
    }

    let targetVefat = null;
    const now = new Date();
    const safetyFutureLimit = new Date(now.getTime() + (7 * 24 * 60 * 60 * 1000));

    // Listeyi tara ve ilk geçerli (tarihi mantıklı) kişiyi bul
    rows.each((i, el) => {
      const name = $(el).find('th').first().text().trim();
      const dateStr = $(el).find('th').eq(2).text().trim();
      const vefatDate = parseDate(dateStr);

      if (name && vefatDate) {
        // Geçmişteki her şeye izin ver, ama gelecekte 7 günden fazlasını reddet
        if (vefatDate <= safetyFutureLimit) {
          targetVefat = { name, dateStr };
          return false; // Döngüden çık
        } else {
          console.log(`Atlanan absürt tarihli ilan: ${name} (${dateStr})`);
        }
      }
    });

    if (!targetVefat) {
      console.log('Geçerli tarihe sahip yeni ilan bulunamadı.');
      return;
    }

    console.log(`İşlem yapılacak son geçerli kişi: ${targetVefat.name}`);

    // Eski veriyi oku
    let latestData = { name: '' };
    if (fs.existsSync(LATEST_VEFAT_FILE)) {
      latestData = JSON.parse(fs.readFileSync(LATEST_VEFAT_FILE, 'utf8'));
    }

    // Karşılaştır
    if (targetVefat.name !== latestData.name) {
      console.log('Yeni geçerli vefat ilanı tespit edildi! Bildirim gönderiliyor...');

      const message = {
        notification: {
          title: 'Yeni Vefat Bildirimi 🔔',
          body: 'Detaylar için uygulamayı ziyaret edebilirsiniz.'
        },
        data: {
          screen: '/vefat',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        topic: 'vefat_notif'
      };

      await admin.messaging().send(message);
      console.log('Bildirim başarıyla gönderildi.');

      // Yeni ismi kaydet
      fs.writeFileSync(LATEST_VEFAT_FILE, JSON.stringify({ 
        name: targetVefat.name, 
        checkDate: new Date().toISOString(),
        vefatDate: targetVefat.dateStr
      }, null, 2));
    } else {
      console.log('Yeni bir ilan yok.');
    }

  } catch (error) {
    console.error('Hata oluştu:', error.message);
  }
}

checkVefat();
