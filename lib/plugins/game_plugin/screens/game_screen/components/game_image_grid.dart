import 'package:flutter/material.dart';
import '../../../../../utils/consts/theme_consts.dart';

class GameImageGrid extends StatelessWidget {
  final List<String> imageOptions;
  final Function(String) onImageTap;
  final Set<String> fadedImages; // ✅ Track faded images

  const GameImageGrid({
    Key? key,
    required this.imageOptions,
    required this.onImageTap,
    required this.fadedImages, // ✅ Passed from GameScreen
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> images = imageOptions.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ Top Row (First 2 Images)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.take(2).map((image) => _buildImageBox(image)).toList(),
        ),
        const SizedBox(height: 8),

        // ✅ Bottom Row (Next 2 Images)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.skip(2).map((image) => _buildImageBox(image)).toList(),
        ),
      ],
    );
  }

  /// ✅ Reusable Image Box with fading effect
  Widget _buildImageBox(String imageUrl) {
    bool isFaded = fadedImages.contains(imageUrl);

    return GestureDetector(
      onTap: isFaded ? null : () => onImageTap(imageUrl), // ✅ Disable tapping on faded images
      child: Opacity(
        opacity: isFaded ? 0.1 : 1.0, // ✅ Fade out incorrect images
        child: Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isFaded ? Colors.grey : AppColors.accentColor, // ✅ Grey border if faded
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
