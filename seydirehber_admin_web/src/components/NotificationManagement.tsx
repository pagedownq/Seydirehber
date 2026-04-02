import React, { useState, useEffect } from 'react';
import { db } from '../lib/firebase';
import { 
  collection, 
  query, 
  orderBy, 
  onSnapshot, 
  addDoc, 
  deleteDoc, 
  doc, 
  serverTimestamp,
  limit 
} from 'firebase/firestore';
import { Send, Bell, Trash2, Loader2, Calendar } from 'lucide-react';
import { sendFCMNotification } from '../lib/fcm';
import { format } from 'date-fns';

const NotificationManagement: React.FC = () => {
  const [notifications, setNotifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [status, setStatus] = useState<{ type: 'success' | 'error', message: string } | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, 'duyurular'), 
      orderBy('tarih', 'desc'),
      limit(20)
    );
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setNotifications(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });
    
    return unsubscribe;
  }, []);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !body) return;

    setSending(true);
    setStatus(null);

    try {
      // 1. Send to FCM
      await sendFCMNotification(title, body);

      // 2. Save to Firestore
      await addDoc(collection(db, 'duyurular'), {
        baslik: title,
        icerik: body,
        tarih: serverTimestamp(),
      });

      setTitle('');
      setBody('');
      setStatus({ type: 'success', message: 'Bildirim başarıyla tüm kullanıcılara gönderildi.' });
      
      setTimeout(() => setStatus(null), 5000);
    } catch (err: any) {
      console.error('Send error:', err);
      setStatus({ type: 'error', message: 'Bildirim gönderilirken hata oluştu: ' + (err.message || 'Bilinmeyen hata') });
    } finally {
      setSending(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Bu bildirim kaydını geçmişten silmek istediğinize emin misiniz? (Cihazlardan silinmez)')) return;
    try {
      await deleteDoc(doc(db, 'duyurular', id));
    } catch (err) {
      console.error('Delete error:', err);
    }
  };


  return (
    <div className="collection-view">
      <div className="header">
        <div>
          <h1>Bildirim Yönetimi</h1>
          <p className="text-muted">Tüm kullanıcılara anlık push bildirimi gönderin</p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '2rem' }}>
        {/* Send Form */}
        <div className="card" style={{ height: 'fit-content' }}>
          <div style={{ marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
             <div style={{ background: 'rgba(99, 102, 241, 0.1)', padding: '0.5rem', borderRadius: '12px' }}>
                <Send size={20} color="#6366f1" />
             </div>
             <h3 style={{ margin: 0 }}>Yeni Bildirim Oluştur</h3>
          </div>

          <form onSubmit={handleSend}>
            <div className="form-group">
              <label className="label">Bildirim Başlığı</label>
              <input 
                className="input" 
                placeholder="Örn: Yeni Kampanya!"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />
            </div>
            
            <div className="form-group">
              <label className="label">Bildirim İçeriği</label>
              <textarea 
                className="input" 
                rows={4}
                placeholder="Bildirim mesajınızı buraya yazın..."
                value={body}
                onChange={(e) => setBody(e.target.value)}
                required
              />
            </div>


            {status && (
              <div style={{ 
                background: status.type === 'success' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)', 
                color: status.type === 'success' ? '#22c55e' : '#ef4444',
                padding: '0.75rem',
                borderRadius: '0.75rem',
                marginBottom: '1rem',
                fontSize: '0.875rem'
              }}>
                {status.message}
              </div>
            )}

            <button className="btn btn-primary" style={{ width: '100%', justifyContent: 'center' }} disabled={sending}>
              {sending ? <Loader2 className="spin" size={20} /> : (
                <>
                  <Send size={18} />
                  Şimdi Tüm Cihazlara Gönder
                </>
              )}
            </button>
            <p style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: '1rem', textAlign: 'center' }}>
              * 'Gönder' butonuna bastığınızda bildirim tüm aktif kullanıcılara anında iletilecektir.
            </p>
          </form>
        </div>

        {/* History List */}
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
             <div style={{ background: 'rgba(245, 158, 11, 0.1)', padding: '0.5rem', borderRadius: '12px' }}>
                <Bell size={20} color="#f59e0b" />
             </div>
             <h3 style={{ margin: 0 }}>Bildirim Geçmişi (Son 20)</h3>
          </div>

          <div style={{ maxHeight: '600px', overflowY: 'auto' }}>
            {loading ? (
              <div style={{ padding: '3rem', textAlign: 'center' }}>
                <Loader2 className="spin" />
              </div>
            ) : notifications.length === 0 ? (
              <div style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                Henüz gönderilmiş bildirim bulunmuyor.
              </div>
            ) : (
              <table className="table">
                <thead>
                  <tr>
                    <th>Başlık / İçerik</th>
                    <th>Tarih</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {notifications.map((notif) => (
                    <tr key={notif.id}>
                      <td style={{ padding: '1rem' }}>
                        <div style={{ fontWeight: 600, color: 'var(--text)', marginBottom: '0.25rem' }}>{notif.baslik}</div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', lineHeight: '1.4' }}>{notif.icerik}</div>
                      </td>
                      <td style={{ padding: '1rem', fontSize: '0.75rem', whiteSpace: 'nowrap', color: 'var(--text-muted)' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <Calendar size={12} />
                          {notif.tarih?.toDate ? format(notif.tarih.toDate(), 'dd.MM.yyyy HH:mm') : '...'}
                        </div>
                      </td>
                      <td style={{ padding: '1rem' }}>
                        <button 
                          className="btn btn-outline" 
                          style={{ padding: '0.4rem', color: '#ef4444' }} 
                          onClick={() => handleDelete(notif.id)}
                        >
                          <Trash2 size={16} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default NotificationManagement;
