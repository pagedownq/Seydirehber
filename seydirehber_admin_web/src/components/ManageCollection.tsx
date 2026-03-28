import React, { useState, useEffect } from 'react';
import { db } from '../lib/firebase';
import { supabase } from '../lib/supabase';
import { 
  collection, 
  query, 
  orderBy, 
  onSnapshot, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  serverTimestamp,
  Timestamp 
} from 'firebase/firestore';
import { Plus, Trash2, Edit, X, Upload, Loader2, Search } from 'lucide-react';
import { COLLECTIONS } from '../types';
import { format } from 'date-fns';

interface ManageCollectionProps {
  collectionId: string;
}

const ManageCollection: React.FC<ManageCollectionProps> = ({ collectionId }) => {
  const config = COLLECTIONS[collectionId];
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState<any>(null);
  const [formData, setFormData] = useState<any>({});
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [companies, setCompanies] = useState<any[]>([]);
  const [companySearch, setCompanySearch] = useState('');

  useEffect(() => {
    if (config.fields.some(f => f.isCompanyPicker)) {
      const q = query(collection(db, 'firmalar'), orderBy('ad'));
      const unsubscribe = onSnapshot(q, (snapshot) => {
        setCompanies(snapshot.docs.map(doc => ({ id: doc.id, ad: doc.data().ad })));
      });
      return unsubscribe;
    }
  }, [config.fields]);

  useEffect(() => {
    setLoading(true);
    // Use 'tarih' for support, else 'created_at'
    const sortField = collectionId === 'yardim_destek' ? 'tarih' : 'created_at';
    
    // We try to query with order, if it fails (e.g. index missing), we fallback to no order
    const q = query(collection(db, collectionId), orderBy(sortField, 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setItems(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    }, (error) => {
      console.error('Firestore Error:', error);
      // Fallback: search without order if index is missing or field doesn't exist
      const qFallback = query(collection(db, collectionId));
      onSnapshot(qFallback, (snapshot) => {
        setItems(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        setLoading(false);
      });
    });
    return unsubscribe;
  }, [collectionId]);

  const handleOpenModal = (item?: any) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      setFormData({});
    }
    setSelectedFile(null);
    setShowModal(true);
  };

  const handleUploadImage = async (file: File) => {
    if (!config.bucket) return '';
    setUploading(true);
    const fileName = `${Date.now()}_${file.name}`;
    const { error } = await supabase.storage
      .from(config.bucket)
      .upload(fileName, file);

    if (error) {
      console.error('Upload error:', error);
      setUploading(false);
      return '';
    }

    const { data: { publicUrl } } = supabase.storage
      .from(config.bucket)
      .getPublicUrl(fileName);

    setUploading(false);
    return publicUrl;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setUploading(true);

    try {
      let imageUrl = formData.image_url || formData.gorsel || '';
      
      if (selectedFile) {
        imageUrl = await handleUploadImage(selectedFile);
      }

      const cleanData = { ...formData };
      delete cleanData.id;
      
      // Handle specialized fields
      config.fields.forEach(f => {
        if (f.isNumber) {
          cleanData[f.key] = Number(cleanData[f.key]) || 0;
        }
        if (f.isDate && cleanData[f.key] && typeof cleanData[f.key] === 'string') {
          // Convert HTML date string (YYYY-MM-DD) to Firestore Timestamp
          cleanData[f.key] = Timestamp.fromDate(new Date(cleanData[f.key]));
        }
        // Ensure optional fields can be cleared
        if (!f.required && (cleanData[f.key] === '' || cleanData[f.key] === undefined)) {
          cleanData[f.key] = null;
        }
      });

      if (imageUrl) {
        cleanData.image_url = imageUrl;
      }

      if (editingItem) {
        await updateDoc(doc(db, collectionId, editingItem.id), cleanData);
      } else {
        cleanData.created_at = serverTimestamp();
        await addDoc(collection(db, collectionId), cleanData);
      }

      setShowModal(false);
    } catch (err) {
      console.error('Error saving:', err);
      alert('Kaydedilirken hata oluştu');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (id: string, imageUrl?: string) => {
    if (!window.confirm('Bu ögeyi silmek istediğinize emin misiniz?')) return;
    
    try {
      if (imageUrl && config.bucket) {
        const urlObj = new URL(imageUrl);
        const fileName = urlObj.pathname.split('/').pop();
        if (fileName) {
          await supabase.storage.from(config.bucket).remove([fileName]);
        }
      }
      await deleteDoc(doc(db, collectionId, id));
    } catch (err) {
      console.error('Delete error:', err);
    }
  };

  const filteredItems = items.filter(item => 
    Object.values(item).some(val => 
      String(val).toLowerCase().includes(searchTerm.toLowerCase())
    )
  );

  return (
    <div className="collection-view">
      <div className="header">
        <div>
          <h1>{config.title}</h1>
          <p className="text-muted">{items.length} kayıt bulundu</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <div className="input-group" style={{ position: 'relative' }}>
            <Search size={18} style={{ position: 'absolute', left: 12, top: 12, color: 'var(--text-muted)' }} />
            <input 
              className="input" 
              placeholder="Ara..." 
              style={{ paddingLeft: '2.5rem', width: '250px' }}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <button className="btn btn-primary" onClick={() => handleOpenModal()}>
            <Plus size={20} />
            Ekle
          </button>
        </div>
      </div>

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="table">
          <thead>
            <tr>
              {config.bucket && <th>Görsel</th>}
              <th>Bilgi / İçerik</th>
              {collectionId === 'yardim_destek' && <th>Durum</th>}
              <th>İşlem</th>
            </tr>
          </thead>
          <tbody>
            {filteredItems.map((item) => (
              <tr key={item.id}>
                {config.bucket && (
                  <td>
                    <img 
                      src={item.image_url || item.gorsel || 'https://via.placeholder.com/50'} 
                      alt="" 
                      style={{ width: 48, height: 48, borderRadius: 8, objectFit: 'cover' }}
                    />
                  </td>
                )}
                <td>
                  <div style={{ fontWeight: 600 }}>{item.ad || item.ad_soyad || item.baslik || item.guzergah || 'İsimsiz'}</div>
                  <div className="text-muted" style={{ fontSize: '0.8rem' }}>
                    {item.kategori && <span>{item.kategori} - </span>}
                    {/* Format firestore timestamps if present */}
                    {item.tarih?.toDate ? format(item.tarih.toDate(), 'dd.MM.yyyy HH:mm') + ' - ' : ''}
                    {item.expiry_date && (
                      <span className="text-danger" style={{ fontWeight: 600 }}>
                         - Bitiş: {item.expiry_date.toDate ? format(item.expiry_date.toDate(), 'dd.MM.yyyy') : item.expiry_date}
                      </span>
                    )}
                    {item.email || item.konum || item.hakkinda?.substring(0, 50)}...
                  </div>
                </td>
                <td style={{ minWidth: '120px' }}>
                  {collectionId === 'yardim_destek' && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <label className="switch">
                        <input 
                          type="checkbox" 
                          checked={item.durum === 'Çözüldü'} 
                          onChange={async (e) => {
                            const newStatus = e.target.checked ? 'Çözüldü' : 'Bekliyor';
                            await updateDoc(doc(db, collectionId, item.id), { durum: newStatus });
                          }}
                        />
                        <span className="slider"></span>
                      </label>
                      <span style={{ fontSize: '0.75rem', fontWeight: 600, color: item.durum === 'Çözüldü' ? '#22c55e' : '#f59e0b' }}>
                        {item.durum || 'Bekliyor'}
                      </span>
                    </div>
                  )}
                </td>
                <td style={{ display: 'flex', gap: '0.5rem' }}>
                  <button className="btn btn-outline" style={{ padding: '0.5rem' }} onClick={() => handleOpenModal(item)}>
                    <Edit size={16} />
                  </button>
                  <button className="btn btn-danger" style={{ padding: '0.5rem' }} onClick={() => handleDelete(item.id, item.image_url)}>
                    <Trash2 size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {loading && (
          <div style={{ padding: '2rem', textAlign: 'center' }}>
            <Loader2 className="spin" />
            <p>Yükleniyor...</p>
          </div>
        )}
      </div>

      {showModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="header" style={{ marginBottom: '1.5rem' }}>
              <h2>{editingItem ? 'Düzenle' : 'Yeni Ekle'}</h2>
              <button className="btn btn-outline" style={{ padding: '0.25rem' }} onClick={() => setShowModal(false)}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              {config.bucket && (
                <div className="form-group">
                  <label className="label">Görsel</label>
                  <div className="img-preview" onClick={() => document.getElementById('fileInput')?.click()}>
                    {selectedFile ? (
                      <img src={URL.createObjectURL(selectedFile)} alt="Preview" />
                    ) : formData.image_url ? (
                      <img src={formData.image_url} alt="Current" />
                    ) : (
                      <div style={{ textAlign: 'center' }}>
                        <Upload size={32} style={{ marginBottom: '0.5rem' }} />
                        <div>Resim Seç</div>
                      </div>
                    )}
                  </div>
                  <input 
                    type="file" 
                    id="fileInput" 
                    style={{ display: 'none' }} 
                    accept="image/*"
                    onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
                  />
                </div>
              )}

              {config.fields.map(field => (
                <div className="form-group" key={field.key}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                    <label className="label" style={{ marginBottom: 0 }}>{field.label}</label>
                    {field.key === 'expiry_date' && (
                      <label style={{ fontSize: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.25rem', cursor: 'pointer', color: 'var(--text-muted)' }}>
                        <input 
                          type="checkbox" 
                          checked={!formData[field.key]} 
                          onChange={(e) => {
                            if (e.target.checked) {
                              setFormData({ ...formData, [field.key]: null });
                            } else {
                              setFormData({ ...formData, [field.key]: Timestamp.now() });
                            }
                          }} 
                        />
                        Sınırsız
                      </label>
                    )}
                  </div>
                  
                  {field.isCompanyPicker ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                      <input 
                        className="input"
                        placeholder="Firma ara..."
                        value={companySearch}
                        onChange={(e) => setCompanySearch(e.target.value)}
                        style={{ padding: '0.4rem', fontSize: '0.8rem' }}
                      />
                      <select 
                        className="input"
                        value={formData[field.key] || ''}
                        onChange={(e) => setFormData({ ...formData, [field.key]: e.target.value })}
                        disabled={!companies.length}
                      >
                        <option value="">Firma Seçin (Boş Bırakılabilir)</option>
                        {companies
                          .filter(c => c.ad.toLowerCase().includes(companySearch.toLowerCase()))
                          .map(c => (
                            <option key={c.id} value={c.id}>{c.ad}</option>
                          ))
                        }
                      </select>
                      {formData[field.key] && (
                        <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                          Seçili ID: {formData[field.key]}
                        </div>
                      )}
                    </div>
                  ) : field.multiline ? (
                    <textarea 
                      className="input" 
                      rows={4}
                      value={formData[field.key] || ''}
                      onChange={(e) => setFormData({ ...formData, [field.key]: e.target.value })}
                    />
                  ) : (
                    <input 
                      className="input"
                      type={field.isDate ? 'date' : field.isTime ? 'time' : field.isNumber ? 'number' : 'text'}
                      value={(() => {
                        const val = formData[field.key];
                        if (field.isDate && val && typeof val === 'object' && val.seconds) {
                          return new Date(val.seconds * 1000).toISOString().split('T')[0];
                        }
                        return val || '';
                      })()}
                      onChange={(e) => setFormData({ ...formData, [field.key]: e.target.value })}
                      disabled={field.key === 'expiry_date' && !formData[field.key]}
                    />
                  )}
                </div>
              ))}

              <button className="btn btn-primary" style={{ width: '100%' }} disabled={uploading}>
                {uploading ? <Loader2 className="spin" size={20} /> : (editingItem ? 'Güncelle' : 'Ekle')}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default ManageCollection;
