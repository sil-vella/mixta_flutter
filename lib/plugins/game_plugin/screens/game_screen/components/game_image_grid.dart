import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mixta_guess_who/plugins/game_plugin/modules/function_helper_module/function_helper_module.dart';
import 'package:mixta_guess_who/utils/consts/theme_consts.dart';
import '../../../../../tools/logging/logger.dart';
import '../../../modules/game_play_module/game_play_module.dart';
import '../../../../../core/managers/module_manager.dart';

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
  final ModuleManager moduleManager = ModuleManager();
  late FunctionHelperModule gameFunctionsHelper; // ✅ Declare instance

  @override
  void initState() {
    super.initState();
    _resetLoadingState();
    // ✅ Fetch GamePlayModule instance from ModuleManager
    gameFunctionsHelper = moduleManager.getModule<FunctionHelperModule>('game_functions_helper_module') ?? FunctionHelperModule();
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

  void _onImageLoaded(int index, String imageUrl) {
    if (mounted && !_isLoaded[index]) {
      setState(() {
        _isLoaded[index] = true;
        _loadedCount++;

        Logger().info("📸 Image Loaded: $imageUrl [${_loadedCount}/${widget.imageOptions.length}]");

        // ✅ Store image timestamp only on success
        gameFunctionsHelper.storeImageCacheTimestamp(imageUrl);

        /// ✅ Fire `onAllImagesLoaded` only when ALL images finish loading
        if (_loadedCount >= widget.imageOptions.length && !_callbackFired) {
          _callbackFired = true;
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

  Widget _buildImageBox(String imageUrl, int index) {
    bool isFaded = widget.fadedImages.contains(imageUrl);
    Logger().info("📸 Checking if faded: $imageUrl -> ${isFaded ? "Faded" : "Visible"}");

    return GestureDetector(
      onTap: isFaded ? null : () => _handleImageTap(imageUrl),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500), // ✅ Smooth fade animation
        opacity: isFaded ? 0.3 : 1.0, // ✅ Reduce opacity for faded images
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
            child: ColorFiltered(
              colorFilter: isFaded
                  ? ColorFilter.mode(Colors.grey.withOpacity(0.5), BlendMode.saturation)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,

                /// ✅ Placeholder while loading
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),

                /// ❌ Error Handling: Still trigger `_onImageLoaded` for failed images
                errorWidget: (context, url, error) {
                  Logger().error("❌ Image failed to load: $imageUrl | Using fallback...");
                  _onImageLoaded(index, imageUrl); // ✅ Still track errors
                  return Image.asset(
                    'assets/images/icon.png', // ✅ Fallback image
                    fit: BoxFit.cover,
                  );
                },

                /// ✅ Fires `_onImageLoaded` when image is successfully displayed
                imageBuilder: (context, imageProvider) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onImageLoaded(index, imageUrl);
                  });
                  return Image(image: imageProvider, fit: BoxFit.cover);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }


}
