import { useState, useEffect } from "react";
import { db } from "./lib/firebase";
import { 
  getDocs, 
  collection, 
  query, 
  where, 
  Timestamp, 
  runTransaction, 
  doc, 
  increment, 
  onSnapshot,
  orderBy,
  limit
} from "firebase/firestore";
import type { QuerySnapshot, DocumentData } from "firebase/firestore";
import { KeyRound, LogOut, AlertCircle, BarChart3, RefreshCw, Ticket, CheckCircle2, User, Building2, Phone, MessageCircle } from "lucide-react";

function App() {
  const [userId, setUserId] = useState<string | null>(null);
  const [companyId, setCompanyId] = useState<string | null>(null);
  const [companyName, setCompanyName] = useState("");
  
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [loginError, setLoginError] = useState("");

  const [couponCode, setCouponCode] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [verifyStatus, setVerifyStatus] = useState<{type: 'success' | 'error', msg: string} | null>(null);

  const [activeTab, setActiveTab] = useState<'dashboard' | 'coupons' | 'support'>('dashboard');
  const [coupons, setCoupons] = useState<any[]>([]);
  const [stats, setStats] = useState<{
    totalUsed: number,
    dailyTrend: Array<{date: string, count: number}>,
    recentUses: Array<{id: string, code: string, usedAt: Date, couponTitle: string}>
  } | null>(null);
  const [isStatsLoading, setIsStatsLoading] = useState(false);

  useEffect(() => {
    let unsub: (() => void) | undefined;
    
    if (companyId) {
      const unsubCompany = fetchCompanyName(companyId, (exists) => {
        if (!exists) {
          console.log("Firma silindi, oturum kapatılıyor...");
          handleLogout();
        }
      });
      const unsubStats = fetchStats(companyId);
      const unsubCoupons = fetchCoupons(companyId);
      unsub = () => {
        unsubCompany();
        unsubStats();
        unsubCoupons();
      };
    } else {
      setStats(null);
      setCoupons([]);
      setCompanyName("");
    }

    return () => {
      if (unsub) unsub();
    };
  }, [companyId]);

  // Admin hesabı silerse çıkış yapmasını sağlayan listener
  useEffect(() => {
    if (!userId) return;

    const userDocRef = doc(db, "esnaf_users", userId);
    const unsubscribe = onSnapshot(userDocRef, (snapshot) => {
      if (!snapshot.exists()) {
        console.log("Hesap silindi, oturum kapatılıyor...");
        handleLogout();
      }
    });

    return () => unsubscribe();
  }, [userId]);

  useEffect(() => {
    const storedUser = localStorage.getItem("esnaf_user_id");
    const storedFirma = localStorage.getItem("esnaf_firma_id");
    
    if (storedUser && storedFirma) {
      setUserId(storedUser);
      setCompanyId(storedFirma);
    }
  }, []);

  const fetchCoupons = (fId: string) => {
    if (!fId) return () => {};
    const q = query(collection(db, "coupons"), where("companyId", "==", fId));
    return onSnapshot(q, 
      (snapshot) => {
        setCoupons(snapshot.docs.map(d => ({
          id: d.id,
          ...d.data()
        })));
      },
      (error) => {
        console.error("fetchCoupons error:", error);
      }
    );
  };

  const fetchStats = (fId: string) => {
    if (!fId) return () => {};
    setIsStatsLoading(true);
    
    const q = query(
      collection(db, "generated_codes"),
      where("companyId", "==", fId),
      where("status", "==", "used"),
      orderBy("usedAt", "desc"),
      limit(100)
    );

    return onSnapshot(q, 
      (snapshot) => {
        try {
          const dailyTrend: Record<string, number> = {};
          const now = new Date();
          const last7Days = Array.from({length: 7}, (_, i) => {
            const d = new Date();
            d.setDate(now.getDate() - i);
            return d.toLocaleDateString('tr-TR');
          }).reverse();

          snapshot.docs.forEach((d: any) => {
            const data = d.data();
            if (data.usedAt) {
              const dateStr = data.usedAt.toDate().toLocaleDateString('tr-TR');
              if (last7Days.includes(dateStr)) {
                dailyTrend[dateStr] = (dailyTrend[dateStr] || 0) + 1;
              }
            }
          });

          setStats({
            totalUsed: snapshot.size,
            dailyTrend: last7Days.map(date => ({ date, count: dailyTrend[date] || 0 })),
            recentUses: snapshot.docs.slice(0, 10).map(d => ({
              id: d.id,
              code: d.data().code,
              usedAt: d.data().usedAt?.toDate(),
              couponTitle: d.data().couponTitle || "Kupon"
            }))
          });
        } catch (err) {
          console.error("Stats processing error:", err);
        } finally {
          setIsStatsLoading(false);
        }
      },
      (error) => {
        console.error("fetchStats error:", error);
        setIsStatsLoading(false);
      }
    );
  };

  const fetchCompanyName = (fId: string, onUpdate?: (exists: boolean) => void) => {
    if (!fId) return () => {};
    const docRef = doc(db, "firmalar", fId);
    return onSnapshot(docRef, (snapshot) => {
      if (snapshot.exists()) {
        setCompanyName(snapshot.data().ad || "");
        onUpdate?.(true);
      } else {
        onUpdate?.(false);
      }
    }, (err) => {
      console.error("Firma adı dinlenirken hata:", err);
    });
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoggingIn(true);
    setLoginError("");
    try {
      const q = query(
        collection(db, "esnaf_users"), 
        where("username", "==", email),
        where("password", "==", password)
      );
      const snapshot = await getDocs(q);
      
      if (snapshot.empty) {
        setLoginError("Kullanıcı adı veya şifre hatalı.");
      } else {
        const docSnap = snapshot.docs[0];
        const data = docSnap.data();
        
        localStorage.setItem("esnaf_user_id", docSnap.id);
        localStorage.setItem("esnaf_firma_id", data.companyId || "");
        
        setUserId(docSnap.id);
        setCompanyId(data.companyId || null);
        fetchCompanyName(data.companyId || "");
      }
    } catch (err: any) {
      setLoginError("Sunucuya bağlanılamadı. Lütfen tekrar deneyin.");
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem("esnaf_user_id");
    localStorage.removeItem("esnaf_firma_id");
    setUserId(null);
    setCompanyId(null);
    setCompanyName("");
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!companyId || couponCode.length !== 6) return;
    
    setIsVerifying(true);
    setVerifyStatus(null);
    try {
      const q = query(
        collection(db, "generated_codes"),
        where("code", "==", couponCode.toUpperCase()),
        where("companyId", "==", companyId)
      );
      
      const res = await getDocs(q);
      const docs = res.docs.filter(doc => {
        const data = doc.data();
        return data.status === "pending" && data.expiresAt.toMillis() > Date.now();
      });
      
      if (docs.length === 0) {
        setVerifyStatus({type: 'error', msg: "Geçersiz, süresi dolmuş veya başka bir firmaya ait kupon."});
        return;
      }

      // We found the coupon! Use transaction to mark it used.
      const docRef = docs[0].ref;
      
      await runTransaction(db, async (transaction) => {
        const freshDoc = await transaction.get(docRef);
        const data = freshDoc.data() as any;
        if (!freshDoc.exists() || data?.status !== 'pending') {
          throw new Error("Kupon zaten kullanılmış veya iptal edilmiş.");
        }
        
        const couponDocRef = doc(db, "coupons", data.couponId);
        
        transaction.update(docRef, {
          status: "used",
          usedAt: Timestamp.now()
        });

        transaction.update(couponDocRef, {
          used_count: increment(1)
        });
      });
      
      setVerifyStatus({type: 'success', msg: "Kupon başarıyla doğrulandı!"});
      setCouponCode("");
      // No need to call fetchStats manually, the onSnapshot will handle real-time updates
    } catch (err: any) {
      setVerifyStatus({type: 'error', msg: err.message || "Bir hata oluştu."});
    } finally {
      setIsVerifying(false);
    }
  };

  if (userId === null) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8fafc] p-4 relative overflow-hidden font-sans">
        {/* Abstract background shapes */}
        <div className="absolute top-[-20%] left-[-10%] w-[60%] h-[60%] bg-indigo-100/40 rounded-full blur-[120px] animate-pulse" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[60%] h-[60%] bg-emerald-100/40 rounded-full blur-[120px] animate-pulse" style={{ animationDelay: '2s' }} />
        
        <div className="max-w-md w-full bg-white/80 backdrop-blur-2xl border border-white rounded-[2.5rem] shadow-[0_32px_64px_-16px_rgba(0,0,0,0.08)] p-10 relative z-10 transition-all duration-500 hover:shadow-[0_48px_80px_-24px_rgba(0,0,0,0.12)]">
          <div className="text-center mb-10">
            <div className="mx-auto h-24 w-24 bg-gradient-to-br from-indigo-600 to-violet-600 rounded-[2rem] flex items-center justify-center mb-8 shadow-2xl shadow-indigo-500/20 transform hover:scale-110 transition-transform duration-500">
              <Building2 className="h-10 w-10 text-white" />
            </div>
            <h1 className="text-3xl font-bold text-slate-900 tracking-tight">Esnaf Girişi</h1>
            <p className="text-slate-500 mt-3 text-sm font-medium">Seydi Rehber İşletme Yönetimi</p>
          </div>
          
          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <label className="block text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">Kullanıcı Adı</label>
              <div className="relative group">
                <input 
                  type="text" 
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  placeholder="isletme_adi"
                  className="block w-full bg-slate-50/50 rounded-2xl border border-slate-200 text-slate-900 px-5 py-4 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/5 transition-all outline-none placeholder:text-slate-300 font-medium" 
                  required 
                />
              </div>
            </div>
            <div className="space-y-2">
              <label className="block text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">Şifre</label>
              <div className="relative group">
                <input 
                  type="password" 
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="block w-full bg-slate-50/50 rounded-2xl border border-slate-200 text-slate-900 px-5 py-4 focus:bg-white focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/5 transition-all outline-none placeholder:text-slate-300 font-medium" 
                  required 
                />
              </div>
            </div>
            
            {loginError && (
              <div className="bg-rose-50 border border-emerald-100 p-4 rounded-2xl flex items-center text-rose-600 animate-in fade-in slide-in-from-top-2">
                <AlertCircle className="h-5 w-5 mr-3 flex-shrink-0" />
                <p className="text-sm font-semibold">{loginError}</p>
              </div>
            )}
            
            <button 
              type="submit" 
              disabled={isLoggingIn}
              className="w-full bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-700 hover:to-violet-700 disabled:from-slate-200 disabled:to-slate-200 text-white py-5 rounded-2xl font-bold text-lg shadow-xl shadow-indigo-500/20 disabled:shadow-none transition-all active:scale-[0.98] flex items-center justify-center gap-3"
            >
              {isLoggingIn ? (
                <RefreshCw className="h-6 w-6 animate-spin text-white/50" />
              ) : (
                "Sisteme Giriş Yap"
              )}
            </button>
          </form>
          
          <div className="mt-10 pt-8 border-t border-slate-50 flex flex-col items-center gap-4">
             <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em]">Destek ve İletişim</p>
             <div className="flex gap-4 w-full">
               <a 
                 href="https://wa.me/905456962060"
                 target="_blank"
                 rel="noopener noreferrer"
                 className="flex-1 flex items-center justify-center gap-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 p-4 rounded-2xl border border-emerald-100/50 transition-all font-bold text-xs"
               >
                 <MessageCircle className="h-4 w-4" />
                 WhatsApp
               </a>
               <a 
                 href="tel:+905456962060"
                 className="flex-1 flex items-center justify-center gap-2 bg-slate-50 hover:bg-slate-100 text-slate-600 p-4 rounded-2xl border border-slate-200/50 transition-all font-bold text-xs"
               >
                 <Phone className="h-4 w-4" />
                 Ara
               </a>
             </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f8fafc] text-slate-900 font-sans selection:bg-indigo-100 relative overflow-hidden">
      {/* Dynamic Background */}
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-indigo-200/20 rounded-full blur-[120px] animate-pulse" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-emerald-200/20 rounded-full blur-[120px] animate-pulse" style={{ animationDelay: '2s' }} />
      </div>

      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/70 backdrop-blur-xl border-b border-slate-200/50">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center max-w-7xl">
          <div className="flex items-center gap-4 group cursor-default">
            <div className="bg-gradient-to-br from-indigo-600 to-violet-600 p-2.5 rounded-2xl shadow-lg shadow-indigo-200 group-hover:scale-105 transition-transform duration-500">
              <Building2 className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight text-slate-900 leading-none drop-shadow-sm">
                {companyName || 'Yükleniyor...'}
              </h1>
              <div className="flex items-center gap-2 mt-1.5">
                <div className="flex items-center gap-1 px-2 py-0.5 bg-indigo-50 rounded-md">
                  <span className="w-1 h-1 bg-indigo-500 rounded-full animate-pulse" />
                  <p className="text-[9px] font-black text-indigo-600 uppercase tracking-[0.15em] leading-none">KURUMSAL PANEL</p>
                </div>
              </div>
            </div>
          </div>
          <button 
            onClick={handleLogout}
            className="flex items-center gap-2 px-5 py-2.5 text-sm font-bold text-slate-600 hover:text-red-600 hover:bg-red-50 rounded-xl transition-all duration-300 border border-transparent hover:border-red-100"
          >
            <LogOut className="w-4 h-4" />
            Çıkış Yap
          </button>
        </div>
      </header>

      <main className="container mx-auto px-4 py-10 relative z-10 max-w-7xl">
        {!companyId ? (
          <div className="bg-white/80 backdrop-blur-md border border-amber-100 p-8 rounded-[2.5rem] shadow-xl flex items-center gap-6 max-w-2xl mx-auto">
            <div className="p-4 bg-amber-50 rounded-2xl text-amber-500">
              <AlertCircle className="w-10 h-10" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-amber-900">Yetki Bekleniyor</h3>
              <p className="text-slate-600 font-medium">Hesabınıza atanmış bir firma bulunamadı. Lütfen yönetici ile iletişime geçin.</p>
            </div>
          </div>
        ) : (
          <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
            {/* Tabs Navigation */}
            <nav className="flex items-center gap-2 p-1.5 bg-white/50 backdrop-blur-sm rounded-3xl border border-white max-w-fit mx-auto lg:mx-0">
              <button 
                onClick={() => setActiveTab('dashboard')}
                className={`px-6 py-2.5 rounded-2xl text-xs font-bold transition-all duration-300 flex items-center gap-2 ${activeTab === 'dashboard' ? 'bg-white text-indigo-600 shadow-md' : 'text-slate-400 hover:text-slate-600'}`}
              >
                <BarChart3 className="w-4 h-4" /> Panel
              </button>
              <button 
                onClick={() => setActiveTab('coupons')}
                className={`px-6 py-2.5 rounded-2xl text-xs font-bold transition-all duration-300 flex items-center gap-2 ${activeTab === 'coupons' ? 'bg-white text-indigo-600 shadow-md' : 'text-slate-400 hover:text-slate-600'}`}
              >
                <Ticket className="w-4 h-4" /> Kuponlarım
              </button>
              <button 
                onClick={() => setActiveTab('support')}
                className={`px-6 py-2.5 rounded-2xl text-xs font-bold transition-all duration-300 flex items-center gap-2 ${activeTab === 'support' ? 'bg-white text-indigo-600 shadow-md' : 'text-slate-400 hover:text-slate-600'}`}
              >
                <MessageCircle className="w-4 h-4" /> Destek
              </button>
            </nav>

            {activeTab === 'dashboard' && (
              <div className="grid lg:grid-cols-3 gap-10">
                {/* Left Column: Verification */}
                <div className="lg:col-span-2 space-y-10">
                  <section className="bg-white/80 backdrop-blur-md rounded-[2.5rem] p-10 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white hover:shadow-[0_8px_40px_rgb(0,0,0,0.08)] transition-all duration-700 group">
                    <div className="flex items-center gap-5 mb-10">
                      <div className="p-4 bg-indigo-50 rounded-[1.5rem] text-indigo-600 group-hover:rotate-6 transition-transform duration-500">
                        <KeyRound className="w-8 h-8" />
                      </div>
                      <div>
                        <h2 className="text-2xl font-bold text-slate-900">Kupon Doğrulama</h2>
                        <p className="text-slate-500 font-medium">Müşterinin getirdiği 6 haneli kodu buraya girerek doğrulayın.</p>
                      </div>
                    </div>

                    <form onSubmit={handleVerify} className="space-y-8">
                      <div className="relative group/input">
                        <input
                          type="text"
                          value={couponCode}
                          onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                          placeholder="• • • • • •"
                          maxLength={6}
                          className="w-full text-center text-6xl font-black tracking-[0.3em] py-10 rounded-[2rem] border-2 border-slate-100 bg-slate-50/30 hover:bg-white focus:bg-white focus:border-indigo-500 focus:ring-8 focus:ring-indigo-500/5 outline-none transition-all duration-500 placeholder:text-slate-200"
                        />
                      </div>

                      <button
                        type="submit"
                        disabled={isVerifying || couponCode.length !== 6}
                        className="w-full bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-700 hover:to-violet-700 disabled:from-slate-200 disabled:to-slate-200 text-white py-6 rounded-[1.75rem] font-bold text-xl shadow-2xl shadow-indigo-500/20 disabled:shadow-none transition-all duration-300 active:scale-[0.98] flex items-center justify-center gap-4 group/btn"
                      >
                        {isVerifying ? (
                          <RefreshCw className="w-8 h-8 animate-spin" />
                        ) : (
                          <>
                            <CheckCircle2 className="w-8 h-8 group-hover/btn:scale-110 transition-transform" />
                            Doğrula ve Kuponu Kullan
                          </>
                        )}
                      </button>

                      {verifyStatus && (
                        <div className={`flex items-center gap-4 p-6 rounded-[1.5rem] border animate-shake ${
                          verifyStatus.type === 'success' 
                            ? 'bg-emerald-50 border-emerald-100 text-emerald-800' 
                            : 'bg-rose-50 border-rose-100 text-rose-800'
                        }`}>
                          {verifyStatus.type === 'success' ? <CheckCircle2 className="w-6 h-6 flex-shrink-0" /> : <AlertCircle className="w-6 h-6 flex-shrink-0" />}
                          <p className="text-sm font-bold uppercase tracking-wide">{verifyStatus.msg}</p>
                        </div>
                      )}
                    </form>

                    <div className="mt-8 flex items-center justify-center gap-2 text-slate-400">
                      <Ticket className="w-4 h-4" />
                      <p className="text-[10px] font-bold uppercase tracking-widest">Her kupon tek kullanımlıktır ve geri alınamaz</p>
                    </div>
                  </section>
                </div>

                <div className="space-y-10">
                  <section className="bg-white/80 backdrop-blur-md rounded-[2.5rem] p-8 shadow-sm border border-white">
                    <div className="flex items-center justify-between mb-8">
                      <div className="flex items-center gap-3">
                        <div className="p-3 bg-emerald-50 rounded-2xl text-emerald-600">
                          <BarChart3 className="w-6 h-6" />
                        </div>
                        <h2 className="text-xl font-bold text-slate-900">Raporlar</h2>
                      </div>
                      <div className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-100 text-emerald-700 text-[10px] font-black uppercase tracking-widest rounded-full">
                        {isStatsLoading ? <RefreshCw className="w-3 h-3 animate-spin mr-1" /> : <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" />}
                        CANLI
                      </div>
                    </div>

                    <div className="space-y-10">
                      <div className="grid grid-cols-2 gap-4">
                        <div className="p-5 bg-slate-50/50 rounded-2xl border border-slate-100/50">
                          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Toplam</p>
                          <p className="text-2xl font-black text-slate-900">{stats?.totalUsed || 0}</p>
                        </div>
                        <div className="p-5 bg-indigo-50/50 rounded-2xl border border-indigo-100/30">
                          <p className="text-[10px] font-bold text-indigo-400 uppercase tracking-widest mb-1">Yeni</p>
                          <p className="text-2xl font-black text-indigo-600">
                            {/* @ts-ignore */}
                            {stats?.dailyTrend?.reduce((acc: number, curr: any) => acc + curr.count, 0) || 0}
                          </p>
                        </div>
                      </div>

                      <div className="space-y-4">
                        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-[0.2em] px-2">
                           Son İşlemler
                        </h3>
                        <div className="space-y-3">
                          {stats?.recentUses?.map((use, idx) => (
                            <div key={idx} className="flex items-center gap-4 p-4 bg-slate-50/30 rounded-2xl border border-slate-100/30 group hover:bg-white hover:shadow-lg hover:shadow-slate-200/50 transition-all duration-300">
                              <div className="bg-white p-2 rounded-xl shadow-sm group-hover:bg-indigo-50 group-hover:text-indigo-600 transition-colors">
                                <CheckCircle2 className="w-4 h-4" />
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-xs font-bold text-slate-900 truncate">{use.couponTitle}</p>
                                <p className="text-[10px] text-slate-400 font-medium">
                                  {use.code} • {use.usedAt?.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
                                </p>
                              </div>
                            </div>
                          ))}
                          {(!stats?.recentUses || stats.recentUses.length === 0) && (
                             <p className="text-center py-6 text-[10px] font-bold text-slate-300 uppercase tracking-widest">İşlem Bulunmuyor</p>
                          )}
                        </div>
                      </div>
                    </div>
                  </section>
                </div>
              </div>
            )}

            {activeTab === 'coupons' && (
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {coupons.map((coupon, idx) => (
                    <div key={idx} className="bg-white/80 backdrop-blur-md rounded-[2rem] p-8 shadow-sm border border-white hover:shadow-[0_20px_40px_rgb(0,0,0,0.05)] transition-all duration-500 group">
                      <div className="flex justify-between items-start mb-6">
                        <div className="p-4 bg-indigo-50 rounded-2xl text-indigo-600 group-hover:scale-110 transition-transform duration-500">
                          <Ticket className="w-6 h-6" />
                        </div>
                        <span className="px-3 py-1 bg-emerald-50 text-emerald-600 text-[10px] font-black rounded-lg">
                          %{coupon.discountPercentage || coupon.discount_value || 0} İNDİRİM
                        </span>
                      </div>
                      <h3 className="text-lg font-bold text-slate-900 mb-2 truncate">{coupon.title}</h3>
                      <p className="text-sm text-slate-500 line-clamp-2 mb-6 font-medium leading-relaxed">{coupon.description}</p>
                      
                      <div className="pt-6 border-t border-slate-100 flex items-center justify-between">
                        <div>
                          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Toplam Kullanım</p>
                          <p className="text-xl font-black text-slate-900">{coupon.used_count || 0}</p>
                        </div>
                        {coupon.total_limit && (
                          <div className="text-right">
                             <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Limit</p>
                             <p className="text-sm font-bold text-slate-700">{coupon.used_count || 0} / {coupon.total_limit}</p>
                          </div>
                        )}
                        {!coupon.total_limit && (
                           <div className="text-right">
                             <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Durum</p>
                             <p className="text-sm font-bold text-emerald-500">Sınırsız İndirim</p>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                  {coupons.length === 0 && (
                    <div className="col-span-full py-20 text-center space-y-4">
                      <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto text-slate-300">
                        <Ticket className="w-10 h-10" />
                      </div>
                      <p className="text-slate-400 font-bold uppercase tracking-widest text-xs">Henüz bir kuponunuz bulunmuyor</p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {activeTab === 'support' && (
              <div className="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto">
                <div className="bg-slate-900 rounded-[2.5rem] p-10 text-white shadow-2xl relative overflow-hidden group border border-white/5">
                  <div className="absolute -top-4 -right-4 p-4 opacity-10 group-hover:scale-125 transition-transform duration-700">
                    <MessageCircle className="w-24 h-24" />
                  </div>
                  <h4 className="text-slate-400 text-xs font-black uppercase tracking-[0.2em] mb-4">Anında Çözüm</h4>
                  <h3 className="text-2xl font-bold mb-6">WhatsApp Destek Hattı</h3>
                  <p className="text-slate-400 mb-8 font-medium leading-relaxed">Sistemle ilgili tüm soru ve sorunlarınız için direct olarak ekibimize ulaşabilirsiniz.</p>
                  <a 
                    href="https://wa.me/905456962060" 
                    target="_blank"
                    className="inline-flex items-center gap-3 bg-emerald-500 hover:bg-emerald-600 px-8 py-4 rounded-2xl transition-all font-bold text-white shadow-[0_8px_25px_-4px_rgba(16,185,129,0.4)]"
                  >
                    Hemen Yazın <MessageCircle className="w-5 h-5" />
                  </a>
                </div>

                <div className="bg-gradient-to-br from-indigo-600 to-violet-600 rounded-[2.5rem] p-10 text-white shadow-2xl relative overflow-hidden group border border-white/10">
                  <div className="absolute -top-4 -right-4 p-4 opacity-10 group-hover:scale-125 transition-transform duration-700">
                    <User className="w-24 h-24" />
                  </div>
                  <h4 className="text-indigo-100/60 text-xs font-black uppercase tracking-[0.2em] mb-4">Kurumsal İletişim</h4>
                  <h3 className="text-2xl font-bold mb-6">Mail ile Bize Ulaşın</h3>
                  <p className="text-indigo-100/70 mb-8 font-medium leading-relaxed">Resmi evraklar veya daha detaylı talepleriniz için mail adresimizi kullanabilirsiniz.</p>
                  <a 
                    href="mailto:seydirehber@gmail.com" 
                    className="inline-flex items-center gap-3 bg-white/10 hover:bg-white/20 px-8 py-4 rounded-2xl backdrop-blur-md transition-all font-bold border border-white/20"
                  >
                    seydirehber@gmail.com <User className="w-5 h-5" />
                  </a>
                </div>
              </div>
            )}
          </div>
        )}
      </main>

      <style>{`
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-4px); }
          75% { transform: translateX(4px); }
        }
        .animate-shake { animation: shake 0.4s ease-in-out; }
        .custom-scrollbar::-webkit-scrollbar { width: 5px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.05); border-radius: 20px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(0,0,0,0.1); }
      `}</style>
    </div>
  );
}

export default App;
