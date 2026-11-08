import 'package:flutter/material.dart';

/// Global navigator key used for session-expiry redirects.
///
/// Wired into [MaterialApp.navigatorKey] so providers can navigate
/// without holding a BuildContext (avoids notify-during-build issues).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
