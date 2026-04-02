import { useState, useEffect } from 'react';
import './App.css';
import Sidebar from './components/Sidebar';
import DashboardOverview from './components/DashboardOverview';
import ManageCollection from './components/ManageCollection';
import NotificationManagement from './components/NotificationManagement';
import { auth } from './lib/firebase';
import { onAuthStateChanged, signInWithPopup, GoogleAuthProvider, signOut } from 'firebase/auth';
import { getDoc, doc } from 'firebase/firestore';
import { LogOut, Loader2 } from 'lucide-react';
import { db } from './lib/firebase';

const ADMIN_EMAILS = [
  'mehmetirem305@gmail.com',
  'bilgimgverse@gmail.com',
  'seydirehber@gmail.com'
];

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const checkAdminStatus = async (u: any) => {
    if (ADMIN_EMAILS.includes(u.email || '')) return true;
    
    try {
      const adminDoc = await getDoc(doc(db, 'admins', u.email || ''));
      return adminDoc.exists() && adminDoc.data()?.isActive !== false;
    } catch (err) {
      console.error('Admin check error:', err);
      return false;
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (u) => {
      if (u) {
        setLoading(true);
        const isAdmin = await checkAdminStatus(u);
        if (isAdmin) {
          setUser(u);
        } else {
          await signOut(auth);
          setError('Bu hesabı kullanma yetkiniz yok.');
          setUser(null);
        }
      } else {
        setUser(null);
      }
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const handleGoogleLogin = async () => {
    setLoading(true);
    setError('');
    const provider = new GoogleAuthProvider();
    try {
      const result = await signInWithPopup(auth, provider);
      const u = result.user;
      const isAdmin = await checkAdminStatus(u);
      
      if (!isAdmin) {
        await signOut(auth);
        setError('Yetkisiz giriş: Bu e-posta admin listesinde değil.');
        setUser(null);
      } else {
        setUser(u);
      }
    } catch (err: any) {
      setError('Giriş başarısız: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    await signOut(auth);
  };

  if (loading) {
    return (
      <div style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#0f172a' }}>
        <Loader2 className="spin" size={48} color="#6366f1" />
      </div>
    );
  }

  if (!user) {
    return (
      <div style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#0f172a', padding: '1rem' }}>
        <div className="card" style={{ maxWidth: '440px', width: '100%', padding: '3rem', textAlign: 'center' }}>
          <div className="logo" style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>Seydi Rehber</div>
          <p className="text-muted" style={{ marginBottom: '2rem' }}>Yönetim paneline erişmek için lütfen admin hesabınızla giriş yapın.</p>

          {error && (
            <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid #ef444455', color: '#ef4444', padding: '0.75rem', borderRadius: '0.75rem', marginBottom: '1.5rem', fontSize: '0.875rem' }}>
              {error}
            </div>
          )}

          <button
            className="btn btn-google"
            style={{ width: '100%', padding: '0.875rem', justifyContent: 'center', gap: '1rem' }}
            onClick={handleGoogleLogin}
            disabled={loading}
          >
            <img src="https://www.google.com/favicon.ico" alt="Google" style={{ width: 18, height: 18 }} />
            Google ile Giriş Yap
          </button>

          <div style={{ marginTop: '2rem', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
            Sadece yetkili admin hesapları giriş yapabilir.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="app-container">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      <main className="main-content">
        <div className="top-nav" style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '2rem', gap: '1rem', alignItems: 'center' }}>
          <div className="text-muted" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'var(--glass-bg)', padding: '0.5rem 1rem', borderRadius: '2rem', border: '1px solid var(--border)' }}>
            {user.photoURL && <img src={user.photoURL} style={{ width: 24, height: 24, borderRadius: '50%' }} alt="User" />}
            <span style={{ fontSize: '0.875rem' }}>{user.email}</span>
          </div>
          <button className="btn btn-outline" style={{ padding: '0.5rem', borderRadius: '50%', width: 40, height: 40, display: 'flex', justifyContent: 'center' }} title="Çıkış Yap" onClick={handleLogout}>
            <LogOut size={18} />
          </button>
        </div>

        {activeTab === 'dashboard' ? (
          <DashboardOverview />
        ) : activeTab === 'notifications' ? (
          <NotificationManagement />
        ) : (
          <ManageCollection key={activeTab} collectionId={activeTab} />
        )}
      </main>
    </div>
  );
}

export default App;
