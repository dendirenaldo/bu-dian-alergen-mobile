import 'package:flutter/material.dart';

class ImagePickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const ImagePickerSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Color(0xFF2563EB),
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo'),
              onTap: onCamera,
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF10B981),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: onGallery,
            ),
          ],
        ),
      ),
    );
  }
}
