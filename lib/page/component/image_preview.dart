import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/helper/image.dart';
import 'package:askaide/helper/logger.dart';
import 'package:askaide/helper/platform.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/gallery_item_share.dart';
import 'package:askaide/page/component/image.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:before_after/before_after.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:photo_view/photo_view.dart';

class NetworkImagePreviewer extends StatefulWidget {
  final String url;
  final String? preview;
  final String? original;
  final String? description;
  final bool hidePreviewButton;
  final bool notClickable;
  final BorderRadius? borderRadius;

  const NetworkImagePreviewer({
    super.key,
    required this.url,
    this.preview,
    this.description,
    this.original,
    this.hidePreviewButton = false,
    this.notClickable = false,
    this.borderRadius,
  });

  @override
  State<NetworkImagePreviewer> createState() => _NetworkImagePreviewerState();
}

class _NetworkImagePreviewerState extends State<NetworkImagePreviewer> {
  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;

    if (widget.hidePreviewButton) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: widget.original == null
            ? _buildImage(widget.borderRadius)
            : BeforeAfter(
                beforeImage: Image(
                    image: CachedNetworkImageProviderEnhanced(
                        imageURL(widget.original!, qiniuImageTypeThumb))),
                afterImage: Image(
                    image: CachedNetworkImageProviderEnhanced(imageURL(
                        widget.preview ?? widget.url, qiniuImageTypeThumb))),
                thumbWidth: 1.0,
              ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: customColors.columnBlockBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          widget.original == null
              ? _buildImage(const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ))
              : ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: BeforeAfter(
                    imageCornerRadius: 0,
                    beforeImage: Image(
                        image: CachedNetworkImageProviderEnhanced(
                            imageURL(widget.original!, qiniuImageTypeThumb))),
                    afterImage: Image(
                        image: CachedNetworkImageProviderEnhanced(imageURL(
                            widget.preview ?? widget.url,
                            qiniuImageTypeThumb))),
                    thumbWidth: 0.5,
                    thumbRadius: 3,
                  ),
                ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share,
                        size: 14,
                        color: customColors.weakLinkColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 12,
                          color: customColors.weakLinkColor,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => GalleryItemShareScreen(
                          images: [widget.url],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: customColors.weakLinkColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 12,
                          color: customColors.weakLinkColor,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    try {
                      openImagePreviewDialog(
                        context,
                        customColors,
                        imageProvider:
                            CachedNetworkImageProviderEnhanced(widget.url),
                        imageUrl: widget.url,
                      );
                    } catch (e) {
                      showErrorMessageEnhanced(context, 'Failed to load image, please try again later');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BorderRadius? borderRadius) {
    return CachedNetworkImageEnhanced(
      imageUrl: widget.preview ?? widget.url,
      cacheManager: DefaultCacheManager(),
      imageBuilder: (context, imageProvider) {
        if (widget.notClickable) {
          return Image(image: imageProvider, fit: BoxFit.cover);
        }

        return ImageFilePreviewer(
          borderRadius: borderRadius,
          imageProvider: imageProvider,
          imageUrl: widget.preview ?? widget.url,
          description: widget.description,
          originalURL: widget.preview != null ? widget.url : null,
        );
      },
      progressIndicatorBuilder: (context, url, downloadProgress) => Container(
        padding: const EdgeInsets.all(5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 200,
            minHeight: 200,
          ),
          child: Center(
            child: LoadingIndicator(
              message: AppLocale.processingWait.getString(context),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildImageBrokenWidget(context),
    );
  }

  Widget _buildImageBrokenWidget(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/image-broken.png',
        fit: BoxFit.cover,
        width: 200,
        color: Theme.of(context).cardColor,
      ),
    );
  }
}

class ImageFilePreviewer extends StatelessWidget {
  final ImageProvider imageProvider;
  final String? description;
  final String? originalURL;
  final String imageUrl;
  final BorderRadius? borderRadius;
  const ImageFilePreviewer({
    super.key,
    required this.imageProvider,
    this.description,
    this.originalURL,
    required this.imageUrl,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: InkWell(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Image(image: imageProvider, fit: BoxFit.cover),
        onTap: () {
          openImagePreviewDialog(
            context,
            customColors,
            imageProvider: imageProvider,
            imageUrl: imageUrl,
            originalURL: originalURL,
            description: description,
          );
        },
      ),
    );
  }
}

void openImagePreviewDialog(
  BuildContext context,
  CustomColors customColors, {
  required ImageProvider imageProvider,
  required String imageUrl,
  String? originalURL,
  String? description,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: CustomSize.toolbarHeight,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => GalleryItemShareScreen(
                      images: [imageUrl],
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.share,
                size: 16,
                color: customColors.weakLinkColor,
              ),
            ),
            IconButton(
              onPressed: () async {
                final cancel = BotToast.showCustomLoading(
                  toastBuilder: (cancel) {
                    return const LoadingIndicator(
                     