import { useState, useEffect } from "react";
import { db } from "./lib/firebase";
import { getDocs, collection, query, where, Timestamp, runTransaction } from "firebase/firestore";
import { KeyRound, LogOut, AlertCircle, BarChart3, RefreshCw, Ticket, CheckCircle2, User, Building2, Phone, MessageCircle } from "lucide-react";

function App() {
  const [userId, setUserId] = useState<string | null>(null);
  const [companyId, setCompanyId] = useState<string | null>(null);
  const [usernameText, setUsernameText] = useState("");
  
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [loginError, setLoginError] = useState("");

  const [couponCode, setCouponCode] = useState("");
  const [isVerifying, setIsVerifying] = useState(false);
  const [verifyStatus, setVerifyStatus] = useState<{type: 'success' | 'error', msg: string} | null>(null);

  const [stats, setStats] = useState<{
    totalUsed: number,
    byCoupon: Array<{id: string, title: string, count: number}>
  } | null>(null);
  const [isStatsLoading, setIsStatsLoading] = useState(false);

  useEffect(() => {
    const storedUser = localStorage.getItem("esnaf_user_id");
    const storedFirma = localStorage.getItem("esnaf_firma_id");
    const storedName = localStorage.getItem("esnaf_username");
    
    if (storedUser && storedFirma) {
      setUserId(storedUser);
      setCompanyId(storedFirma);
      setUsernameText(storedName || "");
      fetchStats(storedFirma);
    }
  }, []);

  const fetchStats = async (fId: string) => {
    if (!fId) return;
    setIsStatsLoading(true);
    try {
      // 1. Fetch all coupons of this company
      const couponsQ = query(collection(db, "coupons"), where("companyId", "==", fId));
      const couponsSnap = await getDocs(couponsQ);
      const couponMap: Record<string, string> = {};
      couponsSnap.docs.forEach(d => {
        couponMap[d.id] = d.data().title || "İsimsiz Kupon";
      });

      // 2. Fetch all used codes
      const usedQ = query(
        collection(db, "generated_codes"),
        where("companyId", "==", fId),
        where("status", "==", "used")
      );
      const usedSnap = await getDocs(usedQ);
      
      const counts: Record<string, number> = {};
      usedSnap.docs.forEach(d => {
        const cId = d.data().couponId;
        counts[cId] = (counts[cId] || 0) + 1;
      });

      const byCouponArray = Object.entries(counts).map(([id, count]) => ({
        id,
        title: couponMap[id] || "Silinmiş Kupon",
        count
      })).sort((a, b) => b.count - a.count);

      setStats({
        totalUsed: usedSnap.size,
        byCoupon: byCouponArray
      });
    } catch (err) {
      console.error("Stats error:", err);
    } finally {
      setIsStatsLoading(false);
    }
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
        localStorage.setItem("esnaf_username", data.username || email);
        
        setUserId(docSnap.id);
        setCompanyId(data.companyId || null);
        setUsernameText(data.username || email);
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
    localStorage.removeItem("esnaf_username");
    setUserId(null);
    setCompanyId(null);
    setUsernameText("");
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
        
        transaction.update(docRef, {
          status: "used",
          usedAt: Timestamp.now()
        });
      });
      
      setVerifyStatus({type: 'success', msg: "Kupon başarıyla doğrulandı!"});
      setCouponCode("");
      fetchStats(companyId); // Refresh stats
    } catch (err: any) {
      setVerifyStatus({type: 'error', msg: err.message || "Bir hata oluştu."});
    } finally {
      setIsVerifying(false);
    }
  };

  if (userId === null) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#0f172a] p-4 relative overflow-hidden">
        {/* Decorative background elements */}
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-blue-600/10 rounded-full blur-[120px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-indigo-600/10 rounded-full blur-[120px]" />
        
        <div className="max-w-md w-full bg-slate-900 border border-white/5 rounded-[2rem] shadow-2xl p-10 relative z-10">
          <div className="text-center mb-10">
            <div className="mx-auto h-20 w-20 bg-gradient-to-tr from-blue-600 to-indigo-600 rounded-2xl flex items-center justify-center mb-6 shadow-xl shadow-blue-500/20">
              <Building2 className="h-10 w-10 text-white" />
            </div>
            <h1 className="text-3xl font-black text-white italic tracking-tight">ESNAF GİRİŞİ</h1>
            <p className="text-slate-500 mt-2 text-xs font-bold uppercase tracking-widest">Seydi Rehber İşletme Yönetimi</p>
          </div>
          
          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Kullanıcı Adı</label>
              <input 
                type="text" 
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="isletme_adi"
                className="block w-full bg-slate-800/50 rounded-xl border border-white/10 text-white p-4 focus:border-blue-500 focus:ring-0 transition-all placeholder:text-slate-600" 
                required 
              />
            </div>
            <div className="space-y-2">
              <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Şifre</label>
              <input 
                type="password" 
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                className="block w-full bg-slate-800/50 rounded-xl border border-white/10 text-white p-4 focus:border-blue-500 focus:ring-0 transition-all placeholder:text-slate-600" 
                required 
              />
            </div>
            
            {loginError && (
              <div className="bg-rose-500/10 border border-rose-500/20 p-3 rounded-lg flex items-center text-rose-400">
                <AlertCircle className="h-4 w-4 mr-2" />
                <p className="text-[11px] font-bold uppercase">{loginError}</p>
              </div>
            )}
            
            <button 
              type="submit" 
              disabled={isLoggingIn}
              className="w-full relative group overflow-hidden rounded-xl"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-600 transition-all group-hover:scale-105 active:scale-95" />
              <div className="relative py-4 px-4 text-sm font-black text-white uppercase tracking-[0.2em]">
                {isLoggingIn ? "Bağlanılıyor..." : "Sisteme Gir"}
              </div>
            </button>
          </form>
          
          <div className="mt-8 pt-8 border-t border-white/5 space-y-3">
             <p className="text-center text-[10px] text-slate-500 font-bold uppercase tracking-widest mb-4">
               DESTEK VE İLETİŞİM
             </p>
             <div className="grid grid-cols-2 gap-3">
               <a 
                 href="tel:+905456962060"
                 className="flex items-center justify-center space-x-2 bg-white/5 hover:bg-blue-500/10 text-slate-300 hover:text-blue-400 p-3 rounded-xl border border-white/5 transition-all text-xs font-bold"
               >
                 <Phone className="h-4 w-4" />
                 <span>Yöneticiyi Ara</span>
               </a>
               <a 
                 href="https://wa.me/905456962060"
                 target="_blank"
                 rel="noopener noreferrer"
                 className="flex items-center justify-center space-x-2 bg-emerald-500/5 hover:bg-emerald-500/10 text-slate-300 hover:text-emerald-400 p-3 rounded-xl border border-white/5 transition-all text-xs font-bold"
               >
                 <MessageCircle className="h-4 w-4" />
                 <span>WhatsApp</span>
               </a>
             </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0f172a] text-slate-200">
      {/* Navbar Upgrade */}
      <nav className="bg-slate-900/50 backdrop-blur-md border-b border-white/10 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-20">
            <div className="flex items-center space-x-3">
              <div className="h-10 w-10 bg-gradient-to-tr from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/20">
                <Building2 className="h-6 w-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-black bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">ESNAF PANELİ</h1>
                <p className="text-[10px] uppercase tracking-widest text-blue-400 font-bold">Seydi Rehber Pro</p>
              </div>
            </div>
            <div className="flex items-center space-x-6">
              <div className="hidden md:flex flex-col items-end">
                <span className="text-sm font-bold text-white flex items-center">
                  <User className="h-3 w-3 mr-1 text-blue-400" />
                  {usernameText}
                </span>
                <span className="text-[10px] text-slate-500 uppercase">İşletme Yetkilisi</span>
              </div>
              <button 
                onClick={handleLogout}
                className="group flex items-center space-x-2 bg-white/5 hover:bg-red-500/10 text-slate-400 hover:text-red-400 px-4 py-2 rounded-lg transition-all border border-white/5 hover:border-red-500/20"
              >
                <LogOut className="h-4 w-4 transform group-hover:-translate-x-1 transition-transform" />
                <span className="text-sm font-bold uppercase tracking-tight">Çıkış</span>
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-4xl mx-auto py-10 px-4 space-y-8">
        {!companyId ? (
          <div className="bg-amber-500/10 border-l-4 border-amber-500 p-6 rounded-2xl flex items-center space-x-4">
            <AlertCircle className="h-8 w-8 text-amber-500" />
            <div>
              <h3 className="text-amber-500 font-bold">Yetki Sorunu</h3>
              <p className="text-sm text-amber-200/70">Hesabınıza atanmış bir firma bulunamadı.</p>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Verification Form Card */}
            <div className="space-y-6">
              <div className="bg-slate-900 border border-white/5 rounded-3xl shadow-2xl shadow-blue-500/5 overflow-hidden">
                <div className="px-8 py-10">
                  <div className="flex flex-col items-center text-center mb-10">
                    <div className="h-20 w-20 bg-blue-600/10 rounded-2xl flex items-center justify-center mb-6 border border-blue-500/20">
                      <KeyRound className="h-10 w-10 text-blue-500" />
                    </div>
                    <h2 className="text-3xl font-black text-white italic">KUPON DOĞRULA</h2>
                    <p className="mt-2 text-slate-400 text-sm font-medium">6 haneli müşteri kodunu buraya giriniz</p>
                  </div>

                  <form onSubmit={handleVerify} className="space-y-8">
                    <div className="relative">
                      <input
                        type="text"
                        maxLength={6}
                        value={couponCode}
                        onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                        placeholder="______"
                        className="block w-full bg-slate-800/50 text-center text-5xl tracking-[0.5em] uppercase font-mono rounded-2xl border-2 border-white/10 text-white placeholder:text-slate-700 focus:border-blue-500 focus:ring-0 transition-all p-6 shadow-inner"
                        required
                      />
                      <div className="absolute inset-0 pointer-events-none rounded-2xl ring-1 ring-inset ring-white/5" />
                    </div>
                    
                    {verifyStatus && (
                      <div className={`p-4 rounded-xl flex items-center animate-in fade-in slide-in-from-top-2 duration-300 ${
                        verifyStatus.type === 'success' 
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' 
                          : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                      }`}>
                        {verifyStatus.type === 'success' ? <CheckCircle2 className="h-5 w-5 mr-3" /> : <AlertCircle className="h-5 w-5 mr-3" />}
                        <span className="text-[13px] font-bold uppercase tracking-wide">{verifyStatus.msg}</span>
                      </div>
                    )}
                    
                    <button
                      type="submit"
                      disabled={isVerifying || couponCode.length !== 6}
                      className="group relative w-full overflow-hidden"
                    >
                      <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-600 transition-all duration-300 group-hover:scale-105 group-active:scale-95" />
                      <div className="relative flex items-center justify-center py-5 rounded-2xl text-white font-black text-lg tracking-widest uppercase disabled:opacity-50 transition-all">
                        {isVerifying ? (
                          <RefreshCw className="h-6 w-6 animate-spin" />
                        ) : (
                          "ONAYLA VE KULLAN"
                        )}
                      </div>
                    </button>
                  </form>
                </div>
                
                <div className="bg-white/5 px-8 py-4 flex items-center justify-center space-x-2">
                  <Ticket className="h-4 w-4 text-slate-500" />
                  <p className="text-[11px] text-slate-500 font-bold uppercase tracking-tighter">
                    Her kupon tek kullanımlıktır • İşlem geri alınamaz
                  </p>
                </div>
              </div>
            </div>

            {/* Reporting Section Card */}
            <div className="space-y-6">
              <div className="bg-slate-900 border border-white/5 rounded-3xl shadow-2xl p-8 h-full">
                <div className="flex items-center justify-between mb-8">
                  <div className="flex items-center space-x-3">
                    <div className="h-10 w-10 bg-indigo-600/10 rounded-xl flex items-center justify-center border border-indigo-500/20">
                      <BarChart3 className="h-6 w-6 text-indigo-400" />
                    </div>
                    <h3 className="text-xl font-black text-white italic uppercase tracking-wider">RAPORLAMA</h3>
                  </div>
                  <button 
                    onClick={() => companyId && fetchStats(companyId)}
                    disabled={isStatsLoading}
                    className="p-2 text-slate-400 hover:text-white hover:bg-white/10 rounded-lg transition-all"
                    title="Yenile"
                  >
                    <RefreshCw className={`h-5 w-5 ${isStatsLoading ? 'animate-spin' : ''}`} />
                  </button>
                </div>

                {isStatsLoading ? (
                  <div className="space-y-4 animate-pulse">
                    {[1, 2, 3].map(i => (
                      <div key={i} className="h-16 bg-white/5 rounded-2xl w-full" />
                    ))}
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Total Stats Card */}
                    <div className="bg-gradient-to-br from-indigo-500/20 to-blue-500/20 border border-white/5 rounded-2xl p-6 relative overflow-hidden">
                      <div className="relative z-10 text-center">
                        <span className="text-[10px] font-black text-indigo-300 uppercase tracking-[0.2em]">Toplam Kullanım</span>
                        <div className="text-5xl font-black text-white mt-1 leading-tight">{stats?.totalUsed || 0}</div>
                        <p className="text-[11px] text-slate-400 mt-2 font-medium">Onaylanan Tüm Fırsatlar</p>
                      </div>
                      <BarChart3 className="absolute -bottom-4 -right-4 h-24 w-24 text-white/5" />
                    </div>

                    {/* Breakdown List */}
                    <div className="space-y-3 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
                      <h4 className="text-[10px] font-bold text-slate-500 uppercase tracking-widest pl-2">Kupon Bazlı Dağılım</h4>
                      {stats?.byCoupon && stats.byCoupon.length > 0 ? (
                        stats.byCoupon.map((item) => (
                          <div 
                            key={item.id}
                            className="flex items-center justify-between bg-white/[0.03] hover:bg-white/[0.06] transition-colors p-4 rounded-2xl border border-white/5 group"
                          >
                            <div className="flex items-center space-x-3">
                              <div className="h-8 w-8 bg-blue-500/10 rounded-lg flex items-center justify-center border border-blue-500/10 group-hover:bg-blue-500/20 transition-colors">
                                <Ticket className="h-4 w-4 text-blue-400" />
                              </div>
                              <span className="text-sm font-bold text-slate-300 truncate max-w-[140px]">{item.title}</span>
                            </div>
                            <div className="flex items-center space-x-2">
                              <span className="text-lg font-black text-white">{item.count}</span>
                              <span className="text-[10px] text-slate-500 font-bold uppercase">Adet</span>
                            </div>
                          </div>
                        ))
                      ) : (
                        <div className="text-center py-10 text-slate-500">
                          <Ticket className="h-10 w-10 mx-auto mb-3 opacity-20" />
                          <p className="text-xs font-bold uppercase tracking-tight">Henüz Kayıt Yok</p>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Floating Right Support Sidebar (Desktop) / Bottom Bar (Mobile) */}
      {companyId && (
        <div className="fixed bottom-6 right-6 lg:top-1/2 lg:-translate-y-1/2 flex flex-col items-end space-y-4 z-[100] group">
          <div className="bg-slate-900/90 backdrop-blur-sm border border-white/10 px-4 py-2 rounded-full mb-2 shadow-2xl animate-bounce">
            <span className="text-[10px] font-black text-blue-400 uppercase tracking-[0.1em]">
              Yönetici ile İletişime Geç
            </span>
          </div>
          
          <div className="flex flex-col space-y-4">
            <a 
              href="https://wa.me/905456962060"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center space-x-4 group"
            >
              <span className="hidden lg:block bg-slate-900/80 backdrop-blur-sm px-4 py-2 rounded-xl text-white text-xs font-bold border border-white/5 opacity-0 group-hover:opacity-100 transition-all shadow-xl">
                WhatsApp İle Yaz
              </span>
              <div className="h-20 w-20 bg-emerald-500 rounded-[2rem] shadow-2xl shadow-emerald-500/40 hover:scale-110 active:scale-95 transition-all border-4 border-[#0f172a] flex flex-col items-center justify-center">
                <MessageCircle className="h-8 w-8 text-white" />
                <span className="text-[10px] font-black text-white/80 uppercase mt-1">Destek</span>
              </div>
            </a>

            <a 
              href="tel:+905456962060"
              className="flex items-center space-x-4 group"
            >
              <span className="hidden lg:block bg-slate-900/80 backdrop-blur-sm px-4 py-2 rounded-xl text-white text-xs font-bold border border-white/5 opacity-0 group-hover:opacity-100 transition-all shadow-xl">
                Yöneticiyi Ara
              </span>
              <div className="h-20 w-20 bg-blue-600 rounded-[2rem] shadow-2xl shadow-blue-500/40 hover:scale-110 active:scale-95 transition-all border-4 border-[#0f172a] flex flex-col items-center justify-center">
                <Phone className="h-8 w-8 text-white" />
                <span className="text-[10px] font-black text-white/80 uppercase mt-1">İletişim</span>
              </div>
            </a>
          </div>
        </div>
      )}

      <style>{`
        .custom-scrollbar::-webkit-scrollbar { width: 4px; }
        .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }
      `}</style>
    </div>
  );
}

export default App;
