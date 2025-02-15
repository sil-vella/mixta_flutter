import 'package:flutter/material.dart';
import 'package:mixta_guess_who/utils/consts/theme_consts.dart';

class GameImageGrid extends StatefulWidget {
  final List<String> imageOptions;
  final Function(String) onImageTap;
  final Function() onAllImagesLoaded; // ✅ Callback for parent
  final Set<String> fadedImages;

  const GameImageGrid({
    Key? key,
    required this.imageOptions,
    required this.onImageTap,
    required this.onAllImagesLoaded, // ✅ Passed from parent
    required this.fadedImages,
  }) : super(key: key);

  @override
  _GameImageGridState createState() => _GameImageGridState();
}

class _GameImageGridState extends State<GameImageGrid> {
  final Map<String, bool> _isLoading = {}; // ✅ Track loading state for each image
  String? _selectedImage;
  bool _disableAllTaps = false;
  int _loadedImagesCount = 0; // ✅ Track loaded images count

  @override
  void initState() {
    super.initState();
    for (String imageUrl in widget.imageOptions.take(4)) {
      _isLoading[imageUrl] = true; // ✅ Mark all images as loading
    }
  }

  /// ✅ Detects when the parent updates and resets selection for a new round
  @override
  void didUpdateWidget(covariant GameImageGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.imageOptions != oldWidget.imageOptions) {
      setState(() {
        _selectedImage = null;
        _disableAllTaps = false;
        _loadedImagesCount = 0; // ✅ Reset loaded images count
      });
    }
  }

  void _handleImageTap(String imageUrl) {
    if (_disableAllTaps) return;

    setState(() {
      _selectedImage = imageUrl;
      _disableAllTaps = true;
    });

    widget.onImageTap(imageUrl);
  }

  void _onImageLoaded(String imageUrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLoading.containsKey(imageUrl)) {
        setState(() {
          _isLoading[imageUrl] = false;
          _loadedImagesCount++; // ✅ Increment count only if the image was not already loaded

          // ✅ Call parent callback **only once** when all images are loaded
          if (_loadedImagesCount == widget.imageOptions.length) {
            widget.onAllImagesLoaded();
          }
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    List<String> images = widget.imageOptions.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.take(2).map((image) => _buildImageBox(image)).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.skip(2).map((image) => _buildImageBox(image)).toList(),
        ),
      ],
    );
  }
  Widget _buildImageBox(String imageUrl) {
    bool isFaded = widget.fadedImages.contains(imageUrl);
    bool isSelected = _selectedImage == imageUrl;
    bool isLoading = _isLoading[imageUrl] ?? true; // ✅ Fix: Provide default value

    return GestureDetector(
      onTap: isFaded || isLoading || _disableAllTaps ? null : () => _handleImageTap(imageUrl),
      child: Opacity(
        opacity: _selectedImage != null && _selectedImage != imageUrl ? 0.05 : 1.0,
        child: Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blueAccent : (isFaded ? Colors.grey : AppColors.accentColor),
              width: isSelected ? 4.0 : 2.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.6),
                spreadRadius: 5,
                blurRadius: 10,
              )
            ]
                : [],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  const CircularProgressIndicator(), // ✅ Show spinner while loading
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      _onImageLoaded(imageUrl); // ✅ Mark image as loaded
                      return child;
                    } else {
                      return const SizedBox(); // Hide image while loading
                    }
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
