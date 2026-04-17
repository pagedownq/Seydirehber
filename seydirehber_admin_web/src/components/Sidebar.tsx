import React from 'react';
import { LayoutDashboard, Image, Calendar, Gavel, Store, Bus, MapPin, Building, MessageSquare, Users, Ticket, ShieldCheck, Bell } from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  permissions: Record<string, boolean>;
}

const Sidebar: React.FC<SidebarProps> = ({ activeTab, setActiveTab, permissions }) => {
  const menuItems = [
    { id: 'dashboard', label: 'Genel Bakış', icon: LayoutDashboard },
    { id: 'banners', label: 'Banner Yönetimi', icon: Image, perm: 'canManageBanners' },
    { id: 'etkinlikler', label: 'Etkinlikler', icon: Calendar, perm: 'canManageEvents' },
    { id: 'noterler', label: 'Noterler', icon: Gavel, perm: 'canManageNotaries' },
    { id: 'pazarlar', label: 'Pazarlar', icon: Store, perm: 'canManageMarkets' },
    { id: 'otobus_saatleri', label: 'Otobüs Saatleri', icon: Bus, perm: 'canManageBuses' },
    { id: 'gezilecek_yerler', label: 'Gezilecek Yerler', icon: MapPin, perm: 'canManagePlaces' },
    { id: 'firmalar', label: 'Firmalar', icon: Building, perm: 'canManageCompanies' },
    { id: 'yardim_destek', label: 'Yardım ve Destek', icon: MessageSquare, perm: 'canManageSupport' },
    { id: 'reviews', label: 'Yorum Yönetimi', icon: LayoutDashboard, perm: 'canManageReviews' },
    { id: 'sikayetler', label: 'Yorum Şikayetleri', icon: ShieldCheck, perm: 'canManageReports' },
    { id: 'esnaf_users', label: 'Esnaf Hesapları', icon: Users, perm: 'canManageEsnaf' },
    { id: 'coupons', label: 'Kupon Yönetimi', icon: Ticket, perm: 'canManageCoupons' },
    { id: 'notifications', label: 'Bildirim Yönetimi', icon: Bell, perm: 'canManageNotifications' },
    { id: 'admins', label: 'Admin Yönetimi', icon: ShieldCheck, perm: 'canManageAdmins' },
  ];

  const filteredItems = menuItems.filter(item => !item.perm || permissions[item.perm]);

  return (
    <aside className="sidebar">
      <div className="logo">Seydi Rehber Admin</div>
      <nav>
        {filteredItems.map((item) => {
          const Icon = item.icon;
          return (
            <div
              key={item.id}
              className={`nav-item ${activeTab === item.id ? 'active' : ''}`}
              onClick={() => setActiveTab(item.id)}
            >
              <Icon size={20} />
              <span>{item.label}</span>
            </div>
          );
        })}
      </nav>
    </aside>
  );
};

export default Sidebar;
