import React, { useState } from 'react';
import { db } from '../lib/firebase';
import { collection, query, onSnapshot, where } from 'firebase/firestore';
import { Users, Activity, Award, Clock } from 'lucide-react';

const DashboardOverview = () => {
  const [stats, setStats] = useState({
    firmalar: 0,
    etkinlikler: 0,
    gezilecek_yerler: 0,
    destek_bekleyen: 0,
  });

  React.useEffect(() => {
    // Standard collections count
    ['firmalar', 'etkinlikler', 'gezilecek_yerler'].forEach(col => {
      onSnapshot(collection(db, col), (snap) => {
        setStats(prev => ({ ...prev, [col]: snap.size }));
      });
    });

    // Support pending count specifically
    const q = query(collection(db, 'yardim_destek'), where('durum', '==', 'Bekliyor'));
    const unsubscribe = onSnapshot(q, (snap) => {
      setStats(prev => ({ ...prev, destek_bekleyen: snap.size }));
    });

    return () => unsubscribe();
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
