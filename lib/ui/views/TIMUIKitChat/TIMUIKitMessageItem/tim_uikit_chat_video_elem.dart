import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/extensions/v2timmessage_extensions.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message_has_file_util.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/video_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/kang_xun_video_screen.dart';

class TIMUIKitVideoElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final String? isFrom;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;
  final Size? Function(
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight,
  )? calculateSizeFunc;

  const TIMUIKitVideoElem(
    this.message, {
    Key? key,
    this.isShowJump = false,
    this.clearJump,
    this.isFrom,
    this.isShowMessageReaction,
    required this.chatModel,
    this.calculateSizeFunc,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitVideoElemState();
}

class _TIMUIKitVideoElemState extends TIMUIKitState<TIMUIKitVideoElem> {
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimVideoElem stateElement = widget.message.videoElem!;

  Widget errorDisplay(TUITheme? theme, num? height) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        width: 1,
        color: Colors.black12,
      )),
      height: height?.toDouble() ?? 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: theme?.cautionColor,
              size: 16,
            ),
            Text(
              TIM_t("视频加载失败"),
              style: TextStyle(color: theme?.cautionColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget generateSnapshot(
    TUITheme theme,
    num height,
    num width,
  ) {
    if (!PlatformUtils().isWeb) {
      final current = (DateTime.now().millisecondsSinceEpoch / 1000).ceil();
      final timeStamp = widget.message.timestamp ?? current;
      if (current - timeStamp < 300) {
        if (stateElement.snapshotPath != null &&
            stateElement.snapshotPath != '') {
          File imgF = File(stateElement.snapshotPath!);
          bool isExist = imgF.existsSync();
          if (isExist) {
            return Image.file(
              File(stateElement.snapshotPath!),
              fit: BoxFit.fitWidth,
              //////////// 增加图片 errorBuilder ////////////
              errorBuilder: (context, error, stackTrace) =>
                  errorDisplay(theme, height),
              //////////// 增加图片 errorBuilder ////////////
            );
          }
        }
      }
    }

    if ((stateElement.snapshotUrl == null || stateElement.snapshotUrl == '') &&
        (stateElement.snapshotPath == null ||
            stateElement.snapshotPath == '')) {
      return _loadingDisplay(
        context,
        theme,
        height: height.toDouble(),
        width: width.toDouble(),
      );
    }
    return (!PlatformUtils().isWeb && stateElement.snapshotUrl == null ||
            widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SENDING)
        ? (stateElement.snapshotPath!.isNotEmpty
            ? Image.file(
                File(stateElement.snapshotPath!),
                fit:
                    BoxFit.fitWidth, //////////// 增加图片 errorBuilder ////////////
                errorBuilder: (context, error, stackTrace) =>
                    errorDisplay(theme, height),
                //////////// 增加图片 errorBuilder ////////////
              )
            : Image.file(
                File(stateElement.localSnapshotUrl!),
                fit:
                    BoxFit.fitWidth, //////////// 增加图片 errorBuilder ////////////
                errorBuilder: (context, error, stackTrace) =>
                    errorDisplay(theme, height),
                //////////// 增加图片 errorBuilder ////////////
              ))
        : (PlatformUtils().isWeb ||
                stateElement.localSnapshotUrl == null ||
                stateElement.localSnapshotUrl == "")
            ? PlatformUtils().isWeb
                ? Image.network(
                    stateElement.snapshotUrl!,
                    fit: BoxFit.fitWidth,
                    //////////// 增加图片 loadingBuilder ////////////
                    loadingBuilder: (context, child, loadingProgress) =>
                        loadingProgress != null &&
                                loadingProgress.cumulativeBytesLoaded ==
                                    loadingProgress.expectedTotalBytes
                            ? const SizedBox()
                            : _loadingDisplay(
                                context,
                                theme,
                                height: height.toDouble(),
                                width: width.toDouble(),
                              ),
                    //////////// 增加图片 loadingBuilder ////////////
                    //////////// 增加图片 errorBuilder ////////////
                    errorBuilder: (context, error, stackTrace) =>
                        errorDisplay(theme, height),
                    //////////// 增加图片 errorBuilder ////////////
                  )
                : CachedNetworkImage(
                    alignment: Alignment.topCenter,
                    imageUrl: stateElement.snapshotUrl!,
                    errorWidget: (context, error, stackTrace) =>
                        errorDisplay(theme, height),
                    fit: BoxFit.contain,
                    cacheKey: stateElement.UUID,
                    //////////// 调整封面 placeholder ////////////
                    placeholder: (context, url) => _loadingDisplay(
                      context,
                      theme,
                      height: height.toDouble(),
                      width: width.toDouble(),
                    ),
                    //////////// 调整封面 placeholder ////////////
                    fadeInDuration: const Duration(milliseconds: 100),
                  )
            : Image.file(
                File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth,
                //////////// 增加图片 errorBuilder ////////////
                errorBuilder: (context, error, stackTrace) =>
                    errorDisplay(theme, height),
                //////////// 增加图片 errorBuilder ////////////
              );
  }

  downloadMessageDetailAndSave() async {
    ///////////////////// 过期消息直接不开启下载 /////////////////////
    if (widget.message.isExpired) return;
    ///////////////////// 过期消息直接不开启下载 /////////////////////

    if (TencentUtils.checkString(widget.message.msgID) != null) {
      if (TencentUtils.checkString(widget.message.videoElem!.videoUrl) ==
          null) {
        final response = await _messageService.getMessageOnlineUrl(
            msgID: widget.message.msgID!);
        if (response.data != null) {
          widget.message.videoElem = response.data!.videoElem;
          Future.delayed(const Duration(microseconds: 10), () {
            setState(() => stateElement = response.data!.videoElem!);
          });
        }
      }
      if (!PlatformUtils().isWeb) {
        if ((TencentUtils.checkString(
                        widget.message.videoElem!.localVideoUrl) ==
                    null ||
                !File(widget.message.videoElem!.localVideoUrl!).existsSync()) &&
            widget.chatModel.chatConfig.fileAutoDownload) {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: false);
        }

        // 下载封面图
        if (TencentUtils.checkString(
                    widget.message.videoElem!.localSnapshotUrl) ==
                null ||
            !File(widget.message.videoElem!.localSnapshotUrl!).existsSync()) {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: true);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    downloadMessageDetailAndSave();
  }

  void launchDesktopFile(String path) {
    if (PlatformUtils().isWindows) {
      OpenFile.open(path);
    } else {
      launchUrl(Uri.file(path));
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final heroTag =
        "${widget.message.msgID ?? widget.message.id ?? widget.message.timestamp ?? DateTime.now().millisecondsSinceEpoch}${widget.isFrom}";

    return GestureDetector(
      onTap: () {
        if (PlatformUtils().isWeb) {
          final url = widget.message.videoElem?.videoUrl ??
              widget.message.videoElem?.videoPath ??
              "";
          TUIKitWidePopup.showMedia(
              context: context,
              mediaURL: url,
              onClickOrigin: () => launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ));
          return;
        }
        if (PlatformUtils().isDesktop) {
          final videoElem = widget.message.videoElem;
          if (videoElem != null) {
            final localVideoUrl =
                TencentUtils.checkString(videoElem.localVideoUrl);
            final videoPath = TencentUtils.checkString(videoElem.videoPath);
            final videoUrl = videoElem.videoUrl;
            if (localVideoUrl != null) {
              launchDesktopFile(localVideoUrl);
              // todo
              // TUIKitWidePopup.showMedia(
              //     context: context,
              //     mediaLocalPath: localVideoUrl,
              //     onClickOrigin: () => launchDesktopFile(localVideoUrl));
            } else if (videoPath != null && File(videoPath).existsSync()) {
              launchDesktopFile(videoPath);
              // todo
              // TUIKitWidePopup.showMedia(
              //     context: context,
              //     mediaURL: videoPath,
              //     onClickOrigin: () => launchDesktopFile(videoPath));
            } else if (TencentUtils.isTextNotEmpty(videoUrl)) {
              // onTIMCallback(TIMCallback(
              //     infoCode: 6660414,
              //     infoRecommendText: TIM_t("正在下载中"),
              //     type: TIMCallbackType.INFO));
            }
          }
        } else {
          //////////////// 图片、视频消息连续浏览 ////////////////
          // if (widget.chatModel.chatConfig.useMediaBrowser) {
          //   MediaBrowser.showIMMediaMsg(
          //     context,
          //     curMsg: widget.message..videoElem = stateElement,
          //     userID: widget.chatModel.conversationType == ConvType.c2c
          //         ? widget.chatModel.conversationID
          //         : null,
          //     groupID: widget.chatModel.conversationType == ConvType.group
          //         ? widget.chatModel.conversationID
          //         : null,
          //     isFrom: widget.isFrom,
          //   );
          //   return;
          // }
          //////////////// 图片、视频消息连续浏览 ////////////////

          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false, // set to false
              pageBuilder: (_, __, ___) =>
                  widget.chatModel.chatConfig.useKangXunVideo
                      ? KangXunVideoScreen(
                          message: widget.message,
                          heroTag: heroTag,
                          videoElement: stateElement,
                        )
                      : VideoScreen(
                          message: widget.message,
                          heroTag: heroTag,
                          videoElement: stateElement,
                        ),
            ),
          );
        }
      },
      child: Hero(
          tag: heroTag,
          child: TIMUIKitMessageReactionWrapper(
              chatModel: widget.chatModel,
              message: widget.message,
              isShowJump: widget.isShowJump,
              isShowMessageReaction: widget.isShowMessageReaction ?? true,
              clearJump: widget.clearJump,
              isFromSelf: widget.message.isSelf ?? true,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  double? positionRadio;

                  double maxWidth =
                      PlatformUtils().isWeb ? 300 : constraints.maxWidth * 0.5;
                  double minWidth = 20;
                  double maxHeight = min(constraints.maxHeight * 0.8, 300);
                  double minHeight = 20;
                  Size? size = widget.calculateSizeFunc?.call(
                    minWidth,
                    maxWidth,
                    minHeight,
                    maxHeight,
                  );

                  if ((stateElement.snapshotWidth) != null &&
                      stateElement.snapshotHeight != null &&
                      stateElement.snapshotWidth != 0 &&
                      stateElement.snapshotHeight != 0) {
                    positionRadio = (stateElement.snapshotWidth! /
                        stateElement.snapshotHeight!);
                  }
                  final child = Stack(
                    children: <Widget>[
                      if (positionRadio != null &&
                          (stateElement.snapshotUrl != null ||
                              stateElement.snapshotUrl != null))
                        AspectRatio(
                          aspectRatio: positionRadio,
                          child: Container(
                            decoration:
                                const BoxDecoration(color: Colors.transparent),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: generateSnapshot(
                              theme,
                              size?.height ??
                                  stateElement.snapshotHeight ??
                                  170,
                              size?.width ?? 170,
                            ),
                          )
                        ],
                      ),
                      if (widget.message.status !=
                                  MessageStatus.V2TIM_MSG_STATUS_SENDING &&
                              (stateElement.snapshotUrl != null ||
                                  stateElement.snapshotPath != null) &&
                              stateElement.videoPath != null ||
                          stateElement.videoUrl != null)
                        Positioned.fill(
                          // alignment: Alignment.center,
                          child: Center(
                              child: PlatformUtils().isDesktop
                                  ? _getWindowView()
                                  : Image.asset('images/play.png',
                                      package: 'tencent_cloud_chat_uikit',
                                      height: 64)),
                        ),
                      if (widget.message.videoElem?.duration != null &&
                          widget.message.videoElem!.duration! > 0)
                        Positioned(
                            right: 10,
                            bottom: 10,
                            child: Text(
                                MessageUtils.formatVideoTime(
                                        widget.message.videoElem!.duration!)
                                    .toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12))),
                    ],
                  );

                  if (size != null &&
                      size != Size.zero &&
                      size != Size.infinite) {
                    return SizedBox(
                      width: size.width,
                      height: size.height,
                      child: child,
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: PlatformUtils().isWeb
                            ? 300
                            : constraints.maxWidth * 0.5,
                        maxHeight: min(constraints.maxHeight * 0.8, 300),
                        minHeight: 20,
                        minWidth: 20),
                    child: child,
                  );
                }),
              ))),
    );
  }

//  新添加  Windows 视图 start

  int downloadProgress = 0;

  ///  是否存在该文件
  bool _hasFile() {
    final (exists, savePath) = MessageHasFileUtil.of
        .hasFile(widget.message, widget.chatModel.globalModel);

    if (exists && widget.message.msgID != null) {
      if (widget.chatModel.globalModel
              .getMessageProgress(widget.message.msgID) !=
          100) {
        widget.chatModel.globalModel
            .setMessageProgress(widget.message.msgID!, 100);
      }
      widget.message.videoElem?.localVideoUrl = savePath;
    }
    return exists;
  }

  Widget _getWindowView() {
    //  判断视频是否下载完成
    if (_hasFile()) {
      return Image.asset('images/play.png',
          package: 'tencent_cloud_chat_uikit', height: 64);
    }
    switch (downloadProgress) {
      case -1:
        //  下载失败
        return Image.asset('images/download_fail.png',
            package: 'tencent_cloud_chat_uikit', height: 64);
      case 100:
        // 下载成功
        String savePath = TencentUtils.checkString(widget.chatModel.globalModel
                .getFileMessageLocation(widget.message.msgID)) ??
            TencentUtils.checkString(widget.message.videoElem!.localVideoUrl) ??
            widget.message.videoElem?.videoPath ??
            '';
        widget.message.videoElem?.localVideoUrl = savePath;
        return Image.asset('images/play.png',
            package: 'tencent_cloud_chat_uikit', height: 64);

      case 0:
        // 尚未下载
        debugPrint(
            "MediaDownloadProgressUtil===>尚未下载: 当前下载进度$downloadProgress");

        return IconButton(
          icon: Image.asset(
            'images/download.png',
            package: 'tencent_cloud_chat_uikit',
          ),
          iconSize: 48,
          onPressed: () async {
            addStartListener();
            MediaDownloadProgressUtil.of.downloadVideo(message: widget.message);
          },
        );
      default:
        // 下载中
        return CircularProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Colors.blue),
          value: downloadProgress / 100,
        );
    }
  }

  void addStartListener() {
    MediaDownloadProgressUtil.of.addDownloadListener(
        message: widget.message,
        downloadKey: (widget.message.msgID ?? "-1") + "video",
        downloadListener: (
          downloadKey,
          messageProgress,
        ) {
          //  因为 此处只监听  视频的下载进度  所以需要过滤
          if ((downloadKey == (widget.message.msgID ?? "-1") + "video") &&
              !messageProgress.isSnapshot) {
            if (mounted) {
              if (messageProgress.isError || messageProgress.errorCode != 0) {
                debugPrint("MediaDownloadProgressUtil===>$downloadKey下载任务失败");

                MediaDownloadProgressUtil.of
                    .removeListenerByKey(removeKey: downloadKey);
                setState(() {
                  downloadProgress = -1;
                });

                return;
              }
              if (messageProgress.isFinish) {
                debugPrint("MediaDownloadProgressUtil===>$downloadKey下载任务成功");

                MediaDownloadProgressUtil.of
                    .removeListenerByKey(removeKey: downloadKey);

                setState(() {
                  downloadProgress = 100;
                });
              } else {
                final currentProgress = (messageProgress.currentSize /
                        messageProgress.totalSize *
                        100)
                    .floor();
                debugPrint(
                    "MediaDownloadProgressUtil===>$downloadKey: 当前下载进度$currentProgress");

                setState(() {
                  downloadProgress = currentProgress;
                });
              }
            }
          }
        });
  }
//  新添加  Windows 视图 end
}

extension _TIMUIKitVideoElemStateCustom on _TIMUIKitVideoElemState {
  Widget _loadingDisplay(
    BuildContext context,
    TUITheme? theme, {
    double? width,
    double? height,
  }) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(
            width: 2,
            color: theme?.weakDividerColor ?? Colors.grey,
          )),
      height: height ?? 170,
      width: width ?? 170,
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
}
