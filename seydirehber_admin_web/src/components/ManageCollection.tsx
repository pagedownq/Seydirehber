import React, { useState, useEffect } from 'react';
import { db } from '../lib/firebase';
import { supabase } from '../lib/supabase';
import { 
  collection, 
  query, 
  orderBy, 
  onSnapshot, 
  addDoc, 
  setDoc,
  updateDoc, 
  deleteDoc, 
  doc, 
  serverTimestamp,
  Timestamp 
} from 'firebase/firestore';
import { Plus, Trash2, Edit, X, Loader2, Search, GripVertical } from 'lucide-react';
import { 
  DndContext, 
  closestCenter, 
  KeyboardSensor, 
  PointerSensor, 
  useSensor, 
  useSensors, 
  type DragEndEvent 
} from '@dnd-kit/core';
import { 
  arrayMove, 
  SortableContext, 
  sortableKeyboardCoordinates, 
  verticalListSortingStrategy,
  useSortable
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
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
  const [selectedCompanyId, setSelectedCompanyId] = useState<string>('');

  useEffect(() => {
    // We always want to fetch companies for filtering and picking
    const q = query(collection(db, 'firmalar'), orderBy('ad'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setCompanies(snapshot.docs.map(doc => ({ id: doc.id, ad: doc.data().ad })));
    });
    return unsubscribe;
  }, []);

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  useEffect(() => {
    setLoading(true);
    // Determine sort field based on collection type
    // If it's firmalar, we use 'order', then 'ad'
    let q = query(collection(db, collectionId));
    
    // Sort logic will be applied locally on the fetched items
    const unsubscribe = onSnapshot(q, (snapshot) => {
      let docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() as any }));
      
      // Perform manual sorting for specific collections
      if (collectionId === 'firmalar' || collectionId === 'banners' || collectionId === 'gezilecek_yerler') {
        docs.sort((a, b) => {
          const aOrder = a.order ?? 999999;
          const bOrder = b.order ?? 999999;
          if (aOrder !== bOrder) return aOrder - bOrder;
          // Use 'ad' (name) as secondary sort for deterministic order
          return (a.ad || '').toLowerCase().localeCompare((b.ad || '').toLowerCase(), undefined, { sensitivity: 'base' });
        });
      } else {
        // Fallback sorts for other collections
        const sortField = collectionId === 'yardim_destek' ? 'tarih' : 
                          collectionId === 'reviews' ? 'createdAt' : 'created_at';
        docs.sort((a, b) => {
          const aVal = a[sortField];
          const bVal = b[sortField];
          if (!aVal) return 1;
          if (!bVal) return -1;
          return bVal - aVal; // Descending
        });
      }
      
      setItems(docs);
      setLoading(false);
    }, (error) => {
      console.error('Firestore Error:', error);
      // Fallback
      const qFallback = query(collection(db, collectionId));
      onSnapshot(qFallback, (snapshot) => {
        setItems(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        setLoading(false);
      });
    });
    return unsubscribe;
  }, [collectionId]);

  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = items.findIndex((item) => item.id === active.id);
    const newIndex = items.findIndex((item) => item.id === over.id);

    const newItems = arrayMove(items, oldIndex, newIndex);
    setItems(newItems);

    // Update orders in Firestore using a batch for performance
    try {
      const { writeBatch } = await import('firebase/firestore');
      const batch = writeBatch(db);
      for (let i = 0; i < newItems.length; i++) {
        const item = newItems[i];
        if (item.order !== i) {
          batch.update(doc(db, collectionId, item.id), { order: i });
        }
      }
      await batch.commit();
    } catch (err) {
      console.error('Error updating order:', err);
    }
  };

  const handleOpenModal = (item?: any) => {
    if (item) {
      setEditingItem(item);
      setFormData(item);
    } else {
      setEditingItem(null);
      // Set defaults for new items
      const defaults: any = {};
      if (collectionId === 'coupons') {
        defaults.isActive = true;
      }
      setFormData(defaults);
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
        if (f.isBoolean) {
          cleanData[f.key] = !!cleanData[f.key];
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
        // Set order to last if it's a reorderable collection
        if (collectionId === 'firmalar' || collectionId === 'banners' || collectionId === 'gezilecek_yerler') {
            const existingOrders = items.map(i => i.order).filter(o => typeof o === 'number');
            const maxOrder = existingOrders.length > 0 ? Math.max(...existingOrders) : -1;
            cleanData.order = maxOrder + 1;
        }

        if (collectionId === 'admins') {
          // Use email as document ID for admins to match security rules
          const email = cleanData.email?.toLowerCase().trim();
          if (!email) throw new Error('Email gereklidir');
          
          await setDoc(doc(db, 'admins', email), cleanData);
        } else {
          await addDoc(collection(db, collectionId), cleanData);
        }
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

  const filteredItems = items.filter(item => {
    const matchesSearch = Object.values(item).some(val => 
      String(val).toLowerCase().includes(searchTerm.toLowerCase())
    );
    const matchesFirm = !selectedCompanyId || item.companyId === selectedCompanyId;
    return matchesSearch && matchesFirm;
  });

  return (
    <div className="collection-view">
      <div className="header">
        <div>
          <h1>{config.title}</h1>
          <p className="text-muted">{items.length} kayıt bulundu</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
          {config.fields.some(f => f.isCompanyPicker) && (
            <select 
              className="input" 
              style={{ width: '200px', fontSize: '0.85rem' }}
              value={selectedCompanyId}
              onChange={(e) => setSelectedCompanyId(e.target.value)}
            >
              <option value="">Tüm Firmalar</option>
              {companies.map(c => (
                <option key={c.id} value={c.id}>{c.ad}</option>
              ))}
            </select>
          )}
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
        <DndContext 
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragEnd={handleDragEnd}
        >
          <table className="table">
            <thead>
              <tr>
                {(collectionId === 'firmalar' || collectionId === 'banners' || collectionId === 'gezilecek_yerler') && <th style={{ width: '40px' }}></th>}
                {config.bucket && <th>Görsel</th>}
                <th>Bilgi / İçerik</th>
                {collectionId === 'yardim_destek' && <th>Durum</th>}
                <th>İşlem</th>
              </tr>
            </thead>
            <SortableContext 
              items={filteredItems.map(i => i.id)} 
              strategy={verticalListSortingStrategy}
              disabled={collectionId !== 'firmalar' && collectionId !== 'banners' && collectionId !== 'gezilecek_yerler'}
            >
              <tbody>
                {filteredItems.map((item) => (
                    <SortableRow 
                        key={item.id} 
                        item={item} 
                        collectionId={collectionId} 
                        config={config} 
                        isDraggable={(collectionId === 'firmalar' || collectionId === 'banners' || collectionId === 'gezilecek_yerler') && searchTerm === ''} // Disable drag if searching
                        handleOpenModal={handleOpenModal}
                        handleDelete={handleDelete}
                    />
                ))}
              </tbody>
            </SortableContext>
          </table>
        </DndContext>
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
                         <img src="/assets/fotoyok.png" alt="No image" style={{ width: '48px', height: '48px', marginBottom: '0.5rem', opacity: 0.5 }} />
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
                        onChange={(e) => {
                          const val = e.target.value;
                          const updates: any = { [field.key]: val };
                          if ((collectionId === 'coupons' || collectionId === 'esnaf_users') && field.key === 'companyId') {
                            const company = companies.find(c => c.id === val);
                            if (company) updates.companyName = company.ad;
                          }
                          setFormData({ ...formData, ...updates });
                        }}
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
                  ) : field.isBoolean ? (
                    <div>
                      <label className="switch">
                        <input 
                          type="checkbox" 
                          checked={formData[field.key] || false}
                          onChange={(e) => setFormData({ ...formData, [field.key]: e.target.checked })}
                        />
                        <span className="slider"></span>
                      </label>
                    </div>
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

const SortableRow = ({ item, collectionId, config, isDraggable, handleOpenModal, handleDelete }: any) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: item.id, disabled: !isDraggable });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
    background: isDragging ? 'var(--glass-bg)' : 'transparent',
    zIndex: isDragging ? 2 : 1,
    position: 'relative' as any,
    borderBottom: '1px solid var(--border)'
  };

  return (
    <tr ref={setNodeRef} style={style}>
      {(collectionId === 'firmalar' || collectionId === 'banners' || collectionId === 'gezilecek_yerler') && (
        <td style={{ padding: '1rem', cursor: isDraggable ? 'grab' : 'default' }} {...attributes} {...listeners}>
          <GripVertical size={20} style={{ color: 'var(--text-muted)' }} />
        </td>
      )}
      {config.bucket && (
        <td style={{ padding: '1rem' }}>
          <img 
            src={item.image_url || item.gorsel || '/assets/fotoyok.png'} 
            alt="" 
            style={{ width: 56, height: 56, borderRadius: 12, objectFit: 'cover', border: '1px solid var(--border)' }}
          />
        </td>
      )}
      <td style={{ padding: '1.25rem' }}>
        <div style={{ fontWeight: 700, fontSize: '1.1rem', marginBottom: '0.25rem', color: 'var(--text)' }}>
          {item.ad || item.title || item.baslik || item.ad_soyad || item.companyName || item.userName || item.username || item.guzergah || 'İsimsiz'}
          {item.rating && <span style={{ color: '#f59e0b', marginLeft: '0.75rem', fontSize: '0.9rem' }}>★ {item.rating}</span>}
          {item.order !== undefined && <span style={{ color: 'var(--text-muted)', marginLeft: '0.75rem', fontSize: '0.8rem', fontWeight: 400 }}>(Sıra: {item.order})</span>}
        </div>
        
        <div style={{ display: 'flex', gap: '0.75rem', fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.75rem', flexWrap: 'wrap' }}>
          {item.kategori && <span style={{ background: 'var(--glass-bg)', padding: '2px 8px', borderRadius: '4px' }}>{item.kategori}</span>}
          {item.tarih?.toDate && (
            <span><i className="bi bi-clock me-1"></i> {format(item.tarih.toDate(), 'dd.MM.yyyy HH:mm')}</span>
          )}
          {item.createdAt?.toDate && (
            <span><i className="bi bi-calendar3 me-1"></i> {format(item.createdAt.toDate(), 'dd.MM.yyyy HH:mm')}</span>
          )}
        </div>

        {/* Specialized Information Display */}
        {(collectionId === 'yardim_destek' || collectionId === 'reviews' || collectionId === 'coupons') && (
          <div style={{ 
            background: 'rgba(15, 23, 42, 0.4)', 
            padding: '1rem', 
            borderRadius: '12px', 
            border: '1px solid var(--border)',
            marginTop: '0.5rem'
          }}>
            {collectionId === 'yardim_destek' && (
              <>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', marginBottom: '0.5rem', fontSize: '0.85rem' }}>
                  {item.email && (
                    <span style={{ color: 'var(--text-muted)' }}>
                      <strong style={{ color: 'var(--text)' }}>E-posta:</strong> {item.email}
                    </span>
                  )}
                  {item.telefon && (
                    <span style={{ color: 'var(--text-muted)' }}>
                      <strong style={{ color: 'var(--text)' }}>Tel No:</strong> {item.telefon}
                    </span>
                  )}
                </div>
                <div style={{ fontSize: '0.9rem', color: 'var(--text)', lineHeight: '1.5' }}>
                  <strong style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.75rem', textTransform: 'uppercase', marginBottom: '4px' }}>Mesaj:</strong>
                  {item.mesaj}
                </div>
              </>
            )}
            {collectionId === 'reviews' && (
              <div style={{ fontSize: '0.9rem', color: 'var(--text)', lineHeight: '1.5' }}>
                 <strong style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.75rem', textTransform: 'uppercase', marginBottom: '4px' }}>Yorum:</strong>
                 "{item.comment}"
              </div>
            )}
            {collectionId === 'coupons' && (
              <>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', marginBottom: '0.5rem', fontSize: '0.85rem' }}>
                  {item.companyName && (
                    <span style={{ color: 'var(--text-muted)' }}>
                      <strong style={{ color: 'var(--text)' }}>Firma:</strong> {item.companyName}
                    </span>
                  )}
                  <span style={{ color: item.isActive ? '#22c55e' : '#ef4444' }}>
                    <strong>{item.isActive ? '✅ AKTIF' : '❌ PASIF'}</strong>
                  </span>
                  {item.expiry_date?.toDate && (
                    <span style={{ color: 'var(--text-muted)' }}>
                      <strong style={{ color: 'var(--text)' }}>Bitiş:</strong> {format(item.expiry_date.toDate(), 'dd.MM.yyyy')}
                    </span>
                  )}
                  {item.total_limit && (
                    <span style={{ color: 'var(--text-muted)' }}>
                      <strong style={{ color: 'var(--text)' }}>Limit:</strong> {item.used_count || 0} / {item.total_limit}
                    </span>
                  )}
                </div>
                {item.description && (
                  <div style={{ fontSize: '0.9rem', color: 'var(--text)', lineHeight: '1.5' }}>
                    <strong style={{ color: 'var(--text-muted)', display: 'block', fontSize: '0.75rem', textTransform: 'uppercase', marginBottom: '4px' }}>Kupon Detayı:</strong>
                    {item.description}
                  </div>
                )}
              </>
            )}
          </div>
        )}

        {!(collectionId === 'yardim_destek' || collectionId === 'reviews' || collectionId === 'coupons') && (
          <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
            {(item.hakkinda || item.konum || '')?.substring(0, 100)}...
          </div>
        )}
      </td>
        {collectionId === 'yardim_destek' && (
          <td style={{ padding: '1rem' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', minWidth: '100px' }}>
              <span style={{ 
                fontSize: '0.65rem', 
                fontWeight: 800, 
                color: item.durum === 'Çözüldü' ? '#22c55e' : '#f59e0b',
                background: item.durum === 'Çözüldü' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                padding: '2px 8px',
                borderRadius: '50px',
                textAlign: 'center',
                border: `1px solid ${item.durum === 'Çözüldü' ? 'rgba(34, 197, 94, 0.2)' : 'rgba(245, 158, 11, 0.2)'}`
              }}>
                {item.durum?.toUpperCase() || 'BEKLIYOR'}
              </span>
              <label className="switch" style={{ alignSelf: 'center' }}>
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
            </div>
          </td>
        )}
      <td style={{ padding: '1rem' }}>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn btn-outline" style={{ padding: '0.5rem', borderRadius: '50%', width: '36px', height: '36px', justifyContent: 'center' }} onClick={() => handleOpenModal(item)}>
            <Edit size={16} />
          </button>
          <button className="btn btn-danger" style={{ padding: '0.5rem', borderRadius: '50%', width: '36px', height: '36px', justifyContent: 'center' }} onClick={() => handleDelete(item.id, item.image_url)}>
            <Trash2 size={16} />
          </button>
        </div>
      </td>
    </tr>
  );
};

export default ManageCollection;
