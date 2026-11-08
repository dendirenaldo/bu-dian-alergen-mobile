import 'package:flutter/material.dart';

/// Kumpulan [GlobalKey] untuk sorotan panduan (coachmark).
///
/// Setiap kunci dipasang tepat satu kali di pohon widget agar tidak
/// terjadi duplikasi. Kunci dibiarkan statis supaya bisa diakses dari
/// [GuidedTourService] maupun halaman tanpa meneruskan via konstruktor.
class TourKeys {
  static final GlobalKey homeHeaderKey = GlobalKey();
  static final GlobalKey scanActionKey = GlobalKey();
  static final GlobalKey historyActionKey = GlobalKey();
  static final GlobalKey uploadAreaKey = GlobalKey();
  static final GlobalKey modelDropdownKey = GlobalKey();
  static final GlobalKey modeToggleQuotaKey = GlobalKey();
  static final GlobalKey detectButtonKey = GlobalKey();
  static final GlobalKey processingBoxKey = GlobalKey();
  static final GlobalKey resultCardKey = GlobalKey();
  static final GlobalKey historyCardKey = GlobalKey();
}
