import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:tencent_cloud_chat_uikit/extensions/v2timmessage_extensions.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/image_hero.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../business_logic/view_models/tui_chat_global_model.dart';
import '../../../data_services/core/tim_uikit_wide_modal_operation_key.dart';
import '../../../data_services/services_locatar.dart';
import '../../utils/message_has_file_util.dart';
import '../wide_popup.dart';

class ImageItem extends StatelessWidget {
  const ImageItem({
    super.key,
    required this.size,
    required this.canScaleImage,
    required this.heroTag,
    required this.slidePagekey,
    required this.onImgTap,
    required this.onLongPress,
    required this.imageDetailY,
    // 暂时不使用 hero，滑动返回的时候会有点问题
    this.useHero = false,
    required this.message,
  });

  final bool Function(GestureDetails? details) canScaleImage;
  final String heroTag;
  final Size size;
  final double imageDetailY;
  final GlobalKey<ExtendedImageSlidePageState> slidePagekey;
  final VoidCallback onImgTap;
  final VoidCallback onLongPress;
  final bool useHero;
  final V2TimMessage message;

  @override
  Widget build(BuildContext context) {
    final imageProvider = message.imgProvider;
    Widget image = imageProvider != null
        ? ExtendedImage(
            image: imageProvider,
            fit: BoxFit.contain,
            enableSlideOutPage: true,
            gaplessPlayback: false,
            mode: ExtendedImageMode.gesture,
            initGestureConfigHandler: (ExtendedImageState state) {
              double? initialScale = 1.0;
              if (state.extendedImageInfo != null) {
                initialScale = _initScale(
                  size: size,
                  initialScale: initialScale,
                  imageSize: Size(
                    min(
                      size.width,
                      state.extendedImageInfo!.image.width.toDouble(),
                    ),
                    min(
                      size.height,
                      state.extendedImageInfo!.image.height.toDouble(),
                    ),
                  ),
                );
              }
              return GestureConfig(
                inPageView: true,
                initialScale: 1.0,
                maxScale: max(initialScale ?? 1.0, 5.0),
                animationMaxScale: max(initialScale ?? 1.0, 5.0),
              );
            },
            loadStateChanged: (ExtendedImageState state) {
              if (state.extendedImageLoadState == LoadState.completed) {
                return ExtendedImageGesture(
                  state,
                  canScaleImage: canScaleImage,
                  imageBuilder: (Widget image) {
                    return Stack(
                      children: <Widget>[
                        Positioned.fill(
                          top: imageDetailY,
                          bottom: -imageDetailY,
                          child: image,
                        ),
                      ],
                    );
                  },
                );
              }
              return InkWell(
                onTap: onImgTap,
                child: const UnconstrainedBox(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          )
        : const Center(
            child: Text(
              '图片丢失',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          );

    if (useHero) {
      image = HeroWidget(
        tag: heroTag,
        slidePagekey: slidePagekey,
        child: image,
      );
    }
    return GestureDetector(
      onTap: onImgTap,
      onSecondaryTapDown: (details) {
        if (PlatformUtils().isDesktop) {
          TUIKitWidePopup.showPopupWindow(
            operationKey:
                TUIKitWideModalOperationKey.mediaBrowserImgSecondaryMenu,
            isDarkBackground: false,
            borderRadius: const BorderRadius.all(
              Radius.circular(4),
            ),
            context: context,
            offset: Offset(
              min(details.globalPosition.dx,
                  MediaQuery.of(context).size.width - 80),
              min(details.globalPosition.dy,
                  MediaQuery.of(context).size.height - 130),
            ),
            child: (onClose) => _defaultSecondaryMenu(
              onClose,
            ),
          );
        }
      },
      onLongPress: onLongPress,
      child: image,
    );
  }

  Widget _defaultSecondaryMenu(VoidCallback onClose) {
    return TUIKitColumnMenu(data: [
      if (!PlatformUtils().isWeb && false)
        ColumnMenuItem(
            label: PlatformUtils().isMacOS ? TIM_t("在访达中打开") : TIM_t("查看文件夹"),
            icon: Image.asset(
              "images/folder_open.png",
              package: "tencent_cloud_chat_uikit",
              width: 20,
              height: 20,
            ),
            onClick: () {
              onClose();
              _onOpenDesktop();
            }),
    ]);
  }

  _onOpenDesktop() {
    String savePath = "";
    final TUIChatGlobalModel globalModal = serviceLocator<TUIChatGlobalModel>();

    final (exits, filePath) =
        MessageHasFileUtil.of.hasFile(message, globalModal);

    if (exits) {
      savePath = filePath;
      final String fileDir = path.dirname(savePath);
      try {
        if (PlatformUtils().isDesktop && !PlatformUtils().isWindows) {
          launchUrl(Uri.file(fileDir));
        } else {
          OpenFile.open(fileDir);
        }
        // ignore: empty_catches
      } catch (e) {}
    }
  }

  double? _initScale({
    required Size imageSize,
    required Size size,
    double? initialScale,
  }) {
    final double n1 = imageSize.height / imageSize.width;
    final double n2 = size.height / size.width;
    if (n1 > n2) {
      final FittedSizes fittedSizes =
          applyBoxFit(BoxFit.contain, imageSize, size);
      //final Size sourceSize = fittedSizes.source;
      final Size destinationSize = fittedSizes.destination;
      return size.width / destinationSize.width;
    } else if (n1 / n2 < 1 / 4) {
      final FittedSizes fittedSizes =
          applyBoxFit(BoxFit.contain, imageSize, size);
      //final Size sourceSize = fittedSizes.source;
      final Size destinationSize = fittedSizes.destination;
      return size.height / destinationSize.height;
    }

    return initialScale;
  }
}

extension V2TimMessageImgProvider on V2TimMessage {
  ImageProvider? get imgProvider {
    final smallImg = MessageUtils.getImageFromImgList(
      imageElem?.imageList,
      HistoryMessageDartConstant.smallImgPrior,
    );
    final originalImg = MessageUtils.getImageFromImgList(
      imageElem?.imageList,
      HistoryMessageDartConstant.oriImgPrior,
    );
    if (PlatformUtils().isWeb && imageElem!.path != null) {
      // Displaying on Web only
      return _getImgProvider(
        isNetworkImage: true,
        smallImg: smallImg,
        originalImg: originalImg,
        webPath: imageElem!.path,
      );
    }

    try {
      if ((_isNeedShowLocalPath &&
          imageElem!.path != null &&
          imageElem!.path!.isNotEmpty &&
          File(imageElem!.path!).existsSync())) {
        return _getImgProvider(
          smallLocalPath: imageElem!.path!,
          originLocalPath: imageElem!.path!,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      outputLogger.i(e.toString());
    }

    try {
      if ((TencentUtils.checkString(smallImg?.localUrl) != null &&
              File((smallImg?.localUrl!)!).existsSync()) ||
          (TencentUtils.checkString(originalImg?.localUrl) != null &&
              File((originalImg?.localUrl!)!).existsSync())) {
        return _getImgProvider(
          smallLocalPath: smallImg?.localUrl ?? "",
          originLocalPath: originalImg?.localUrl,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      outputLogger.i(e.toString());
      return _getImgProvider(
        isNetworkImage: true,
        smallImg: smallImg,
        originalImg: originalImg,
      );
    }

    if ((smallImg?.url ?? originalImg?.url) != null &&
        (smallImg?.url ?? originalImg?.url)!.isNotEmpty) {
      return _getImgProvider(
        isNetworkImage: true,
        smallImg: smallImg,
        originalImg: originalImg,
      );
    }
    return null;
  }

  ImageProvider? _getImgProvider({
    bool isNetworkImage = false,
    String? webPath,
    V2TimImage? originalImg,
    V2TimImage? smallImg,
    String? smallLocalPath,
    String? originLocalPath,
  }) {
    final imgUrl = webPath ?? smallImg?.url ?? originalImg?.url ?? "";
    final imgPath = (TencentUtils.checkString(originLocalPath) != null
            ? originLocalPath
            : smallLocalPath) ??
        "";
    if (isNetworkImage) {
      if (imgUrl.isEmpty) return null;
      if (isExpired) {
        return null;
      }
      return CachedNetworkImageProvider(
        imgUrl,
        cacheKey: msgID,
      );
    } else {
      if (imgPath.isEmpty) return null;
      return FileImage(File(imgPath));
    }
  }

  bool get _isNeedShowLocalPath {
    final current = (DateTime.now().millisecondsSinceEpoch / 1000).ceil();
    final timeStamp = timestamp ?? current;
    return (isSelf ?? true) && current - timeStamp < 300;
  }
}
