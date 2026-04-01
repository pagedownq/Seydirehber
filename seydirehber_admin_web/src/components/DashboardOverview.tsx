import { useState, useEffect } from 'react';
import { db } from '../lib/firebase';
import { collection, query, onSnapshot, where } from 'firebase/firestore';
import { Users, Activity, Award, Clock, MapPin, Bus, Tag, MessageSquare, ShieldCheck, Image, Store, CheckCircle2 } from 'lucide-react';

const DashboardOverview = () => {
  const [stats, setStats] = useState({
    firmalar: 0,
    etkinlikler: 0,
    gezilecek_yerler: 0,
    destek_bekleyen: 0,
    noterler: 0,
    pazarlar: 0,
    otobus_saatleri: 0,
    banners: 0,
    reviews: 0,
    esnaf_users: 0,
    coupons: 0,
    bekleyen_sikayetler: 0
  });

  useEffect(() => {
    const collectionsToCount = [
      'firmalar', 'etkinlikler', 'gezilecek_yerler', 
      'noterler', 'pazarlar', 'otobus_saatleri', 
      'banners', 'reviews', 'esnaf_users', 'coupons'
    ];

    const unsubscribes = collectionsToCount.map(col => {
      return onSnapshot(collection(db, col), (snap) => {
        setStats(prev => ({ ...prev, [col]: snap.size }));
      });
    });

    const qSupport = query(collection(db, 'yardim_destek'), where('durum', '==', 'Bekliyor'));
    const unsubscribeSupport = onSnapshot(qSupport, (snap) => {
      setStats(prev => ({ ...prev, destek_bekleyen: snap.size }));
    });

    // Count ACTUAL used coupons
    const qUsed = query(collection(db, 'generated_codes'), where('status', '==', 'used'));
    const unsubscribeUsed = onSnapshot(qUsed, (snap) => {
      // @ts-ignore
      setStats(prev => ({ ...prev, used_coupons: snap.size }));
    });

    const qReports = query(collection(db, 'sikayetler'), where('status', '==', 'pending'));
    const unsubscribeReports = onSnapshot(qReports, (snap) => {
      setStats(prev => ({ ...prev, bekleyen_sikayetler: snap.size }));
    });

    return () => {
      unsubscribes.forEach(unsub => unsub());
      unsubscribeSupport();
      unsubscribeUsed();
      unsubscribeReports();
    };
  }, []);

  return (
    <div className="dashboard-overview">
      <div className="header">
        <h1>Seydi Rehber Yönetim Paneli</h1>
        <p className="text-muted">Hoş geldiniz, her şey yolunda görünüyor.</p>
      </div>

      <div className="grid">
        <StatCard icon={Award} label="Kayıtlı Firma" value={stats.firmalar} color="#6366f1" />
        <StatCard icon={Activity} label="Aktif Etkinlik" value={stats.etkinlikler} color="#ec4899" />
        <StatCard icon={Users} label="Gezilecek Yer" value={stats.gezilecek_yerler} color="#a855f7" />
        <StatCard icon={Clock} label="Bekleyen Destek" value={stats.destek_bekleyen} color="#f59e0b" />
        <StatCard icon={MapPin} label="Noterler" value={stats.noterler} color="#ef4444" />
        <StatCard icon={Store} label="Pazarlar" value={stats.pazarlar} color="#10b981" />
        <StatCard icon={Bus} label="Otobüs Saatleri" value={stats.otobus_saatleri} color="#0ea5e9" />
        <StatCard icon={Tag} label="Kupon Sayısı" value={stats.coupons} color="#f97316" />
        <StatCard icon={CheckCircle2} label="Kullanılan Kuponlar" value={(stats as any).used_coupons || 0} color="#22c55e" />
        <StatCard icon={MessageSquare} label="Yorumlar" value={stats.reviews} color="#8b5cf6" />
        <StatCard icon={ShieldCheck} label="Bekleyen Şikayet" value={stats.bekleyen_sikayetler} color="#f43f5e" />
        <StatCard icon={Users} label="Esnaf Hesapları" value={stats.esnaf_users} color="#06b6d4" />
        <StatCard icon={Image} label="Bannerler" value={stats.banners} color="#db2777" />
      </div>

      <div className="card" style={{ marginTop: '2rem' }}>
        <h3>Son Durum</h3>
        <p className="text-muted">Burada son eklenen kayıtlar veya istatistiksel grafikler yer alacak.</p>
      </div>
    </div>
  );
};

const StatCard = ({ icon: Icon, label, value, color }: any) => (
  <div className="card" style={{ borderLeft: `4px solid ${color}` }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <div>
        <div className="text-muted" style={{ fontSize: '0.875rem', marginBottom: '0.25rem' }}>{label}</div>
        <div style={{ fontSize: '1.75rem', fontWeight: 800 }}>{value}</div>
      </div>
      <div style={{ padding: '0.75rem', borderRadius: '1rem', background: `${color}11`, color }}>
        <Icon size={24} />
      </div>
    </div>
  </div>
);

export default DashboardOverview;
