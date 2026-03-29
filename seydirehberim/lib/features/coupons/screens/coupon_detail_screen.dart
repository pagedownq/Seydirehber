import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CouponDetailScreen extends ConsumerStatefulWidget {
  final String couponId;
  final Map<String, dynamic> couponData;

  const CouponDetailScreen({
    super.key,
    required this.couponId,
    required this.couponData,
  });

  @override
  ConsumerState<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends ConsumerState<CouponDetailScreen> {
  bool _isGenerating = false;
  bool _isChecking = true;
  bool _isUsed = false;
  String? _activeCodeId;
  DateTime? _expiresAt;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  Map<String, dynamic>? _currentCouponData;

  @override
  void initState() {
    super.initState();
    _currentCouponData = widget.couponData.isNotEmpty ? widget.couponData : null;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isChecking = true);
    await _checkExistingActiveCode();
    if (_currentCouponData == null) {
      await _fetchCouponData();
    }
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _fetchCouponData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('coupons')
          .doc(widget.couponId)
          .get();
      if (doc.exists) {
        setState(() {
          _currentCouponData = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error fetching coupon data: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingActiveCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // First check if already used (lifetime limit 1)
    final usedSnapshot = await FirebaseFirestore.instance
        .collection('generated_codes')
        .where('userId', isEqualTo: user.uid)
        .where('couponId', isEqualTo: widget.couponId)
        .where('status', isEqualTo: 'used')
        .limit(1)
        .get();

    if (usedSnapshot.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isUsed = true;
          _activeCodeId = usedSnapshot.docs.first.id; // Show that used UI
        });
      }
      return;
    }

    // If not used, check for pending active code
    final querySnapshot = await FirebaseFirestore.instance
        .collection('generated_codes')
        .where('userId', isEqualTo: user.uid)
        .where('couponId', isEqualTo: widget.couponId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final expires = (data['expiresAt'] as Timestamp).toDate();
      
      if (expires.isAfter(DateTime.now())) {
        // If we found an active (non-expired) code, use it.
        if (mounted && _activeCodeId == null) {
          setState(() {
            _activeCodeId = doc.id;
            _expiresAt = expires;
          });
          _startTimer();
        }
      } else {
        // Option B: Auto-Cleanup. If the code is expired and wasn't used, delete it.
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting expired code: $e');
        }
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    if (_expiresAt == null) return;
    final now = DateTime.now();
    if (_expiresAt!.isAfter(now)) {
      setState(() {
        _timeLeft = _expiresAt!.difference(now);
      });
    } else {
      _timer?.cancel();
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  Future<void> _generateCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın.')),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    const Text(
                      'Kuponu Kullanalım mı?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kupon kodunu oluşturduktan sonra 5 dakika süreniz başlar. Görevliye bu kodu göstererek indirimden faydalanabilirsiniz.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Vazgeç',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Kodu Oluştur',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final String code = _generateRandomCode();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 5));

      final docRef = await FirebaseFirestore.instance.collection('generated_codes').add({
        'couponId': widget.couponId,
        'companyId': _currentCouponData?['companyId'],
        'userId': user.uid,
        'code': code,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      setState(() {
        _activeCodeId = docRef.id;
        _expiresAt = expiresAt;
      });
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kod oluşturulamadı: \$e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Kupon Detayı')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeCodeId != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Kupon Kodu'),
          surfaceTintColor: Colors.transparent,
        ),
        body: _buildActiveCodeView(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kupon Detayı'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCouponHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kupon Hakkında',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentCouponData?['description'] ?? 'Detaylı bilgi bulunmuyor.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isGenerating || _isUsed ? null : _generateCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUsed ? Colors.grey : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isUsed ? 'Bu Kuponu Kullandınız' : 'Kuponu Kullan',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponHeader() {
    final title = _currentCouponData?['title'] ?? 'Kupon';
    final companyName = _currentCouponData?['companyName'] ?? '';
    final discount = _currentCouponData?['discountPercentage'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '%$discount İNDİRİM',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                companyName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCodeView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('generated_codes')
          .doc(_activeCodeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Center(child: Text('Kod bulunamadı.'));
        }

        final status = data['status'] as String? ?? 'pending';
        final code = data['code'] as String? ?? '';

        if (status == 'used') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kupon Başarıyla Kullanıldı!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bizi tercih ettiğiniz için teşekkür ederiz.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Geri Dön'),
                ),
              ],
            ),
          );
        }

        final minutes = _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
        final isExpired = _timeLeft.inSeconds <= 0;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Kupon Kodunuz',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpired ? Colors.grey : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: isExpired ? Colors.grey : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isUsed)
                  const Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Kupon Başarıyla Kullanıldı',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Bu kupondan daha önce faydalandınız.',
                        style: TextStyle(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    isExpired ? 'Süre Doldu' : 'Kalan Süre',
                    style: TextStyle(
                      fontSize: 16,
                      color: isExpired ? Colors.red : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                const Text(
                  'Lütfen bu kodu kasadatki görevliye gösterin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
