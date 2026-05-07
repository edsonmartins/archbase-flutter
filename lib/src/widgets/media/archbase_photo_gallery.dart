import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../theme/archbase_theme_extensions.dart';

/// Item da galeria — pode ser URL remota, asset ou caminho local.
class ArchbasePhoto {
  ArchbasePhoto({
    this.url,
    this.assetPath,
    this.localPath,
    this.caption,
    this.id,
  }) : assert(
          url != null || assetPath != null || localPath != null,
          'Informe url, assetPath ou localPath',
        );

  final String? url;
  final String? assetPath;
  final String? localPath;
  final String? caption;
  final String? id;
}

/// Galeria horizontal compacta com viewer fullscreen ao tocar.
class ArchbasePhotoGallery extends StatelessWidget {
  const ArchbasePhotoGallery({
    super.key,
    required this.photos,
    this.height = 96,
    this.onRemove,
    this.onAdd,
    this.maxPhotos,
  });

  final List<ArchbasePhoto> photos;
  final double height;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onAdd;
  final int? maxPhotos;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    final canAdd =
        onAdd != null && (maxPhotos == null || photos.length < maxPhotos!);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: photos.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, idx) {
          if (canAdd && idx == photos.length) {
            return _AddTile(
                onTap: onAdd!, height: height, color: colors.border);
          }
          final photo = photos[idx];
          return _Thumb(
            photo: photo,
            size: height,
            onTap: () => _openViewer(context, idx),
            onRemove: onRemove == null ? null : () => onRemove!(idx),
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _GalleryViewer(photos: photos, initialIndex: initialIndex),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.photo,
    required this.size,
    required this.onTap,
    this.onRemove,
  });

  final ArchbasePhoto photo;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: size,
              height: size,
              child: _buildImage(),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child:
                      const Icon(LucideIcons.x, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (photo.url != null) {
      return CachedNetworkImage(
        imageUrl: photo.url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Colors.black12),
        errorWidget: (_, __, ___) => const ColoredBox(
            color: Colors.black12, child: Icon(LucideIcons.image)),
      );
    }
    if (photo.localPath != null) {
      return Image.file(File(photo.localPath!), fit: BoxFit.cover);
    }
    return Image.asset(photo.assetPath!, fit: BoxFit.cover);
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile(
      {required this.onTap, required this.height, required this.color});

  final VoidCallback onTap;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: height,
        height: height,
        decoration: BoxDecoration(
          border:
              Border.all(color: color, width: 1.5, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.photos, required this.initialIndex});
  final List<ArchbasePhoto> photos;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}'),
      ),
      body: PhotoViewGallery.builder(
        pageController: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        builder: (_, i) {
          final p = widget.photos[i];
          ImageProvider provider;
          if (p.url != null) {
            provider = CachedNetworkImageProvider(p.url!);
          } else if (p.localPath != null) {
            provider = FileImage(File(p.localPath!));
          } else {
            provider = AssetImage(p.assetPath!);
          }
          return PhotoViewGalleryPageOptions(
            imageProvider: provider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          );
        },
      ),
    );
  }
}
