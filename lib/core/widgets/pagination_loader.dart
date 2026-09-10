import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PaginationLoader extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;

  const PaginationLoader({
    super.key,
    this.isLoading = false,
    this.hasMore = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && hasMore) {
      return const SizedBox.shrink();
    }

    if (!isLoading && !hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Tidak ada data lagi',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}