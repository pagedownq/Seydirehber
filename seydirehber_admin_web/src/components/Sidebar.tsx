import React from 'react';
import { LayoutDashboard, Image, Calendar, Gavel, Store, Bus, MapPin, Building, MessageSquare } from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const Sidebar: React.FC<SidebarProps> = ({ activeTab, setActiveTab }) => {
  const menuItems = [
    { id: 'dashboard', label: 'Genel Bakış', icon: LayoutDashboard },
    { id: 'banners', label: 'Banner Yönetimi', icon: Image },
    { id: 'etkinlikler', label: 'Etkinlikler', icon: Calendar },
    { id: 'noterler', label: 'Noterler', icon: Gavel },
    { id: 'pazarlar', label: 'Pazarlar', icon: Store },
    { id: 'otobus_saatleri', label: 'Otobüs Saatleri', icon: Bus },
    { id: 'gezilecek_yerler', label: 'Gezilecek Yerler', icon: MapPin },
    { id: 'firmalar', label: 'Firmalar', icon: Building },
    { id: 'yardim_destek', label: 'Yardım ve Destek', icon: MessageSquare },
  ];

  return (
    <aside className="sidebar">
      <div className="logo">Seydi Rehber Admin</div>
      <nav>
        {menuItems.map((item) => {
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
