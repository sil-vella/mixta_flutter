import 'package:flutter/material.dart';
import '../../../../../utils/consts/theme_consts.dart';

class GameImageGrid extends StatelessWidget {
  final List<String> imageOptions;
  final Function(String) onImageTap;

  const GameImageGrid({
    Key? key,
    required this.imageOptions,
    required this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // ✅ 2 images per row
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: imageOptions.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageTap(imageOptions[index]),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accentColor, // ✅ Accent color border
                width: 4.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Image.network(
                imageOptions[index],
                height: 150,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
