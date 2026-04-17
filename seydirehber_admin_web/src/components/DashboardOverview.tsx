import { useState, useEffect } from 'react';
import { db } from '../lib/firebase';
import { collection, query, onSnapshot, where } from 'firebase/firestore';
import { Users, Activity, Award, Clock, MapPin, Bus, Tag, MessageSquare, ShieldCheck, Image, Store, CheckCircle2 } from 'lucide-react';

interface DashboardOverviewProps {
  permissions: Record<string, boolean>;
}

const DashboardOverview = ({ permissions }: DashboardOverviewProps) => {
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
    // Only fetch counts for allowed collections
    const collectionsToCount = [
      { key: 'firmalar', perm: 'canManageCompanies' },
      { key: 'etkinlikler', perm: 'canManageEvents' },
      { key: 'gezilecek_yerler', perm: 'canManagePlaces' },
      { key: 'noterler', perm: 'canManageNotaries' },
      { key: 'pazarlar', perm: 'canManageMarkets' },
      { key: 'otobus_saatleri', perm: 'canManageBuses' },
      { key: 'banners', perm: 'canManageBanners' },
      { key: 'reviews', perm: 'canManageReviews' },
      { key: 'esnaf_users', perm: 'canManageEsnaf' },
      { key: 'coupons', perm: 'canManageCoupons' }
    ].filter(col => permissions[col.perm]);

    const unsubscribes = collectionsToCount.map(col => {
      return onSnapshot(collection(db, col.key), (snap) => {
        setStats(prev => ({ ...prev, [col.key]: snap.size }));
      });
    });

    let unsubscribeSupport = () => {};
    if (permissions['canManageSupport']) {
      const qSupport = query(collection(db, 'yardim_destek'), where('durum', '==', 'Bekliyor'));
      unsubscribeSupport = onSnapshot(qSupport, (snap) => {
        setStats(prev => ({ ...prev, destek_bekleyen: snap.size }));
      });
    }

    let unsubscribeUsed = () => {};
    if (permissions['canManageCoupons']) {
      const qUsed = query(collection(db, 'generated_codes'), where('status', '==', 'used'));
      unsubscribeUsed = onSnapshot(qUsed, (snap) => {
        // @ts-ignore
        setStats(prev => ({ ...prev, used_coupons: snap.size }));
      });
    }

    let unsubscribeReports = () => {};
    if (permissions['canManageReports']) {
      const qReports = query(collection(db, 'sikayetler'), where('status', '==', 'pending'));
      unsubscribeReports = onSnapshot(qReports, (snap) => {
        setStats(prev => ({ ...prev, bekleyen_sikayetler: snap.size }));
      });
    }

    return () => {
      unsubscribes.forEach(unsub => unsub());
      unsubscribeSupport();
      unsubscribeUsed();
      unsubscribeReports();
    };
  }, [permissions]);

  return (
    <div className="dashboard-overview">
      <div className="header">
        <h1>Seydi Rehber Yönetim Paneli</h1>
        <p className="text-muted">Hoş geldiniz, her şey yolunda görünüyor.</p>
      </div>

      <div className="grid">
        {permissions['canManageCompanies'] && <StatCard icon={Award} label="Kayıtlı Firma" value={stats.firmalar} color="#6366f1" />}
        {permissions['canManageEvents'] && <StatCard icon={Activity} label="Aktif Etkinlik" value={stats.etkinlikler} color="#ec4899" />}
        {permissions['canManagePlaces'] && <StatCard icon={Users} label="Gezilecek Yer" value={stats.gezilecek_yerler} color="#a855f7" />}
        {permissions['canManageSupport'] && <StatCard icon={Clock} label="Bekleyen Destek" value={stats.destek_bekleyen} color="#f59e0b" />}
        {permissions['canManageNotaries'] && <StatCard icon={MapPin} label="Noterler" value={stats.noterler} color="#ef4444" />}
        {permissions['canManageMarkets'] && <StatCard icon={Store} label="Pazarlar" value={stats.pazarlar} color="#10b981" />}
        {permissions['canManageBuses'] && <StatCard icon={Bus} label="Otobüs Saatleri" value={stats.otobus_saatleri} color="#0ea5e9" />}
        {permissions['canManageCoupons'] && <StatCard icon={Tag} label="Kupon Sayısı" value={stats.coupons} color="#f97316" />}
        {permissions['canManageCoupons'] && <StatCard icon={CheckCircle2} label="Kullanılan Kuponlar" value={(stats as any).used_coupons || 0} color="#22c55e" />}
        {permissions['canManageReviews'] && <StatCard icon={MessageSquare} label="Yorumlar" value={stats.reviews} color="#8b5cf6" />}
        {permissions['canManageReports'] && <StatCard icon={ShieldCheck} label="Bekleyen Şikayet" value={stats.bekleyen_sikayetler} color="#f43f5e" />}
        {permissions['canManageEsnaf'] && <StatCard icon={Users} label="Esnaf Hesapları" value={stats.esnaf_users} color="#06b6d4" />}
        {permissions['canManageBanners'] && <StatCard icon={Image} label="Bannerler" value={stats.banners} color="#db2777" />}
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
