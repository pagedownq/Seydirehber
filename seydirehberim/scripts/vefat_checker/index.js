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

async function checkVefat() {
  try {
    console.log('Belediye sitesi kontrol ediliyor...');
    const response = await axios.get('https://www.seydisehir.bel.tr/vefatedenler', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    });

    const $ = cheerio.load(response.data);
    const firstRow = $('table.table tbody tr').first();
    
    if (!firstRow.length) {
      console.log('Vefat listesi bulunamadı.');
      return;
    }

    const name = firstRow.find('th').first().text().trim();
    const detail = firstRow.find('th').eq(3).text().trim(); // Yer / Zaman sütunu

    if (!name) {
      console.log('İsim okunamadı.');
      return;
    }

    console.log(`Tespit edilen son kişi: ${name}`);

    // Eski veriyi oku
    let latestData = { name: '' };
    if (fs.existsSync(LATEST_VEFAT_FILE)) {
      latestData = JSON.parse(fs.readFileSync(LATEST_VEFAT_FILE, 'utf8'));
    }

    // Karşılaştır
    if (name !== latestData.name) {
      console.log('Yeni vefat ilanı tespit edildi! Bildirim gönderiliyor...');

      const message = {
        notification: {
          title: 'Vefat İlanı 🔔',
          body: `${name} vefat etmiştir. Ailesine ve yakınlarına başsağlığı dileriz.`
        },
        data: {
          screen: '/vefat',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        topic: 'all'
      };

      await admin.messaging().send(message);
      console.log('Bildirim başarıyla gönderildi.');

      // Yeni ismi kaydet
      fs.writeFileSync(LATEST_VEFAT_FILE, JSON.stringify({ name, date: new Date().toISOString() }, null, 2));
    } else {
      console.log('Yeni bir ilan yok.');
    }

  } catch (error) {
    console.error('Hata oluştu:', error.message);
  }
}

checkVefat();
