import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PullToRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: widget.child,
    );
  }
}