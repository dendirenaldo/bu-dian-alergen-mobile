import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'tour_keys.dart';

/// Panduan 10 langkah dengan sorotan (coachmark).
///
/// Judul ditulis awam agar mudah dipahami pengguna baru.
/// Kunci prefs [seenKey] sengaja berbeda dari `onboarding_complete`
/// supaya tur bisa muncul sekali untuk pengguna lama.
class GuidedTourService {
  static const String seenKey = 'hasSeenGuidedTour';

  static Future<bool> hasSeenTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setTourSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(seenKey, true);
    } catch (_) {
      // Best-effort: tur boleh muncul lagi bila penyimpanan gagal.
    }
  }

  static bool _isVisible(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;
    final offstage = ctx.findAncestorWidgetOfExactType<Offstage>();
    if (offstage != null && offstage.offstage) return false;
    final render = ctx.findRenderObject();
    if (render == null || !render.attached) return false;
    return true;
  }

  static Widget _stepContent({
    required String title,
    required String description,
    required int step,
    required int total,
    required VoidCallback onNext,
    required bool isLast,
  }) {
    return Semantics(
      label: '$title. Langkah $step dari $total. $description',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$step/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              description,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: isLast ? 'Selesai panduan' : 'Lanjut ke langkah berikutnya',
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onNext();
                },
                child: Text(
                  isLast ? 'Selesai' : 'Lanjut',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 10 sorotan sesuai urutan alur pakai aplikasi.
  static List<TargetFocus> buildTargets() {
    const total = 10;
    return [
      TargetFocus(
        identify: 'home-header',
        keyTarget: TourKeys.homeHeaderKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Sapaan dan profilmu',
              description:
                  'Di sini kamu disapa sesuai waktu dan bisa melihat inisial akunmu. Ketuk lingkaran untuk membuka profil.',
              step: 1,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home-scan',
        keyTarget: TourKeys.scanActionKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Mulai periksa label',
              description:
                  'Ketuk tombol ini untuk membuka halaman pemindai dan memeriksa kemasan makanan.',
              step: 2,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'home-history',
        keyTarget: TourKeys.historyActionKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Buka catatan lama',
              description:
                  'Semua hasil yang tersimpan ada di sini. Cocok untuk membandingkan belanjaan kemarin.',
              step: 3,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'detection-upload',
        keyTarget: TourKeys.uploadAreaKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Ambil foto label kemasan',
              description:
                  'Ketuk kotak ini lalu pilih kamera atau galeri. Contoh baik: terang, tulisan tajam, label rata. Contoh buruk: gelap, goyang, tulisan terpotong atau tertutup bayangan.',
              step: 4,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'detection-model',
        keyTarget: TourKeys.modelDropdownKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Pilih mesin pemeriksa',
              description:
                  'Ada tiga pilihan mesin. Bawaan sudah cukup untuk pemakaian harian, ganti bila ingin membandingkan hasil.',
              step: 5,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'detection-mode-quota',
        keyTarget: TourKeys.modeToggleQuotaKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Tukar cara isi dan lihat sisa',
              description:
                  'Pakai tombol ini untuk tukar antara foto dan ketik isi manual. Tulisan kecil di sampingnya menunjukkan sisa jatah gratis per jam.',
              step: 6,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'detection-submit',
        keyTarget: TourKeys.detectButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _stepContent(
              title: 'Tekan untuk memeriksa',
              description:
                  'Setelah foto atau tulisan siap, tekan tombol besar ini. Hasilnya muncul di halaman berikutnya.',
              step: 7,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'detection-processing',
        keyTarget: TourKeys.processingBoxKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _stepContent(
              title: 'Tunggu sebentar',
              description:
                  'Kotak ini muncul saat aplikasi bekerja. Tunggu sampai selesai, jangan menutup halaman dulu.',
              step: 8,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'result-card',
        keyTarget: TourKeys.resultCardKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Baca hasil dengan tenang',
              description:
                  'Kartu ini merangkum status aman atau berbahaya, tingkat keyakinan, dan waktu pindai. Warna dan lencana membantu membaca cepat.',
              step: 9,
              total: total,
              isLast: false,
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'history-card',
        keyTarget: TourKeys.historyCardKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _stepContent(
              title: 'Buka lagi hasil lama',
              description:
                  'Ketuk salah satu baris untuk melihat detail lengkapnya kapan pun kamu butuh.',
              step: 10,
              total: total,
              isLast: true,
              onNext: controller.next,
            ),
          ),
        ],
      ),
    ];
  }

  /// Menampilkan sorotan yang kuncinya sedang terlihat di layar.
  ///
  /// Label `x/10` tetap memakai nomor urut penuh agar konsisten
  /// walau halaman lain sedang tersembunyi.
  static Future<void> showTour(BuildContext context) async {
    final all = buildTargets();
    final visible = all.where((t) => _isVisible(t.keyTarget!)).toList();
    if (visible.isEmpty) return;
    HapticFeedback.lightImpact();
    final coach = TutorialCoachMark(
      targets: visible,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 8,
      pulseEnable: true,
      hideSkip: false,
      textSkip: 'Lewati',
      alignSkip: Alignment.bottomRight,
      textStyleSkip: const TextStyle(color: Colors.white),
      onClickTarget: (_) => HapticFeedback.lightImpact(),
      onClickOverlay: (_) => HapticFeedback.lightImpact(),
      onFinish: () {
        HapticFeedback.lightImpact();
        unawaited(setTourSeen());
      },
      onSkip: () {
        HapticFeedback.lightImpact();
        unawaited(setTourSeen());
        return true;
      },
    );
    coach.show(context: context);
  }

  /// Otomatis tampil sekali untuk pengguna lama yang sudah lewat
  /// perkenalan awal tetapi belum pernah melihat tur ini.
  static Future<void> maybeShowAfterOnboarding(BuildContext context) async {
    bool onboardingDone = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    } catch (_) {
      onboardingDone = false;
    }
    if (!onboardingDone) return;
    if (await hasSeenTour()) return;
    if (!context.mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;
    await showTour(context);
  }
}

void unawaited(Future<void> future) {}
