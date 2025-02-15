import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mixta_guess_who/utils/consts/theme_consts.dart';
import '../../../../../tools/logging/logger.dart';

class GameImageGrid extends StatefulWidget {
  final List<String> imageOptions;
  final Function(String) onImageTap;
  final Function() onAllImagesLoaded;
  final Set<String> fadedImages;

  const GameImageGrid({
    Key? key,
    required this.imageOptions,
    required this.onImageTap,
    required this.onAllImagesLoaded,
    required this.fadedImages,
  }) : super(key: key);

  @override
  _GameImageGridState createState() => _GameImageGridState();
}

class _GameImageGridState extends State<GameImageGrid> {
  late List<bool> _isLoaded; // ✅ List to track loaded images
  int _loadedCount = 0; // ✅ Track number of loaded images
  bool _callbackFired = false; // ✅ Prevent multiple callback triggers

  @override
  void initState() {
    super.initState();
    _resetLoadingState();
  }

  @override
  void didUpdateWidget(covariant GameImageGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.imageOptions != oldWidget.imageOptions) {
      _resetLoadingState();
    }
  }

  /// ✅ Resets the image loading state when the grid updates
  void _resetLoadingState() {
    setState(() {
      _isLoaded = List.generate(widget.imageOptions.length, (_) => false);
      _loadedCount = 0;
      _callbackFired = false;
    });
  }

  /// ✅ Called when an image (or error fallback) loads
  void _onImageLoaded(int index) {
    if (mounted && !_isLoaded[index]) {
      setState(() {
        _isLoaded[index] = true;
        _loadedCount++;

        Logger().info("📸 Image Loaded [${_loadedCount}/${widget.imageOptions.length}]");

        /// ✅ Fire `onAllImagesLoaded` when all images are done (loaded or errored)
        if (_loadedCount >= widget.imageOptions.length && !_callbackFired) {
          _callbackFired = true; // ✅ Prevent duplicate calls
          Logger().info("✅ ALL images processed. Triggering callback...");
          widget.onAllImagesLoaded();
        }
      });
    }
  }

  /// ✅ Handles user tapping an image
  void _handleImageTap(String imageUrl) {
    widget.onImageTap(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = widget.imageOptions.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.take(2).map((image) => _buildImageBox(image, images.indexOf(image))).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.skip(2).map((image) => _buildImageBox(image, images.indexOf(image))).toList(),
        ),
      ],
    );
  }

  /// ✅ Builds each image box with `CachedNetworkImage`
  Widget _buildImageBox(String imageUrl, int index) {
    bool isFaded = widget.fadedImages.contains(imageUrl);

    return GestureDetector(
      onTap: isFaded ? null : () => _handleImageTap(imageUrl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        height: 150,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFaded ? Colors.grey : AppColors.accentColor,
            width: isFaded ? 2.5 : 3.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,

            /// ✅ Placeholder while loading
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),

            /// ❌ Error Handling: Ensure `_onImageLoaded` is still triggered for fallback images
            errorWidget: (context, url, error) {
              Logger().error("❌ Image failed to load: $imageUrl | Using fallback...");
              _onImageLoaded(index);
              return Image.asset(
                'assets/images/icon.png', // ✅ Fallback image
                fit: BoxFit.cover,
              );
            },

            /// ✅ Fires `_onImageLoaded` when the image is displayed
            imageBuilder: (context, imageProvider) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onImageLoaded(index);
              });
              return Image(image: imageProvider, fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
  }
}
