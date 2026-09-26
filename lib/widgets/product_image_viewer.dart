import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../app/app_colors.dart';

class ProductImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ProductImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<ProductImageViewer> {
  late PageController _pageController;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            /// Zoomable image gallery
            PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(
                color: Colors.white,
              ),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(
                    widget.imageUrls[index],
                  ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.5,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: "product-image-$index-${widget.imageUrls[index]}",
                  ),
                );
              },
            ),

            /// Close button
            Positioned(
              top: 12,
              right: 16,
              child: _closeButton(),
            ),

            /// Image counter
            if (widget.imageUrls.length > 1)
              Positioned(
                top: 18,
                left: 18,
                child: _counter(),
              ),

            /// Bottom thumbnails
            if (widget.imageUrls.length > 1)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _thumbnailBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _closeButton() {
    return Material(
      color: Colors.grey.shade700.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Navigator.pop(context);
        },
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _counter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "${_selectedIndex + 1} / ${widget.imageUrls.length}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _thumbnailBar() {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == _selectedIndex;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 70,
              height: 70,
              padding: EdgeInsets.all(selected ? 2 : 1),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
