import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

/// Shows up to 5 photos with add / delete / set-primary support.
/// Set [editable] = false for read-only view (profile detail screen).
class PhotoGalleryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> initialPhotos;
  final bool editable;

  const PhotoGalleryWidget({
    super.key,
    required this.initialPhotos,
    this.editable = true,
  });

  @override
  State<PhotoGalleryWidget> createState() => _PhotoGalleryWidgetState();
}

class _PhotoGalleryWidgetState extends State<PhotoGalleryWidget> {
  late List<Map<String, dynamic>> _photos;
  bool _uploading = false;

  static const _kPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _photos = List<Map<String, dynamic>>.from(widget.initialPhotos);
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _addPhoto() async {
    if (_photos.length >= 5) {
      _snack('Maximum 5 photos allowed. Delete one first.');
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final res = await ApiService.uploadProfilePhoto(File(picked.path));
    if (!mounted) return;
    setState(() => _uploading = false);

    if (res['status'] == true) {
      final d = res['data'] ?? {};
      setState(() {
        _photos.add({
          'id':         d['photo_id'] ?? 0,
          'url':        d['photo_url'] ?? '',
          'is_primary': d['is_primary'] == true || d['is_primary'] == 1,
        });
      });
      _snack('Photo uploaded!', ok: true);
    } else {
      _snack(res['message'] ?? 'Upload failed');
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _delete(Map<String, dynamic> photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo from your profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final photoId = int.tryParse(photo['id']?.toString() ?? '0') ?? 0;
    if (photoId > 0) {
      final res = await ApiService.deletePhoto(photoId);
      if (!mounted) return;
      if (res['status'] != true) { _snack(res['message'] ?? 'Delete failed'); return; }
    }
    setState(() => _photos.remove(photo));
    _snack('Photo deleted');
  }

  // ── Set Primary ────────────────────────────────────────────────────────────

  Future<void> _setPrimary(Map<String, dynamic> photo) async {
    final photoId = int.tryParse(photo['id']?.toString() ?? '0') ?? 0;
    if (photoId > 0) {
      final res = await ApiService.setPrimaryPhoto(photoId);
      if (!mounted) return;
      if (res['status'] != true) { _snack(res['message'] ?? 'Failed'); return; }
    }
    setState(() {
      for (final p in _photos) { p['is_primary'] = false; }
      photo['is_primary'] = true;
    });
    _snack('Profile photo updated!', ok: true);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final slots = _photos.length;
    final showAdd = widget.editable && slots < 5;
    final itemCount = slots + (showAdd ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text('Photos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$slots/5',
                  style: const TextStyle(fontSize: 11, color: _kPink, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: itemCount,
          itemBuilder: (_, i) {
            if (i == slots) return _buildAddTile();
            return _buildPhotoTile(_photos[i]);
          },
        ),

        // Upload progress
        if (_uploading) ...[
          const SizedBox(height: 10),
          const Row(
            children: [
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPink)),
              SizedBox(width: 8),
              Text('Uploading...', style: TextStyle(fontSize: 13, color: _kPink)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoTile(Map<String, dynamic> photo) {
    final url = photo['url']?.toString() ?? '';
    final isPrimary = photo['is_primary'] == true || photo['is_primary'] == 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(url, fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(color: const Color(0xFFF5F5F5),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),

        // Primary badge
        if (isPrimary)
          Positioned(
            top: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _kPink, borderRadius: BorderRadius.circular(8)),
              child: const Text('Main',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),

        // Edit actions
        if (widget.editable)
          Positioned(
            bottom: 5, right: 5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPrimary)
                  _miniBtn(Icons.star_outline, Colors.amber.shade700, () => _setPrimary(photo)),
                const SizedBox(width: 4),
                _miniBtn(Icons.delete_outline, Colors.red, () => _delete(photo)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPink.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: _kPink, size: 26),
            const SizedBox(height: 5),
            Text('Add Photo',
                style: TextStyle(fontSize: 11, color: _kPink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.photo_outlined, color: Colors.grey)),
      );

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4)],
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
