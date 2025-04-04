// ignore_for_file: prefer_typing_uninitialized_variables,  unused_import, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/extensions/v2timmessage_extensions.dart';
import 'package:tencent_cloud_chat_uikit/kx_self/kx_util.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/media_download_util.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/im_media_msg_browser/media_browser.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/image_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/file_util.dart';

class TIMUIKitImageElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final String? isFrom;
  final bool? isShowMessageReaction;
  final TUIChatSeparateViewModel chatModel;
  final Size? Function(
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight,
  )? calculateSizeFunc;

  const TIMUIKitImageElem({
    required this.message,
    this.isShowJump = false,
    required this.chatModel,
    this.clearJump,
    this.isFrom,
    Key? key,
    this.isShowMessageReaction,
    ////////// 自定义入参 //////////
    this.calculateSizeFunc,
    ////////// 自定义入参 //////////
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitImageElem();
}

class _TIMUIKitImageElem extends TIMUIKitState<TIMUIKitImageElem> {
  final TUIChatGlobalModel globalModel = serviceLocator<TUIChatGlobalModel>();
  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();
  final MessageService _messageService = serviceLocator<MessageService>();
  Widget? imageItem;

  bool _didRenderWithNet = false;

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  String getOriginImgURLOf(V2TimMessage message) {
    // 实际拿的是原图
    V2TimImage? img = MessageUtils.getImageFromImgList(
        message.imageElem!.imageList, HistoryMessageDartConstant.oriImgPrior);
    return img == null ? message.imageElem!.path! : img.url!;
  }

  Widget errorDisplay(
    BuildContext context,
    TUITheme? theme, {
    num? height,
    num? width,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          width: 2,
          color: theme?.weakDividerColor ?? Colors.grey,
        ),
      ),
      height: height?.toDouble() ?? 170,
      width: width?.toDouble() ?? 170,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: theme?.cautionColor,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              TIM_t('图片过期\n或已被清理'),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme?.cautionColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget placeholderDisplay(
    BuildContext context,
    TUITheme? theme, {
    num? height,
    num? width,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(
          width: 2,
          color: theme?.weakDividerColor ?? Colors.grey,
        ),
      ),
      height: height?.toDouble() ?? 170,
      width: width?.toDouble() ?? 170,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: theme?.weakTextColor ?? Colors.grey,
              size: 28,
            )
          ],
        ),
      ),
    );
  }

  Widget getImage(image, {imageElem}) {
    Widget res = ClipRRect(
      clipper: ImageClipper(),
      child: image,
    );

    return res;
  }

  Future<void> _saveImg(
    TUITheme theme, {
    V2TimMessage? cusMsg,
  }) async {
    if(cusMsg==null)return;
    widget.chatModel.chatConfig.onImageLongPress
        ?.call(cusMsg!, autoSave: true);
    // ////////////// 整体逻辑已迁移 //////////////
    // /// 去内部进行比对
    // return MediaDownloadUtil.of.saveImg(
    //   context,
    //   theme,
    //   cusMsg: cusMsg,
    //   message: widget.message,
    // );
    // ////////////// 整体逻辑已迁移 //////////////
  }

  V2TimImage? getImageFromList(V2TimImageTypesEnum imgType) {
    V2TimImage? img = MessageUtils.getImageFromImgList(
        widget.message.imageElem!.imageList,
        HistoryMessageDartConstant.imgPriorMap[imgType] ??
            HistoryMessageDartConstant.oriImgPrior);

    return img;
  }

  void launchDesktopFile(String path) {
    if (PlatformUtils().isWindows) {
      OpenFile.open(path);
    } else {
      launchUrl(Uri.file(path));
    }
  }

  Widget errorPage(theme) => SizedBox(
      height: MediaQuery.of(context).size.height,
      // color: theme.black,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: errorDisplay(context, theme),
      ));

  bool checkIfDownloadSuccess() {
    final localUrl = TencentUtils.checkString(
            model.getFileMessageLocation(widget.message.msgID)) ??
        widget.message.imageElem!.imageList![0]!.localUrl;
    return TencentUtils.checkString(localUrl) != null &&
        File(localUrl!).existsSync();
  }

  _onClickOpenImageInNewWindow() {
    final localUrl = TencentUtils.checkString(
            model.getFileMessageLocation(widget.message.msgID)) ??
        widget.message.imageElem!.imageList![0]!.localUrl;
    Future.delayed(const Duration(milliseconds: 0), () async {
      final isDownloaded = checkIfDownloadSuccess();
      if (isDownloaded) {
        launchDesktopFile(localUrl ?? "");
      } else {
        onTIMCallback(TIMCallback(
            infoCode: 6660414,
            infoRecommendText: TIM_t("正在下载原始资源，请稍候..."),
            type: TIMCallbackType.INFO));
      }
    });
  }

  _handleOnTapPreviewImageOnDesktop({
    double? positionRadio,
    String? originImgUrl,
  }) {
    final localUrl = TencentUtils.checkString(
            model.getFileMessageLocation(widget.message.msgID)) ??
        widget.message.imageElem!.imageList![0]!.localUrl;
    if (checkIfDownloadSuccess()) {
      TUIKitWidePopup.showMedia(
          aspectRatio: positionRadio,
          context: context,
          mediaLocalPath: localUrl ?? "",
          onClickOrigin: () => _onClickOpenImageInNewWindow());
    } else {
      if (TencentUtils.checkString(originImgUrl) != null) {
        TUIKitWidePopup.showMedia(
            aspectRatio: positionRadio,
            context: context,
            mediaURL: originImgUrl,
            onClickOrigin: () => _onClickOpenImageInNewWindow());
      } else {
        onTIMCallback(TIMCallback(
            infoCode: 6660414,
            infoRecommendText: TIM_t("正在下载中"),
            type: TIMCallbackType.INFO));
      }
    }
  }

  Future<double> calculateAspectRatio(ImageProvider imageProvider) async {
    Completer<double> completer = Completer<double>();

    final imageStream = imageProvider.resolve(const ImageConfiguration());
    imageStream.addListener(
      ImageStreamListener((imageInfo, synchronousCall) {
        if (imageInfo.image.width != 0 && imageInfo.image.height != 0) {
          double aspectRatio = imageInfo.image.width / imageInfo.image.height;
          completer.complete(aspectRatio);
        } else {
          // If unable to calculate aspect ratio, return default value of 0.5
          completer.complete(0.5);
        }
      }, onError: (Object exception, StackTrace? stackTrace) {
        // If there's an error, return default value of 0.5
        completer.complete(1);
      }),
    );

    return await completer.future;
  }

  void onClickImage({
    required bool isNetworkImage,
    dynamic heroTag,
    required TUITheme theme,
    String? imgUrl,
    String? imgPath,
  }) {
    if (widget.chatModel.chatConfig.onUseCusImgBrowserFn != null) {
      widget.chatModel.chatConfig.onUseCusImgBrowserFn?.call(
        isNetworkImage: isNetworkImage,
        heroTag: heroTag,
        imgUrl: imgUrl,
        imgPath: imgPath,
        message: widget.message,
        userID: widget.chatModel.conversationType == ConvType.c2c
            ? widget.chatModel.conversationID
            : null,
        groupID: widget.chatModel.conversationType == ConvType.group
            ? widget.chatModel.conversationID
            : null,
        isFrom: widget.isFrom,
      );
      return;
    }
    if (isNetworkImage) {
      if (PlatformUtils().isWeb) {
        TUIKitWidePopup.showMedia(
            context: context,
            mediaURL: widget.message.imageElem?.path ?? "",
            onClickOrigin: () => launchUrl(
                  Uri.parse(widget.message.imageElem?.path ?? ""),
                  mode: LaunchMode.externalApplication,
                ));
        return;
      }
      if (PlatformUtils().isDesktop &&
          widget.chatModel.chatConfig.desktopDefaultBrowser) {
        _handleOnTapPreviewImageOnDesktop(
          originImgUrl: imgUrl,
        );
      } else {
        //////////////// 图片、视频消息连续浏览 ////////////////
        if (widget.chatModel.chatConfig.useMediaBrowser) {
          MediaBrowser.showIMMediaMsg(
            context,
            curMsg: widget.message,
            userID: widget.chatModel.conversationType == ConvType.c2c
                ? widget.chatModel.conversationID
                : null,
            groupID: widget.chatModel.conversationType == ConvType.group
                ? widget.chatModel.conversationID
                : null,
            isFrom: widget.isFrom,
            onImgLongPress: (V2TimMessage msg) {
              widget.chatModel.chatConfig.onImageLongPress
                  ?.call(msg, autoSave: false);
            },
            onImgMorePress: (V2TimMessage msg) {
              widget.chatModel.chatConfig.onImageMorePress
                  ?.call(msg);
            },
            onImgViewPress: (V2TimMessage msg) {
              widget.chatModel.chatConfig.onImageViewPress
                  ?.call(msg);
            },
            onDownloadImage: (msg) {
              _saveImg(theme, cusMsg: msg);
            },
          );
          return;
        }
        //////////////// 图片、视频消息连续浏览 ////////////////
        Navigator.of(context).push(
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => ImageScreen(
                    imageProvider: CachedNetworkImageProvider(
                      imgUrl ?? "",
                      cacheKey: widget.message.msgID,
                    ),
                    heroTag: heroTag,
                    messageID: widget.message.msgID,
                    downloadFn: () async {
                      return await _saveImg(theme);
                    },
                    onLongPress: () async {
                      widget.chatModel.chatConfig.onImageLongPress
                          ?.call(widget.message, autoSave: false);
                    },
                  )),
        );
      }
    } else {
      if (PlatformUtils().isDesktop &&
          widget.chatModel.chatConfig.desktopDefaultBrowser) {
        TUIKitWidePopup.showMedia(
            mediaLocalPath: imgPath,
            context: context,
            onClickOrigin: () => launchDesktopFile(imgPath ?? ""));
      } else {
        //////////////// 图片、视频消息连续浏览 ////////////////
        if (widget.chatModel.chatConfig.useMediaBrowser) {
          MediaBrowser.showIMMediaMsg(
            context,
            curMsg: widget.message,
            userID: widget.chatModel.conversationType == ConvType.c2c
                ? widget.chatModel.conversationID
                : null,
            groupID: widget.chatModel.conversationType == ConvType.group
                ? widget.chatModel.conversationID
                : null,
            isFrom: widget.isFrom,
            onImgLongPress: (V2TimMessage msg) {
              widget.chatModel.chatConfig.onImageLongPress
                  ?.call(widget.message, autoSave: false);
            },
            onImgMorePress: (V2TimMessage msg) {
              widget.chatModel.chatConfig.onImageMorePress
                  ?.call(msg);
            },
            onImgViewPress: (V2TimMessage msg) {
              widget.chatModel.chatConfig.onImageViewPress
                  ?.call(msg);
            },
            onDownloadImage: (msg) {
              _saveImg(theme, cusMsg: msg);
            },
          );
          return;
        }
        //////////////// 图片、视频消息连续浏览 ////////////////

        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false, // set to false
            pageBuilder: (_, __, ___) => ImageScreen(
              imageProvider: FileImage(File(imgPath ?? "")),
              heroTag: heroTag,
              messageID: widget.message.msgID,
              downloadFn: () async {
                return await _saveImg(theme);
              },
              onLongPress: () async {
                widget.chatModel.chatConfig.onImageLongPress
                    ?.call(widget.message, autoSave: false);
              },
            ),
          ),
        );
      }
    }
  }

  Widget _renderAllImage({
    dynamic heroTag,
    required TUITheme theme,
    bool isNetworkImage = false,
    String? webPath,
    V2TimImage? originalImg,
    V2TimImage? smallImg,
    String? smallLocalPath,
    String? originLocalPath,
    num? height,
    num? width,
  }) {
    Widget getImageWidget() {
      ///  start  单独的图片加载逻辑
      ///  如果是图片
      // FileUtil.of.messageImageCachePath(
      //     orgImgPath: messageProgress.path, msgId: messageProgress.msgID);

      /// end  单独的图片加载逻辑

      if (isNetworkImage || _didRenderWithNet) {
        _didRenderWithNet = true;
        return Hero(
          tag: heroTag,
          child: PlatformUtils().isWeb
              ? Image.network(webPath ?? smallImg?.url ?? originalImg!.url!,
                  fit: BoxFit.contain)
              : CachedNetworkImage(
                  alignment: Alignment.topCenter,
                  imageUrl: webPath ?? smallImg?.url ?? originalImg!.url!,
                  errorWidget: (context, error, stackTrace) => errorDisplay(
                    context,
                    theme,
                    width: width,
                    height: height,
                  ),
                  fit: BoxFit.contain,
                  cacheKey: smallImg?.uuid ?? originalImg!.uuid,
                  //////////// 调整图片 placeholder ////////////
                  placeholder: (context, url) => placeholderDisplay(
                    context,
                    theme,
                    width: width,
                    height: height,
                  ),
                  // Image(image: MemoryImage(kTransparentImage)),
                  //////////// 调整图片 placeholder ////////////
                  fadeInDuration: const Duration(milliseconds: 100),
                ),
        );
      } else {
        final imgPath = (TencentUtils.checkString(smallLocalPath) != null
            ? smallLocalPath
            : originLocalPath)!;

        final imgFile = File(imgPath);
        debugPrint('imgFile: ${imgFile.existsSync()}');
        debugPrint('imgFile smallLocalPath: $smallLocalPath');
        debugPrint('imgFile originLocalPath: $originLocalPath');
        debugPrint('imgFile imgPath: $imgPath');
        debugPrint('imgFile statSync: ${imgFile.statSync()}');
        return Hero(
            tag: heroTag,
            child: Image.file(
              File(imgPath),
              fit: BoxFit.contain,
              //////////// 增加图片 errorBuilder ////////////
              errorBuilder: (context, error, stackTrace) => errorDisplay(
                context,
                theme,
                width: width,
                height: height,
              ),
              //////////// 增加图片 errorBuilder ////////////
            ));
      }
    }

    double? currentPositionRadio;
    // File imgF = File((TencentUtils.checkString(originLocalPath) != null
    //         ? originLocalPath
    //         : smallLocalPath) ??
    //     "");
    // bool isExist = imgF.existsSync();
    //
    // if (!isExist) {
    //   return errorDisplay(context, theme);
    // }
    // Image image = Image.file(imgF);
    //
    // image.image
    //     .resolve(const ImageConfiguration())
    //     .addListener(ImageStreamListener((image, synchronousCall) {
    //   if (image.image.width != 0 && image.image.height != 0) {
    //     currentPositionRadio = image.image.width / image.image.height;
    //   }
    // }));

    return GestureDetector(
      onTap: () => onClickImage(
          theme: theme,
          heroTag: heroTag,
          isNetworkImage: isNetworkImage,
          imgUrl: webPath ?? smallImg?.url ?? originalImg?.url ?? "",
          imgPath: (TencentUtils.checkString(originLocalPath) != null
                  ? originLocalPath
                  : smallLocalPath) ??
              ""),
      child: getImageWidget(),
    );
  }

  void initImages() async {
    final zeroImageLocal = TencentUtils.checkString(widget
        .message.imageElem?.imageList
        ?.firstWhereOrNull((element) => element?.type == 0)
        ?.localUrl);
    final oneImageLocal = TencentUtils.checkString(widget
        .message.imageElem?.imageList
        ?.firstWhereOrNull((element) => element?.type == 1)
        ?.localUrl);
    final twoImageLocal = TencentUtils.checkString(widget
        .message.imageElem?.imageList
        ?.firstWhereOrNull((element) => element?.type == 2)
        ?.localUrl);

    debugPrint('savePath j elem.imageElem1: $zeroImageLocal');
    debugPrint('savePath j elem.imageElem2: $oneImageLocal');
    debugPrint('savePath j elem.imageElem3: $twoImageLocal');

// start 单独的存储图片逻辑

    // String conV = KxUtil.of.getConversationID(message: widget.message);
    // debugPrint('savePath j conV: $conV');
    // FileUtil.of.messageImageCachePath(
    //     conversationId: conV,
    //     orgImgPath: "",
    //     msgId: widget.message.msgID ?? "");

// end 单独的存储图片逻辑

    ///////////////////// 过期消息直接不开启下载 /////////////////////
    if (widget.message.isExpired) return;
    ///////////////////// 过期消息直接不开启下载 /////////////////////

    if (!PlatformUtils().isWeb &&
        TencentUtils.checkString(widget.message.msgID) != null) {
      if ((widget.message.imageElem?.imageList) == null ||
          widget.message.imageElem!.imageList!.isEmpty) {
        final response = await _messageService.getMessageOnlineUrl(
            msgID: widget.message.msgID!);
        final elem = response.data;
        if (elem != null && elem.imageElem != null) {
          widget.message.imageElem = elem.imageElem;
          debugPrint(
              'savePath elem.imageElem4: ${elem.imageElem?.imageList?.length}');
        }
      }
      if ((oneImageLocal == null || !File(oneImageLocal).existsSync()) &&
          widget.chatModel.chatConfig.fileAutoDownload) {
        // thumb 缩略图
        _messageService.downloadMessage(
            msgID: widget.message.msgID!,
            messageType: 3,
            imageType: 1,
            isSnapshot: false);
      }
      if ((twoImageLocal == null || !File(twoImageLocal).existsSync()) &&
          widget.chatModel.chatConfig.fileAutoDownload) {
        // large
        _messageService.downloadMessage(
            msgID: widget.message.msgID!,
            messageType: 3,
            imageType: 2,
            isSnapshot: false);
      }
      if (zeroImageLocal == null || !File(zeroImageLocal).existsSync()) {
        debugPrint('savePath zeroImageLocal: $zeroImageLocal');
        debugPrint('savePath zeroImageLocal msgID: ${widget.message.msgID}');
        // origin
        _messageService.downloadMessage(
            msgID: widget.message.msgID!,
            messageType: 3,
            imageType: 0,
            isSnapshot: false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initImages();
  }

  Widget? _renderImage(
    dynamic heroTag,
    TUITheme theme, {
    V2TimImage? originalImg,
    V2TimImage? smallImg,
    num? height,
    num? width,
  }) {
    double positionRadio = 1.0;
    if (smallImg?.width != null &&
        smallImg?.height != null &&
        smallImg?.width != 0 &&
        smallImg?.height != 0) {
      positionRadio = (smallImg!.width! / smallImg.height!);
    }

    if (PlatformUtils().isWeb && widget.message.imageElem!.path != null) {
      // Displaying on Web only
      return _renderAllImage(
        heroTag: heroTag,
        theme: theme,
        isNetworkImage: true,
        smallImg: smallImg,
        originalImg: originalImg,
        webPath: widget.message.imageElem!.path,
        height: height,
        width: width,
      );
    }

    try {
      if ((widget.message.isSelf! &&
          widget.message.imageElem!.path != null &&
          widget.message.imageElem!.path!.isNotEmpty &&
          File(widget.message.imageElem!.path!).existsSync())) {
        return _renderAllImage(
          smallLocalPath: widget.message.imageElem!.path!,
          heroTag: heroTag,
          theme: theme,
          originLocalPath: widget.message.imageElem!.path!,
          height: height,
          width: width,
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
        return _renderAllImage(
          smallLocalPath: smallImg?.localUrl ?? "",
          heroTag: heroTag,
          theme: theme,
          originLocalPath: originalImg?.localUrl,
          height: height,
          width: width,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      outputLogger.i(e.toString());
      return _renderAllImage(
        heroTag: heroTag,
        theme: theme,
        isNetworkImage: true,
        smallImg: smallImg,
        originalImg: originalImg,
        height: height,
        width: width,
      );
    }

    if ((smallImg?.url ?? originalImg?.url) != null &&
        (smallImg?.url ?? originalImg?.url)!.isNotEmpty) {
      return _renderAllImage(
        heroTag: heroTag,
        theme: theme,
        isNetworkImage: true,
        smallImg: smallImg,
        originalImg: originalImg,
        height: height,
        width: width,
      );
    }

    return errorDisplay(
      context,
      theme,
      width: width,
      height: height,
    );
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final heroTag =
        "${widget.message.msgID ?? widget.message.id ?? widget.message.timestamp ?? DateTime.now().millisecondsSinceEpoch}${widget.isFrom}";

    V2TimImage? originalImg = getImageFromList(V2TimImageTypesEnum.original);
    V2TimImage? smallImg = getImageFromList(V2TimImageTypesEnum.small);
    return TIMUIKitMessageReactionWrapper(
        chatModel: widget.chatModel,
        isShowJump: widget.isShowJump,
        clearJump: widget.clearJump,
        isFromSelf: widget.message.isSelf ?? true,
        isShowMessageReaction: widget.isShowMessageReaction ?? true,
        message: widget.message,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          double maxWidth = constraints.maxWidth * 0.5;
          double minWidth = 64;
          double maxHeight = 256;

          Size? size = widget.calculateSizeFunc?.call(
            minWidth,
            maxWidth,
            0,
            maxHeight,
          );
          if (size != null && size != Size.zero && size != Size.infinite) {
            return SizedBox(
              width: size.width,
              height: size.height,
              child: _renderImage(
                heroTag,
                theme,
                originalImg: originalImg,
                smallImg: smallImg,
                height: size.height,
                width: size.width,
              ),
            );
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * (isDesktopScreen ? 0.4 : 0.5),
              minWidth: 64,
              maxHeight: 256,
            ),
            child: _renderImage(
              heroTag,
              theme,
              originalImg: originalImg,
              smallImg: smallImg,
            ),
          );
        }));
  }
}

class ImageClipper extends CustomClipper<RRect> {
  @override
  RRect getClip(Size size) {
    return RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, min(size.height, 256)),
        const Radius.circular(5));
  }

  @override
  bool shouldReclip(CustomClipper<RRect> oldClipper) {
    return oldClipper != this;
  }
}
