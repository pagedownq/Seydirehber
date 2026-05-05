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

// Tarih ayrıştırma yardımcı fonksiyonu (DD.MM.YYYY formatı için)
function parseDate(dateStr) {
  try {
    const parts = dateStr.trim().split('.');
    if (parts.length === 3) {
      return new Date(parts[2], parts[1] - 1, parts[0]);
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
    const thirtyDays = 30 * 24 * 60 * 60 * 1000;

    // Listeyi tara ve ilk geçerli (tarihi mantıklı) kişiyi bul
    rows.each((i, el) => {
      const name = $(el).find('th').first().text().trim();
      const dateStr = $(el).find('th').eq(2).text().trim();
      const vefatDate = parseDate(dateStr);

      if (name && vefatDate) {
        const diff = Math.abs(now - vefatDate);
        // Sadece son 30 gün veya gelecek 30 gün içindeyse kabul et
        if (diff <= thirtyDays) {
          targetVefat = { name, dateStr };
          return false; // Döngüden çık
        } else {
          console.log(`Atlanan hatalı tarihli ilan: ${name} (${dateStr})`);
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
